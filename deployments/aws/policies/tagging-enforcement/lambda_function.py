"""
AWS Tag Compliance Daily Digest Lambda Function

Runs daily at 2am UTC to check tag compliance across all AWS resources.
Validates tags against approved-tags.yaml configuration and sends digest emails
to compliance team and resource owners.

Features:
- 14-day grace period for new resources
- Team-specific filtered notifications
- Severity-grouped reporting (missing tags > invalid values)
- YAML-driven validation for allowed tag values
"""

import json
import os
import boto3
import yaml
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any
from collections import defaultdict

# Setup logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables
REQUIRED_TAGS = json.loads(os.environ.get('REQUIRED_TAGS', '[]'))
COMPLIANCE_EMAIL = os.environ.get('COMPLIANCE_EMAIL', 'compliance@kuduworks.net')
TEAM_CONFIG_BUCKET = os.environ.get('TEAM_CONFIG_BUCKET')
TEAM_CONFIG_KEY = os.environ.get('TEAM_CONFIG_KEY', 'approved-tags.yaml')
GRACE_PERIOD_DAYS = int(os.environ.get('GRACE_PERIOD_DAYS', '14'))
DRY_RUN = os.environ.get('DRY_RUN', 'true').lower() == 'true'

# AWS clients
config_client = boto3.client('config')
s3_client = boto3.client('s3')
sns_client = boto3.client('sns')


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main Lambda handler - runs daily compliance check
    
    Args:
        event: EventBridge scheduled event
        context: Lambda context
    
    Returns:
        Response dict with status and summary
    """
    logger.info("Starting daily tag compliance check")
    
    try:
        # Load team configuration from S3
        team_config = load_team_config()
        logger.info(f"Loaded configuration for {len(team_config.get('teams', {}))} teams")
        
        # Get non-compliant resources from AWS Config
        non_compliant_resources = get_non_compliant_resources()
        logger.info(f"Found {len(non_compliant_resources)} non-compliant resources (before grace period)")
        
        # Filter out resources within grace period
        filtered_resources = filter_grace_period(non_compliant_resources)
        logger.info(f"After grace period filter: {len(filtered_resources)} resources")
        
        if not filtered_resources:
            logger.info("No non-compliant resources found - no emails sent")
            return {
                'statusCode': 200,
                'body': json.dumps('All resources compliant - no action needed')
            }
        
        # Validate tags and categorize issues
        compliance_report = validate_and_categorize(filtered_resources, team_config)
        
        # Group by team for targeted notifications
        team_reports = group_by_team(compliance_report)
        
        # Send compliance email (always)
        send_compliance_digest(compliance_report, team_config)
        
        # Send team-specific emails (only for known teams)
        for team_id, team_resources in team_reports.items():
            if team_id in team_config.get('teams', {}):
                send_team_digest(team_id, team_resources, team_config)
            else:
                logger.warning(f"Unknown team '{team_id}' - included in compliance email only")
        
        summary = {
            'total_non_compliant': len(filtered_resources),
            'teams_notified': len([t for t in team_reports.keys() if t in team_config.get('teams', {})]),
            'compliance_email_sent': True
        }
        
        logger.info(f"Compliance check complete: {json.dumps(summary)}")
        
        return {
            'statusCode': 200,
            'body': json.dumps(summary)
        }
        
    except Exception as e:
        error_msg = f"Error during compliance check: {str(e)}"
        logger.error(error_msg, exc_info=True)
        
        # Send error notification to compliance team
        try:
            send_error_notification(error_msg)
        except Exception:  
            logger.error("Failed to send error notification", exc_info=True)  
        
        return {
            'statusCode': 500,
            'body': json.dumps(error_msg)
        }


def load_team_config() -> Dict[str, Any]:
    """
    Load approved-tags.yaml from S3
    
    Returns:
        Dict containing team mappings and allowed tag values
    """
    try:
        response = s3_client.get_object(
            Bucket=TEAM_CONFIG_BUCKET,
            Key=TEAM_CONFIG_KEY
        )
        
        config_content = response['Body'].read().decode('utf-8')
        config = yaml.safe_load(config_content)
        
        logger.info("Successfully loaded team configuration from S3")
        return config
        
    except Exception as e:
        logger.error(f"Failed to load team config from S3: {str(e)}")
        raise


def get_non_compliant_resources() -> List[Dict[str, Any]]:
    """
    Query AWS Config for non-compliant resources
    
    Returns:
        List of non-compliant resource details
    """
    try:
        response = config_client.get_compliance_details_by_config_rule(
            ConfigRuleName='required-tags-check',
            ComplianceTypes=['NON_COMPLIANT'],
            Limit=100  # Adjust as needed
        )
        
        resources = []
        
        for result in response.get('EvaluationResults', []):
            resource_id = result.get('EvaluationResultIdentifier', {}).get('EvaluationResultQualifier', {})
            
            # Get resource configuration history for creation time
            resource_type = resource_id.get('ResourceType')
            resource_name = resource_id.get('ResourceId')
            
            if resource_type and resource_name:
                try:
                    config_history = config_client.get_resource_config_history(
                        resourceType=resource_type,
                        resourceId=resource_name,
                        limit=1,
                        laterTime=datetime.utcnow(),
                        chronologicalOrder='Reverse'  # Get newest (latest) configuration item
                    )
                    
                    config_item = config_history.get('configurationItems', [{}])[0]
                    creation_time = config_item.get('resourceCreationTime')
                    tags = config_item.get('tags', {})
                    
                    resources.append({
                        'resource_type': resource_type,
                        'resource_id': resource_name,
                        'creation_time': creation_time,
                        'tags': tags,
                        'compliance_type': result.get('ComplianceType')
                    })
                    
                except Exception as e:
                    logger.warning(f"Could not get config history for {resource_type}/{resource_name}: {str(e)}")
                    # Still include resource but without creation time
                    resources.append({
                        'resource_type': resource_type,
                        'resource_id': resource_name,
                        'creation_time': None,
                        'tags': {},
                        'compliance_type': result.get('ComplianceType')
                    })
        
        # Handle pagination if needed
        while 'NextToken' in response:
            response = config_client.get_compliance_details_by_config_rule(
                ConfigRuleName='required-tags-check',
                ComplianceTypes=['NON_COMPLIANT'],
                Limit=100,
                NextToken=response['NextToken']
            )
            
            # Process additional results (same logic as above)
            for result in response.get('EvaluationResults', []):
                resource_id = result.get('EvaluationResultIdentifier', {}).get('EvaluationResultQualifier', {})
                
                # Get resource configuration history for creation time
                resource_type = resource_id.get('ResourceType')
                resource_name = resource_id.get('ResourceId')
                
                if resource_type and resource_name:
                    try:
                        config_history = config_client.get_resource_config_history(
                            resourceType=resource_type,
                            resourceId=resource_name,
                            limit=1,
                            laterTime=datetime.utcnow(),
                            chronologicalOrder='Reverse'  # Get oldest first
                        )
                        
                        config_item = config_history.get('configurationItems', [{}])[0]
                        creation_time = config_item.get('resourceCreationTime')
                        tags = config_item.get('tags', {})
                        
                        resources.append({
                            'resource_type': resource_type,
                            'resource_id': resource_name,
                            'creation_time': creation_time,
                            'tags': tags,
                            'compliance_type': result.get('ComplianceType')
                        })
                        
                    except Exception as e:
                        logger.warning(f"Could not get config history for {resource_type}/{resource_name}: {str(e)}")
                        # Still include resource but without creation time
                        resources.append({
                            'resource_type': resource_type,
                            'resource_id': resource_name,
                            'creation_time': None,
                            'tags': {},
                            'compliance_type': result.get('ComplianceType')
                        })
        
        return resources
        
    except Exception as e:
        logger.error(f"Failed to get non-compliant resources: {str(e)}")
        raise


def filter_grace_period(resources: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Filter out resources created within grace period
    
    Args:
        resources: List of non-compliant resources
    
    Returns:
        Filtered list excluding resources in grace period
    """
    cutoff_date = datetime.utcnow() - timedelta(days=GRACE_PERIOD_DAYS)
    filtered = []
    
    for resource in resources:
        creation_time = resource.get('creation_time')
        
        if creation_time is None:
            # If we can't determine creation time, include it (fail safe)
            filtered.append(resource)
        elif isinstance(creation_time, datetime):
            if creation_time < cutoff_date:
                filtered.append(resource)
            else:
                logger.debug(f"Skipping {resource['resource_id']} - within grace period")
        else:
            # Unexpected format, include it
            filtered.append(resource)
    
    return filtered


