#!/bin/bash

# AWS Encryption Baseline Config Rules Test Script
# Tests individual AWS Config rules for encryption compliance
#
# IMPORTANT: Region Restriction Compatibility
# ==========================================
# This script must run in a region allowed by your region control policies.
# If you have region restrictions (e.g., only allowing Stockholm region):
#
# Option 1: Update the default region in this script
#   Change line: AWS_REGION=${AWS_REGION:-$(aws configure get region 2>/dev/null || echo "us-east-1")}
#   To:          AWS_REGION=${AWS_REGION:-$(aws configure get region 2>/dev/null || echo "eu-north-1")}
#
# Option 2: Set your AWS CLI default region (RECOMMENDED - IMPLEMENTED)
#   Run: aws configure set region eu-north-1
#   This ensures all AWS CLI commands use the compliant region by default
#
# Option 3: Specify region when running script
#   Run: AWS_REGION=eu-north-1 ./test-config-rules.sh
#
# Note: AWS Config must be enabled in your target region for this script to work.

set -e  # Exit on any error

# Configuration
TEST_PREFIX="aws-config-test-$(date +%s)"
AWS_REGION=${AWS_REGION:-$(aws configure get region 2>/dev/null || echo "us-east-1")}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Resource tracking for cleanup
declare -a test_resources=()
declare -A test_results=()

echo -e "${BLUE}🧪 AWS Config Rules Encryption Policy Testing${NC}"
echo "=============================================="

# Prerequisites check
check_prerequisites() {
    echo -e "${YELLOW}🔧 Checking prerequisites...${NC}"
    
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI not found${NC}"
        exit 1
    fi
    
    # jq is optional - warn if not found but continue
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}⚠️  jq not found - some JSON parsing may be limited${NC}"
        export JQ_AVAILABLE=false
    else
        export JQ_AVAILABLE=true
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS credentials not configured${NC}"
        exit 1
    fi
    
    if ! aws configservice describe-configuration-recorders --query 'ConfigurationRecorders[0].name' --output text &> /dev/null; then
        echo -e "${RED}❌ AWS Config not enabled in region $AWS_REGION${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites met${NC}"
}

# Test functions for each Config rule
test_s3_encryption() {
    echo -e "\n${BLUE}🪣 Test 1: S3 Bucket Server-Side Encryption${NC}"
    
    local bucket_compliant="$TEST_PREFIX-compliant-bucket"
    local bucket_noncompliant="$TEST_PREFIX-noncompliant-bucket"
    
    # Create compliant bucket with encryption
    aws s3 mb "s3://$bucket_compliant" --region "$AWS_REGION"
    aws s3api put-bucket-encryption \
        --bucket "$bucket_compliant" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }'
    test_resources+=("s3_bucket:$bucket_compliant")
    
    # Create non-compliant bucket without encryption
    aws s3 mb "s3://$bucket_noncompliant" --region "$AWS_REGION"
    test_resources+=("s3_bucket:$bucket_noncompliant")
    
    echo -e "${CYAN}Created test buckets: $bucket_compliant (compliant), $bucket_noncompliant (non-compliant)${NC}"
    test_results["s3_encryption"]="CREATED"
}

