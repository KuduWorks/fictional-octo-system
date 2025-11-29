#!/bin/bash

# Cleanup Script for Non-Compliant S3 Buckets
# Removes S3 buckets created in non-approved regions (Ohio) and public buckets

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧹 AWS S3 Bucket Cleanup Script${NC}"
echo "=================================="
echo ""
echo "This script will:"
echo "1. Find buckets in non-approved regions (not Stockholm)"
echo "2. Find buckets with public access enabled"
echo "3. Delete these non-compliant buckets"
echo ""

# Get all regions
ALL_REGIONS=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text)
APPROVED_REGION="eu-north-1"

echo -e "${YELLOW}Scanning all AWS regions for non-compliant buckets...${NC}"
echo ""

declare -a buckets_to_delete=()

# Check each region
for region in $ALL_REGIONS; do
    if [ "$region" != "$APPROVED_REGION" ]; then
        echo -e "${BLUE}Checking region: $region${NC}"
        
        # List buckets in this region
        buckets=$(aws s3api list-buckets --query "Buckets[?contains(Name, 'test')].Name" --output text 2>/dev/null || echo "")
        
        for bucket in $buckets; do
            # Get bucket location
            bucket_region=$(aws s3api get-bucket-location --bucket "$bucket" --query 'LocationConstraint' --output text 2>/dev/null || echo "us-east-1")
            
            # Handle us-east-1 special case (returns "None" for LocationConstraint)
            if [ "$bucket_region" == "None" ] || [ "$bucket_region" == "" ]; then
                bucket_region="us-east-1"
            fi
            
            if [ "$bucket_region" == "$region" ] && [ "$bucket_region" != "$APPROVED_REGION" ]; then
                echo -e "${RED}  ❌ Found non-compliant bucket: $bucket in $bucket_region${NC}"
                buckets_to_delete+=("$bucket:$bucket_region")
            fi
        done
    fi
done

# Check Stockholm buckets for public access
echo -e "\n${BLUE}Checking Stockholm region for public access...${NC}"
stockholm_buckets=$(aws s3api list-buckets --query "Buckets[].Name" --output text 2>/dev/null || echo "")

for bucket in $stockholm_buckets; do
    bucket_region=$(aws s3api get-bucket-location --bucket "$bucket" --query 'LocationConstraint' --output text 2>/dev/null || echo "us-east-1")
    
    if [ "$bucket_region" == "$APPROVED_REGION" ]; then
        # Check for public access
        public_access=$(aws s3api get-bucket-acl --bucket "$bucket" --query 'Grants[?Grantee.URI==`http://acs.amazonaws.com/groups/global/AllUsers`]' --output text 2>/dev/null || echo "")
        
        if [ ! -z "$public_access" ]; then
            echo -e "${RED}  ❌ Found bucket with public access: $bucket${NC}"
            buckets_to_delete+=("$bucket:$bucket_region")
        fi
        
        # Check public access block settings
        block_config=$(aws s3api get-public-access-block --bucket "$bucket" 2>/dev/null || echo "")
        if [ -z "$block_config" ]; then
            echo -e "${YELLOW}  ⚠️  Bucket has no public access block: $bucket${NC}"
        fi
    fi
done

# Summary
echo ""
echo -e "${BLUE}=================================${NC}"
echo -e "${YELLOW}Found ${#buckets_to_delete[@]} non-compliant bucket(s)${NC}"

if [ ${#buckets_to_delete[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ No non-compliant buckets found!${NC}"
    exit 0
fi

echo ""
echo "Buckets to delete:"
for bucket_info in "${buckets_to_delete[@]}"; do
    bucket=$(echo "$bucket_info" | cut -d':' -f1)
    region=$(echo "$bucket_info" | cut -d':' -f2)
    echo -e "  - ${RED}$bucket${NC} (region: $region)"
done

echo ""
read -p "Do you want to delete these buckets? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Cleanup cancelled.${NC}"
    exit 0
fi

# Delete buckets
echo ""
echo -e "${BLUE}Deleting buckets...${NC}"

for bucket_info in "${buckets_to_delete[@]}"; do
    bucket=$(echo "$bucket_info" | cut -d':' -f1)
    region=$(echo "$bucket_info" | cut -d':' -f2)
    
    echo -e "${YELLOW}Deleting bucket: $bucket${NC}"
    
    # Delete all objects first
    aws s3 rm "s3://$bucket" --recursive --region "$region" 2>/dev/null || true
    
    # Delete all versions if versioning is enabled
    aws s3api delete-objects \
        --bucket "$bucket" \
        --delete "$(aws s3api list-object-versions \
            --bucket "$bucket" \
            --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
            --max-items 1000 \
            --region "$region" 2>/dev/null)" \
        --region "$region" 2>/dev/null || true
    
    # Delete the bucket
    aws s3api delete-bucket --bucket "$bucket" --region "$region" 2>/dev/null || {
        echo -e "${RED}  Failed to delete $bucket${NC}"
        continue
    }
    
    echo -e "${GREEN}  ✅ Deleted $bucket${NC}"
done

echo ""
echo -e "${GREEN}✅ Cleanup complete!${NC}"