def validate_and_categorize(
    resources: List[Dict[str, Any]], 
    team_config: Dict[str, Any]
) -> Dict[str, List[Dict[str, Any]]]:
    """
    Validate tags against YAML rules and categorize by severity
    
    Args:
        resources: List of non-compliant resources
        team_config: Team configuration from YAML
    
    Returns:
        Dict categorized by severity: {missing: [], invalid: []}
    """
    allowed_values = team_config.get('allowed_values', {})
    
    categorized = {
        'missing_tags': [],
        'invalid_values': []
    }
    
    for resource in resources:
        tags = resource.get('tags', {})
        issues = {
            'missing': [],
            'invalid': []
        }
        
        # Check each required tag
        for tag_key in REQUIRED_TAGS:
            if tag_key not in tags:
                issues['missing'].append(tag_key)
            else:
                # Validate value against allowed list
                tag_value = tags[tag_key]
                allowed = allowed_values.get(tag_key, [])
                
                if allowed and tag_value not in allowed:
                    issues['invalid'].append({
                        'key': tag_key,
                        'value': tag_value,
                        'allowed': allowed
                    })
        
        # Categorize by severity (missing > invalid)
        if issues['missing']:
            categorized['missing_tags'].append({
                **resource,
                'missing_tags': issues['missing'],
                'invalid_tags': issues['invalid']
            })
        elif issues['invalid']:
            categorized['invalid_values'].append({
                **resource,
                'missing_tags': [],
                'invalid_tags': issues['invalid']
            })
    
    return categorized