test_s3_ssl() {
    echo -e "\n${BLUE}🔒 Test 2: S3 Bucket SSL Requests Only${NC}"
    
    local bucket_ssl_compliant="$TEST_PREFIX-ssl-compliant"
    local bucket_ssl_noncompliant="$TEST_PREFIX-ssl-noncompliant"
    
    # Create compliant bucket with SSL-only policy
    aws s3 mb "s3://$bucket_ssl_compliant" --region "$AWS_REGION"
    aws s3api put-bucket-policy \
        --bucket "$bucket_ssl_compliant" \
        --policy '{
            "Version": "2012-10-17",
            "Statement": [{
                "Sid": "DenyInsecureConnections",
                "Effect": "Deny",
                "Principal": "*",
                "Action": "s3:*",
                "Resource": ["arn:aws:s3:::'$bucket_ssl_compliant'", "arn:aws:s3:::'$bucket_ssl_compliant'/*"],
                "Condition": {
                    "Bool": {
                        "aws:SecureTransport": "false"
                    }
                }
            }]
        }'
    test_resources+=("s3_bucket:$bucket_ssl_compliant")
    
    # Create non-compliant bucket without SSL policy
    aws s3 mb "s3://$bucket_ssl_noncompliant" --region "$AWS_REGION"
    test_resources+=("s3_bucket:$bucket_ssl_noncompliant")
    
    echo -e "${CYAN}Created SSL test buckets: $bucket_ssl_compliant (compliant), $bucket_ssl_noncompliant (non-compliant)${NC}"
    test_results["s3_ssl"]="CREATED"
}

test_ebs_encryption() {
    echo -e "\n${BLUE}💾 Test 3: EBS Volume Encryption${NC}"
    
    # Create encrypted EBS volume
    local encrypted_volume=$(aws ec2 create-volume \
        --size 10 \
        --volume-type gp3 \
        --availability-zone "${AWS_REGION}a" \
        --encrypted \
        --query 'VolumeId' \
        --output text)
    test_resources+=("ebs_volume:$encrypted_volume")
    
    # Create unencrypted EBS volume
    local unencrypted_volume=$(aws ec2 create-volume \
        --size 10 \
        --volume-type gp3 \
        --availability-zone "${AWS_REGION}a" \
        --no-encrypted \
        --query 'VolumeId' \
        --output text)
    test_resources+=("ebs_volume:$unencrypted_volume")
    
    echo -e "${CYAN}Created EBS volumes: $encrypted_volume (encrypted), $unencrypted_volume (unencrypted)${NC}"
    test_results["ebs_encryption"]="CREATED"
}

test_rds_encryption() {
    echo -e "\n${BLUE}🗄️ Test 4: RDS Storage Encryption${NC}"
    
    local db_encrypted="$TEST_PREFIX-encrypted-db"
    local db_unencrypted="$TEST_PREFIX-unencrypted-db"
    
    # Create encrypted RDS instance
    aws rds create-db-instance \
        --db-instance-identifier "$db_encrypted" \
        --db-instance-class db.t3.micro \
        --engine mysql \
        --master-username admin \
        --master-user-password TempPass123! \
        --allocated-storage 20 \
        --storage-encrypted \
        --publicly-accessible false \
        --skip-final-snapshot
    test_resources+=("rds_instance:$db_encrypted")
    
    # Create unencrypted RDS instance
    aws rds create-db-instance \
        --db-instance-identifier "$db_unencrypted" \
        --db-instance-class db.t3.micro \
        --engine mysql \
        --master-username admin \
        --master-user-password TempPass123! \
        --allocated-storage 20 \
        --storage-encrypted false \
        --publicly-accessible false \
        --skip-final-snapshot
    test_resources+=("rds_instance:$db_unencrypted")
    
    echo -e "${CYAN}Created RDS instances: $db_encrypted (encrypted), $db_unencrypted (unencrypted)${NC}"
    test_results["rds_encryption"]="CREATED"
}

test_dynamodb_encryption() {
    echo -e "\n${BLUE}📊 Test 5: DynamoDB KMS Encryption${NC}"
    
    local table_kms="$TEST_PREFIX-kms-table"
    local table_default="$TEST_PREFIX-default-table"
    
    # Create table with KMS encryption
    aws dynamodb create-table \
        --table-name "$table_kms" \
        --attribute-definitions AttributeName=id,AttributeType=S \
        --key-schema AttributeName=id,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --sse-specification Enabled=true,SSEType=KMS
    test_resources+=("dynamodb_table:$table_kms")
    
    # Create table with default encryption (non-KMS)
    aws dynamodb create-table \
        --table-name "$table_default" \
        --attribute-definitions AttributeName=id,AttributeType=S \
        --key-schema AttributeName=id,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST
    test_resources+=("dynamodb_table:$table_default")
    
    echo -e "${CYAN}Created DynamoDB tables: $table_kms (KMS), $table_default (default)${NC}"
    test_results["dynamodb_encryption"]="CREATED"
}

