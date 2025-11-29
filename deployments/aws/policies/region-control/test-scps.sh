#!/bin/bash

# AWS Service Control Policy Test Script
# Tests both region restrictions and S3 public access blocking

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🧪 AWS Service Control Policy Testing${NC}"
echo "======================================="
echo ""

# Configuration
TEST_PREFIX="scp-test-$(date +%s)"
APPROVED_REGION="eu-north-1"
BLOCKED_REGION="us-east-2"

echo -e "${CYAN}Test Configuration:${NC}"
echo "  Approved Region: $APPROVED_REGION (Stockholm)"
echo "  Blocked Region: $BLOCKED_REGION (Ohio)"
echo "  Test Prefix: $TEST_PREFIX"
echo ""

# Test Results
declare -A test_results

# ============================================================================
# TEST 1: Region Restriction - Blocked Region
# ============================================================================

echo -e "\n${BLUE}📍 Test 1: Create S3 bucket in BLOCKED region (Ohio)${NC}"
echo "Expected: ❌ DENIED by SCP"

test_bucket_blocked="$TEST_PREFIX-blocked-region"

if aws s3 mb "s3://$test_bucket_blocked" --region "$BLOCKED_REGION" 2>&1 | grep -q "AccessDenied"; then
    echo -e "${GREEN}✅ PASS: Bucket creation DENIED in Ohio (SCP working!)${NC}"
    test_results["region_block"]="PASS"
else
    echo -e "${RED}❌ FAIL: Bucket was created in Ohio (SCP not working!)${NC}"
    test_results["region_block"]="FAIL"
    # Cleanup if created
    aws s3 rb "s3://$test_bucket_blocked" --region "$BLOCKED_REGION" 2>/dev/null || true
fi

# ============================================================================
# TEST 2: Region Restriction - Approved Region
# ============================================================================

echo -e "\n${BLUE}📍 Test 2: Create S3 bucket in APPROVED region (Stockholm)${NC}"
echo "Expected: ✅ ALLOWED"

test_bucket_approved="$TEST_PREFIX-approved-region"

if aws s3 mb "s3://$test_bucket_approved" --region "$APPROVED_REGION" 2>&1; then
    echo -e "${GREEN}✅ PASS: Bucket created successfully in Stockholm${NC}"
    test_results["region_allow"]="PASS"
else
    echo -e "${RED}❌ FAIL: Bucket creation failed in Stockholm${NC}"
    test_results["region_allow"]="FAIL"
fi

# ============================================================================
# TEST 3: S3 Public Access - Public ACL
# ============================================================================

echo -e "\n${BLUE}🔓 Test 3: Make bucket PUBLIC with ACL${NC}"
echo "Expected: ❌ DENIED by SCP"

if [ "${test_results["region_allow"]}" == "PASS" ]; then
    if aws s3api put-bucket-acl --bucket "$test_bucket_approved" --acl public-read 2>&1 | grep -q "AccessDenied"; then
        echo -e "${GREEN}✅ PASS: Public ACL DENIED by SCP${NC}"
        test_results["public_acl"]="PASS"
    else
        echo -e "${RED}❌ FAIL: Public ACL was allowed (SCP not working!)${NC}"
        test_results["public_acl"]="FAIL"
    fi
else
    echo -e "${YELLOW}⏭️  SKIP: Previous test failed${NC}"
    test_results["public_acl"]="SKIP"
fi

# ============================================================================
# TEST 4: S3 Public Access Block Removal
# ============================================================================

echo -e "\n${BLUE}🔓 Test 4: Remove public access block${NC}"
echo "Expected: ❌ DENIED by SCP"

if [ "${test_results["region_allow"]}" == "PASS" ]; then
    # First add public access block
    aws s3api put-public-access-block \
        --bucket "$test_bucket_approved" \
        --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
        2>&1 > /dev/null || true
    
    # Try to remove it (should be denied)
    if aws s3api delete-public-access-block --bucket "$test_bucket_approved" 2>&1 | grep -q "AccessDenied"; then
        echo -e "${GREEN}✅ PASS: Removing public access block DENIED by SCP${NC}"
        test_results["block_removal"]="PASS"
    else
        echo -e "${RED}❌ FAIL: Public access block removal was allowed (SCP not working!)${NC}"
        test_results["block_removal"]="FAIL"
    fi
else
    echo -e "${YELLOW}⏭️  SKIP: Previous test failed${NC}"
    test_results["block_removal"]="SKIP"
fi

# ============================================================================
# TEST 5: Private Bucket in Approved Region
# ============================================================================

echo -e "\n${BLUE}🔒 Test 5: Create PRIVATE bucket in Stockholm${NC}"
echo "Expected: ✅ ALLOWED"

test_bucket_private="$TEST_PREFIX-private-bucket"

if aws s3 mb "s3://$test_bucket_private" --region "$APPROVED_REGION" 2>&1; then
    # Add public access block (should succeed)
    if aws s3api put-public-access-block \
        --bucket "$test_bucket_private" \
        --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
        2>&1 > /dev/null; then
        echo -e "${GREEN}✅ PASS: Private bucket with access block created successfully${NC}"
        test_results["private_bucket"]="PASS"
    else
        echo -e "${RED}❌ FAIL: Could not add public access block${NC}"
        test_results["private_bucket"]="FAIL"
    fi
else
    echo -e "${RED}❌ FAIL: Private bucket creation failed${NC}"
    test_results["private_bucket"]="FAIL"
fi

# ============================================================================
# CLEANUP
# ============================================================================

echo -e "\n${BLUE}🧹 Cleaning up test resources...${NC}"

# Delete buckets in Stockholm
for bucket in "$test_bucket_approved" "$test_bucket_private"; do
    if aws s3 ls "s3://$bucket" 2>/dev/null; then
        aws s3 rb "s3://$bucket" --force --region "$APPROVED_REGION" 2>/dev/null || true
        echo -e "${GREEN}  ✅ Deleted $bucket${NC}"
    fi
done

# Check for any buckets in Ohio (shouldn't exist, but check anyway)
if aws s3 ls "s3://$test_bucket_blocked" 2>/dev/null; then
    aws s3 rb "s3://$test_bucket_blocked" --force --region "$BLOCKED_REGION" 2>/dev/null || true
    echo -e "${YELLOW}  ⚠️  Deleted unexpected bucket in Ohio${NC}"
fi

# ============================================================================
# TEST RESULTS SUMMARY
# ============================================================================

echo ""
echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}       TEST RESULTS SUMMARY       ${NC}"
echo -e "${BLUE}=================================${NC}"
echo ""

total_tests=0
passed_tests=0

for test_name in "${!test_results[@]}"; do
    result="${test_results[$test_name]}"
    total_tests=$((total_tests + 1))
    
    case $result in
        PASS)
            echo -e "${GREEN}✅ $test_name: PASS${NC}"
            passed_tests=$((passed_tests + 1))
            ;;
        FAIL)
            echo -e "${RED}❌ $test_name: FAIL${NC}"
            ;;
        SKIP)
            echo -e "${YELLOW}⏭️  $test_name: SKIP${NC}"
            ;;
    esac
done

echo ""
echo -e "${CYAN}Results: $passed_tests/$total_tests tests passed${NC}"

if [ $passed_tests -eq $total_tests ]; then
    echo -e "${GREEN}🎉 All tests passed! Your SCPs are working correctly!${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed. Check your SCP configuration.${NC}"
    exit 1
fi