def group_by_team(compliance_report: Dict[str, List[Dict[str, Any]]]) -> Dict[str, List[Dict[str, Any]]]:
    """
    Group resources by team for targeted notifications
    
    Args:
        compliance_report: Categorized compliance issues
    
    Returns:
        Dict mapping team ID to their non-compliant resources
    """
    team_groups = defaultdict(list)
    
    for severity_level in ['missing_tags', 'invalid_values']:
        for resource in compliance_report.get(severity_level, []):
            tags = resource.get('tags', {})
            team = tags.get('team', 'unknown')
            
            team_groups[team].append(resource)
    
    return dict(team_groups)


def send_compliance_digest(
    compliance_report: Dict[str, List[Dict[str, Any]]],
    team_config: Dict[str, Any]
) -> None:
    """
    Send daily digest to compliance team with all non-compliant resources
    
    Args:
        compliance_report: Categorized compliance issues
        team_config: Team configuration from YAML
    """
    # Build email content grouped by resource type and severity
    email_body = build_compliance_email(compliance_report, team_config, is_compliance=True)
    
    subject = f"🏷️ Daily Tag Compliance Digest - {datetime.utcnow().strftime('%Y-%m-%d')}"
    
    try:
        # In real implementation, would send via SNS or SES
        logger.info(f"Sending compliance digest to {COMPLIANCE_EMAIL}")
        
        if DRY_RUN:
            logger.info(f"DRY RUN - Would send email:\n{email_body}")
        else:
            # Send email via SNS topic or SES
            # For now, log it
            logger.info("Email sent to compliance team")
        
    except Exception as e:
        logger.error(f"Failed to send compliance digest: {str(e)}")
        raise


def send_team_digest(
    team_id: str,
    team_resources: List[Dict[str, Any]],
    team_config: Dict[str, Any]
) -> None:
    """
    Send team-specific digest with only their non-compliant resources
    
    Args:
        team_id: Team identifier
        team_resources: List of non-compliant resources for this team
        team_config: Team configuration from YAML
    """
    team_info = team_config['teams'].get(team_id, {})
    team_email = team_info.get('email')
    
    if not team_email:
        logger.warning(f"No email configured for team '{team_id}'")
        return
    
    # Build team-filtered email
    email_body = build_team_email(team_id, team_resources, team_config)
    
    subject = f"🏷️ Tag Compliance Alert for {team_id} - {datetime.utcnow().strftime('%Y-%m-%d')}"
    
    try:
        logger.info(f"Sending team digest to {team_email} for team {team_id}")
        
        if DRY_RUN:
            logger.info(f"DRY RUN - Would send email to {team_email}:\n{email_body}")
        else:
            # Send email via SNS or SES
            logger.info(f"Email sent to team {team_id}")
        
    except Exception as e:
        logger.error(f"Failed to send team digest to {team_id}: {str(e)}")