test_cloudtrail_encryption() {
    echo -e "\n${BLUE}📜 Test 6: CloudTrail Log File Encryption${NC}"
    
    local trail_encrypted="$TEST_PREFIX-encrypted-trail"
    local trail_unencrypted="$TEST_PREFIX-unencrypted-trail"
    local kms_key_arn
    
    # Create KMS key for CloudTrail
    kms_key_arn=$(aws kms create-key \
        --description "Test key for CloudTrail encryption" \
        --query 'KeyMetadata.Arn' \
        --output text)
    test_resources+=("kms_key:$(echo $kms_key_arn | cut -d'/' -f2)")
    
    # Create encrypted CloudTrail
    aws cloudtrail create-trail \
        --name "$trail_encrypted" \
        --s3-bucket-name "$TEST_PREFIX-cloudtrail-bucket" \
        --kms-key-id "$kms_key_arn" \
        --is-multi-region-trail
    test_resources+=("cloudtrail:$trail_encrypted")
    
    # Create unencrypted CloudTrail
    aws cloudtrail create-trail \
        --name "$trail_unencrypted" \
        --s3-bucket-name "$TEST_PREFIX-cloudtrail-bucket" \
        --is-multi-region-trail
    test_resources+=("cloudtrail:$trail_unencrypted")
    
    echo -e "${CYAN}Created CloudTrail trails: $trail_encrypted (encrypted), $trail_unencrypted (unencrypted)${NC}"
    test_results["cloudtrail_encryption"]="CREATED"
}

# Check Config compliance
check_config_compliance() {
    echo -e "\n${BLUE}📋 Checking Config rule compliance (waiting for evaluation)...${NC}"
    
    # Wait for Config evaluations to complete
    echo -e "${YELLOW}⏳ Waiting 60 seconds for Config evaluations...${NC}"
    sleep 60
    
    # Check each Config rule
    local config_rules=(
        "s3-bucket-server-side-encryption-enabled"
        "s3-bucket-ssl-requests-only" 
        "encrypted-volumes"
        "rds-storage-encrypted"
        "dynamodb-table-encryption-enabled"
        "cloudtrail-encryption-enabled"
    )
    
    for rule in "${config_rules[@]}"; do
        echo -e "\n${CYAN}Checking rule: $rule${NC}"
        
        local compliance=$(aws configservice get-compliance-details-by-config-rule \
            --config-rule-name "$rule" \
            --query 'EvaluationResults[].ComplianceByConfigRule.Compliance' \
            --output text 2>/dev/null || echo "NOT_FOUND")
        
        if [[ "$compliance" == *"NON_COMPLIANT"* ]]; then
            echo -e "${GREEN}✅ Rule working: Found non-compliant resources${NC}"
            test_results["$rule"]="WORKING"
        elif [[ "$compliance" == *"COMPLIANT"* ]]; then
            echo -e "${YELLOW}⚠️ Rule may be working: Only compliant resources found${NC}"
            test_results["$rule"]="PARTIAL"
        else
            echo -e "${RED}❌ Rule not found or not evaluating${NC}"
            test_results["$rule"]="ERROR"
        fi
    done
}