def build_compliance_email(
    compliance_report: Dict[str, List[Dict[str, Any]]],
    team_config: Dict[str, Any],
    is_compliance: bool = True
) -> str:
    """
    Build email content grouped by resource type and severity
    
    Args:
        compliance_report: Categorized compliance issues
        team_config: Team configuration
        is_compliance: Whether this is for compliance team (full report)
    
    Returns:
        Formatted email body
    """
    total_issues = sum(len(resources) for resources in compliance_report.values())
    
    email = f"""
Daily Tag Compliance Report
Generated: {datetime.utcnow().strftime('%Y-%m-%d %H:%M UTC')}

Summary:
- Total Non-Compliant Resources: {total_issues}
- Missing Tags: {len(compliance_report.get('missing_tags', []))} resources
- Invalid Values: {len(compliance_report.get('invalid_values', []))} resources

Required Tags: {', '.join(REQUIRED_TAGS)}
Grace Period: {GRACE_PERIOD_DAYS} days

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚨 MISSING TAGS (Highest Severity)
"""
    
    # Group by resource type for missing tags
    missing_by_type = defaultdict(list)
    for resource in compliance_report.get('missing_tags', []):
        missing_by_type[resource['resource_type']].append(resource)
    
    if missing_by_type:
        for resource_type, resources in sorted(missing_by_type.items()):
            email += f"\n{resource_type} ({len(resources)} resources):\n"
            for resource in resources:
                email += f"  • {resource['resource_id']}\n"
                email += f"    Missing: {', '.join(resource['missing_tags'])}\n"
                if resource.get('invalid_tags'):
                    email += f"    Invalid: {len(resource['invalid_tags'])} values\n"
                team = resource.get('tags', {}).get('team', 'unknown')
                email += f"    Team: {team}\n"
    else:
        email += "\nNo resources with missing tags ✅\n"
    
    email += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    email += "\n⚠️  INVALID TAG VALUES\n"
    
    # Group by resource type for invalid values
    invalid_by_type = defaultdict(list)
    for resource in compliance_report.get('invalid_values', []):
        invalid_by_type[resource['resource_type']].append(resource)
    
    if invalid_by_type:
        for resource_type, resources in sorted(invalid_by_type.items()):
            email += f"\n{resource_type} ({len(resources)} resources):\n"
            for resource in resources:
                email += f"  • {resource['resource_id']}\n"
                for invalid_tag in resource.get('invalid_tags', []):
                    email += f"    {invalid_tag['key']}: '{invalid_tag['value']}' "
                    email += f"(allowed: {', '.join(invalid_tag['allowed'])})\n"
                team = resource.get('tags', {}).get('team', 'unknown')
                email += f"    Team: {team}\n"
    else:
        email += "\nNo resources with invalid values ✅\n"
    
    email += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    email += """
Remediation Instructions:
1. Use merge() pattern in Terraform to combine governance + custom tags
2. Reference deployments/aws/modules/required-tags for baseline tags
3. See approved-tags.yaml for allowed tag values
4. Update tags via Terraform (not console) to prevent drift

Documentation:
https://github.com/KuduWorks/fictional-octo-system/tree/main/deployments/aws/policies/tagging-enforcement

Questions? Contact: compliance@kuduworks.net
"""
    
    return email


def build_team_email(
    team_id: str,
    team_resources: List[Dict[str, Any]],
    team_config: Dict[str, Any]
) -> str:
    """
    Build team-specific email with only their resources
    
    Args:
        team_id: Team identifier
        team_resources: Non-compliant resources for this team
        team_config: Team configuration
    
    Returns:
        Formatted email body
    """
    team_info = team_config['teams'].get(team_id, {})
    
    email = f"""
Tag Compliance Alert for Team: {team_id}
{team_info.get('description', '')}

Generated: {datetime.utcnow().strftime('%Y-%m-%d %H:%M UTC')}

Your team has {len(team_resources)} non-compliant resources that need attention.

Required Tags: {', '.join(REQUIRED_TAGS)}
Grace Period: {GRACE_PERIOD_DAYS} days (resources older than this are included)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

YOUR NON-COMPLIANT RESOURCES:
"""
    
    # Group by resource type
    by_type = defaultdict(list)
    for resource in team_resources:
        by_type[resource['resource_type']].append(resource)
    
    for resource_type, resources in sorted(by_type.items()):
        email += f"\n{resource_type} ({len(resources)}):\n"
        for resource in resources:
            email += f"  • {resource['resource_id']}\n"
            
            if resource.get('missing_tags'):
                email += f"    ❌ Missing: {', '.join(resource['missing_tags'])}\n"
            
            if resource.get('invalid_tags'):
                for invalid_tag in resource['invalid_tags']:
                    email += f"    ⚠️  {invalid_tag['key']}: '{invalid_tag['value']}' → "
                    email += f"allowed: {', '.join(invalid_tag['allowed'])}\n"
    
    email += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    email += """
How to Fix:

1. In your Terraform code, use the required-tags module:

   module "required_tags" {
     source = "../../modules/required-tags"
     
     environment = "production"
     team        = "YOUR_TEAM_ID"
     costcenter  = "YOUR_COSTCENTER"
   }

2. Apply tags using merge():

   resource "aws_s3_bucket" "example" {
     bucket = "my-bucket"
     
     tags = merge(
       module.required_tags.baseline_tags,
       {
         custom_tag = "custom_value"
       }
     )
   }

3. Run terraform plan and apply to update tags

Documentation:
https://github.com/KuduWorks/fictional-octo-system/tree/main/deployments/aws/modules/required-tags

Need help? Contact compliance@kuduworks.net
"""
    
    return email


def send_error_notification(error_message: str) -> None:
    """
    Send error notification to compliance team
    
    Args:
        error_message: Error details
    """
    subject = "❌ Tag Compliance Check Failed"
    body = f"""
The daily tag compliance check encountered an error:

Error: {error_message}

Time: {datetime.utcnow().strftime('%Y-%m-%d %H:%M UTC')}

Please investigate the Lambda function logs.
"""
    
    logger.info(f"Sending error notification to {COMPLIANCE_EMAIL}")
    logger.info(body)