# Cleanup function
cleanup_resources() {
    echo -e "\n${YELLOW}🧹 Cleaning up test resources (mandatory)...${NC}"
    
    for resource in "${test_resources[@]}"; do
        local resource_type=$(echo "$resource" | cut -d':' -f1)
        local resource_id=$(echo "$resource" | cut -d':' -f2)
        
        case "$resource_type" in
            s3_bucket)
                echo "Deleting S3 bucket: $resource_id"
                aws s3 rm "s3://$resource_id" --recursive 2>/dev/null || true
                aws s3 rb "s3://$resource_id" 2>/dev/null || true
                ;;
            ebs_volume)
                echo "Deleting EBS volume: $resource_id"
                aws ec2 delete-volume --volume-id "$resource_id" 2>/dev/null || true
                ;;
            rds_instance)
                echo "Deleting RDS instance: $resource_id"
                aws rds delete-db-instance \
                    --db-instance-identifier "$resource_id" \
                    --skip-final-snapshot \
                    --delete-automated-backups 2>/dev/null || true
                ;;
            dynamodb_table)
                echo "Deleting DynamoDB table: $resource_id"
                aws dynamodb delete-table --table-name "$resource_id" 2>/dev/null || true
                ;;
            cloudtrail)
                echo "Deleting CloudTrail: $resource_id"
                aws cloudtrail stop-logging --name "$resource_id" 2>/dev/null || true
                aws cloudtrail delete-trail --name "$resource_id" 2>/dev/null || true
                ;;
            kms_key)
                echo "Scheduling KMS key deletion: $resource_id"
                aws kms schedule-key-deletion --key-id "$resource_id" --pending-window-in-days 7 2>/dev/null || true
                ;;
        esac
    done
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Generate test report
generate_report() {
    echo -e "\n${BLUE}📊 Test Report Summary${NC}"
    echo "========================"
    
    local total_tests=0
    local working_tests=0
    local partial_tests=0
    local failed_tests=0
    
    for test_name in "${!test_results[@]}"; do
        total_tests=$((total_tests + 1))
        local status="${test_results[$test_name]}"
        
        case "$status" in
            WORKING)
                echo -e "${GREEN}✅ $test_name: WORKING${NC}"
                working_tests=$((working_tests + 1))
                ;;
            PARTIAL)
                echo -e "${YELLOW}⚠️  $test_name: PARTIAL${NC}"
                partial_tests=$((partial_tests + 1))
                ;;
            CREATED)
                echo -e "${CYAN}📝 $test_name: TEST RESOURCES CREATED${NC}"
                ;;
            *)
                echo -e "${RED}❌ $test_name: ERROR${NC}"
                failed_tests=$((failed_tests + 1))
                ;;
        esac
    done
    
    echo ""
    echo "Summary:"
    echo "- Working policies: $working_tests"
    echo "- Partially working: $partial_tests" 
    echo "- Failed/Error: $failed_tests"
    echo ""
    
    if [[ $failed_tests -gt 0 ]]; then
        echo -e "${RED}⚠️  Some Config rules may need attention${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ All Config rules appear to be functioning${NC}"
    fi
}

# Trap to ensure cleanup on script exit
trap cleanup_resources EXIT

# Main execution
main() {
    echo -e "Region: ${CYAN}$AWS_REGION${NC}"
    echo -e "Account: ${CYAN}$ACCOUNT_ID${NC}"
    echo ""
    
    check_prerequisites
    
    # Create CloudTrail S3 bucket first (needed for CloudTrail tests)
    local cloudtrail_bucket="$TEST_PREFIX-cloudtrail-bucket"
    aws s3 mb "s3://$cloudtrail_bucket" --region "$AWS_REGION"
    test_resources+=("s3_bucket:$cloudtrail_bucket")
    
    # Run all 6 Config rule tests
    test_s3_encryption
    test_s3_ssl  
    test_ebs_encryption
    test_rds_encryption
    test_dynamodb_encryption
    test_cloudtrail_encryption
    
    # Check compliance and generate report
    check_config_compliance
    generate_report
    
    # Cleanup is handled by trap
}

# Handle script interruption
handle_interrupt() {
    echo -e "\n${YELLOW}Script interrupted. Cleaning up...${NC}"
    cleanup_resources
    exit 1
}

trap handle_interrupt SIGINT SIGTERM

main "$@"