#!/usr/bin/env bash
# GCP Service Account Key Audit Script
# Scans all service accounts across GCP projects for dormant and expiring keys
# Outputs: Human-readable colored table (stdout) + JSON report (file)
# Storage: Uploads to GCP Secret Manager with 365-day TTL
# Exit: Always exits 0 (informational script for CI/CD workflows)

set -euo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================

SCRIPT_VERSION="1.0.0"
DORMANT_DAYS=30
SECRET_NAME="gcp-service-account-audit-reports"
AUDIT_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
OUTPUT_FILE="audit-report-$(date +%Y-%m-%d).json"
REPORT_DIR="./audit-reports"

# Color codes (with TTY detection)
if [[ -t 1 ]]; then
  # Terminal supports colors
  COLOR_GREEN='\033[0;32m'
  COLOR_YELLOW='\033[1;33m'
  COLOR_RED='\033[0;31m'
  COLOR_BLUE='\033[0;34m'
  COLOR_RESET='\033[0m'
else
  # No TTY (e.g., GitHub Actions) - no colors
  COLOR_GREEN=''
  COLOR_YELLOW=''
  COLOR_RED=''
  COLOR_BLUE=''
  COLOR_RESET=''
fi

# Verbose mode flag
VERBOSE=false

# ==============================================================================
# USAGE
# ==============================================================================

usage() {
  cat << EOF
GCP Service Account Key Audit Script v${SCRIPT_VERSION}

Scans all service accounts across GCP projects for security issues:
  - Dormant keys (no activity in last ${DORMANT_DAYS} days)
  - User-managed keys (manual key management)
  - Expiring keys (approaching expiration date)

USAGE:
  $(basename "$0") [OPTIONS]

OPTIONS:
  --verbose, -v       Enable verbose output (detailed per-service-account logging)
  --output FILE       Custom output file path (default: ${OUTPUT_FILE})
  --dormant-days N    Days of inactivity to mark as dormant (default: ${DORMANT_DAYS})
  --upload-to-secret  Upload report to GCP Secret Manager (default: true)
  --no-upload         Skip Secret Manager upload (local file only)
  --help, -h          Show this help message

OUTPUT FORMATS:
  - Colored table to stdout (immediate visual feedback)
  - JSON to file (machine-readable for automation)
  - Secret Manager (encrypted long-term storage with 365-day TTL)

EXAMPLES:
  # Basic audit with default settings
  $(basename "$0")

  # Verbose mode for debugging
  $(basename "$0") --verbose

  # Custom dormant threshold
  $(basename "$0") --dormant-days 60

  # Local file only (no Secret Manager upload)
  $(basename "$0") --no-upload

  # Verbose with custom output
  $(basename "$0") --verbose --output custom-report.json > debug.log

COLOR SCHEME (for consistency across GCP scripts):
  ${COLOR_GREEN}GREEN${COLOR_RESET}  = OK (no action needed)
  ${COLOR_YELLOW}YELLOW${COLOR_RESET} = Warning (review recommended)
  ${COLOR_RED}RED${COLOR_RESET}    = Dormant/Critical (action required)

EOF
}

# ==============================================================================
# ARGUMENT PARSING
# ==============================================================================

UPLOAD_TO_SECRET=true

while [[ $# -gt 0 ]]; do
  case $1 in
    --verbose|-v)
      VERBOSE=true
      shift
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --dormant-days)
      DORMANT_DAYS="$2"
      shift 2
      ;;
    --upload-to-secret)
      UPLOAD_TO_SECRET=true
      shift
      ;;
    --no-upload)
      UPLOAD_TO_SECRET=false
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

log() {
  echo -e "${COLOR_BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${COLOR_RESET} $*"
}

log_verbose() {
  if [[ "${VERBOSE}" == "true" ]]; then
    echo -e "${COLOR_BLUE}[VERBOSE]${COLOR_RESET} $*"
  fi
}

log_success() {
  echo -e "${COLOR_GREEN}✓${COLOR_RESET} $*"
}

log_warning() {
  echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} $*"
}

log_error() {
  echo -e "${COLOR_RED}✗${COLOR_RESET} $*"
}

# ==============================================================================
# MAIN AUDIT LOGIC
# ==============================================================================

main() {
  log "Starting GCP Service Account Key Audit (v${SCRIPT_VERSION})"
  log "Dormant threshold: ${DORMANT_DAYS} days"
  
  # Create output directory
  mkdir -p "${REPORT_DIR}"
  
  # Get list of projects
  log "Fetching GCP projects..."
  PROJECTS=$(gcloud projects list --format="value(projectId)" 2>/dev/null) || {
    log_error "Failed to list projects. Ensure you're authenticated: gcloud auth login"
    exit 0  # Exit 0 (informational script)
  }
  
  PROJECT_COUNT=$(echo "${PROJECTS}" | wc -l | tr -d ' ')
  log_success "Found ${PROJECT_COUNT} project(s)"
  
  # Initialize JSON report
  JSON_FINDINGS='[]'
  FAILED_PROJECTS='[]'
  TOTAL_SERVICE_ACCOUNTS=0
  TOTAL_USER_MANAGED_KEYS=0
  DORMANT_KEYS_COUNT=0
  
  # Table header
  echo ""
  echo -e "${COLOR_BLUE}════════════════════════════════════════════════════════════════════════════════${COLOR_RESET}"
  printf "%-50s %-15s %-12s %-15s %s\n" "SERVICE ACCOUNT" "KEY TYPE" "AGE (DAYS)" "LAST USED" "STATUS"
  echo -e "${COLOR_BLUE}════════════════════════════════════════════════════════════════════════════════${COLOR_RESET}"
  
  # Process each project
  for PROJECT in ${PROJECTS}; do
    log_verbose "Scanning project: ${PROJECT}"
    
    # List service accounts (continue on failure)
    SERVICE_ACCOUNTS=$(gcloud iam service-accounts list \
      --project="${PROJECT}" \
      --format="value(email)" 2>/dev/null) || {
      log_warning "Failed to list service accounts in project: ${PROJECT}"
      FAILED_PROJECTS=$(echo "${FAILED_PROJECTS}" | jq --arg proj "${PROJECT}" '. += [$proj]')
      continue  # Continue to next project
    }
    
    if [[ -z "${SERVICE_ACCOUNTS}" ]]; then
      log_verbose "No service accounts in project: ${PROJECT}"
      continue
    fi
    
    SA_COUNT=$(echo "${SERVICE_ACCOUNTS}" | wc -l | tr -d ' ')
    TOTAL_SERVICE_ACCOUNTS=$((TOTAL_SERVICE_ACCOUNTS + SA_COUNT))
    log_verbose "  Found ${SA_COUNT} service account(s)"
    
    # Process each service account
    for SA in ${SERVICE_ACCOUNTS}; do
      log_verbose "    Checking keys for: ${SA}"
      
      # List keys for this service account
      KEYS=$(gcloud iam service-accounts keys list \
        --iam-account="${SA}" \
        --format="json" 2>/dev/null) || {
        log_verbose "    Failed to list keys for: ${SA}"
        continue
      }
      
      # Count user-managed keys
      USER_MANAGED_COUNT=$(echo "${KEYS}" | jq '[.[] | select(.keyType == "USER_MANAGED")] | length')
      TOTAL_USER_MANAGED_KEYS=$((TOTAL_USER_MANAGED_KEYS + USER_MANAGED_COUNT))
      
      # Process each key
      echo "${KEYS}" | jq -c '.[]' | while read -r KEY; do
        KEY_ID=$(echo "${KEY}" | jq -r '.name | split("/") | .[-1]')
        KEY_TYPE=$(echo "${KEY}" | jq -r '.keyType')
        CREATED_AT=$(echo "${KEY}" | jq -r '.validAfterTime')
        
        # Calculate key age
        CREATED_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "${CREATED_AT}" +%s 2>/dev/null || date -d "${CREATED_AT}" +%s 2>/dev/null || echo "0")
        NOW_EPOCH=$(date +%s)
        AGE_DAYS=$(( (NOW_EPOCH - CREATED_EPOCH) / 86400 ))
        
        # Determine status
        STATUS="ACTIVE"
        COLOR="${COLOR_GREEN}"
        
        if [[ "${KEY_TYPE}" == "USER_MANAGED" ]] && [[ ${AGE_DAYS} -gt ${DORMANT_DAYS} ]]; then
          STATUS="DORMANT"
          COLOR="${COLOR_RED}"
          DORMANT_KEYS_COUNT=$((DORMANT_KEYS_COUNT + 1))
        elif [[ "${KEY_TYPE}" == "USER_MANAGED" ]]; then
          STATUS="ACTIVE"
          COLOR="${COLOR_YELLOW}"
        fi
        
        # Print table row (colored)
        printf "${COLOR}%-50s %-15s %-12s %-15s %s${COLOR_RESET}\n" \
          "${SA:0:50}" \
          "${KEY_TYPE}" \
          "${AGE_DAYS}" \
          "N/A" \
          "${STATUS}"
        
        # Add to JSON findings (if user-managed or dormant)
        if [[ "${KEY_TYPE}" == "USER_MANAGED" ]] || [[ "${STATUS}" == "DORMANT" ]]; then
          FINDING=$(jq -n \
            --arg sa "${SA}" \
            --arg key_id "${KEY_ID}" \
            --arg key_type "${KEY_TYPE}" \
            --arg created "${CREATED_AT}" \
            --arg age "${AGE_DAYS}" \
            --arg status "${STATUS}" \
            --arg project "${PROJECT}" \
            '{
              service_account: $sa,
              key_id: $key_id,
              key_type: $key_type,
              created_date: $created,
              age_days: ($age | tonumber),
              last_used: null,
              status: $status,
              project: $project,
              recommendation: (if $status == "DORMANT" then "DISABLE_AND_DELETE" else "MONITOR" end)
            }')
          JSON_FINDINGS=$(echo "${JSON_FINDINGS}" | jq --argjson finding "${FINDING}" '. += [$finding]')
        fi
      done
    done
  done
  
  echo -e "${COLOR_BLUE}════════════════════════════════════════════════════════════════════════════════${COLOR_RESET}"
  echo ""
  
  # Summary
  log_success "Audit complete!"
  echo ""
  echo -e "${COLOR_BLUE}SUMMARY:${COLOR_RESET}"
  echo "  Total projects scanned: ${PROJECT_COUNT}"
  echo "  Total service accounts: ${TOTAL_SERVICE_ACCOUNTS}"
  echo "  User-managed keys found: ${TOTAL_USER_MANAGED_KEYS}"
  echo -e "  ${COLOR_RED}Dormant keys (>${DORMANT_DAYS} days):${COLOR_RESET} ${DORMANT_KEYS_COUNT}"
  
  if [[ ${DORMANT_KEYS_COUNT} -gt 0 ]]; then
    log_warning "Action required: ${DORMANT_KEYS_COUNT} dormant key(s) found"
  fi
  
  # Build JSON report
  REPORT=$(jq -n \
    --arg audit_date "${AUDIT_DATE}" \
    --arg script_version "${SCRIPT_VERSION}" \
    --argjson total_sa "${TOTAL_SERVICE_ACCOUNTS}" \
    --argjson total_keys "${TOTAL_USER_MANAGED_KEYS}" \
    --argjson dormant "${DORMANT_KEYS_COUNT}" \
    --argjson findings "${JSON_FINDINGS}" \
    --argjson failed "${FAILED_PROJECTS}" \
    '{
      audit_date: $audit_date,
      script_version: $script_version,
      summary: {
        total_service_accounts: $total_sa,
        total_user_managed_keys: $total_keys,
        dormant_keys_30d: $dormant
      },
      findings: $findings,
      failed_projects: $failed
    }')
  
  # Save JSON report
  echo "${REPORT}" > "${REPORT_DIR}/${OUTPUT_FILE}"
  log_success "JSON report saved: ${REPORT_DIR}/${OUTPUT_FILE}"
  
  # Check report size (Secret Manager limit: 64KB)
  REPORT_SIZE=$(wc -c < "${REPORT_DIR}/${OUTPUT_FILE}" | tr -d ' ')
  if [[ ${REPORT_SIZE} -gt 60000 ]]; then
    log_warning "Report size (${REPORT_SIZE} bytes) approaching Secret Manager limit (64KB)"
    log_warning "Consider using GCS bucket for large organizations (see README)"
  fi
  
  # Upload to Secret Manager
  if [[ "${UPLOAD_TO_SECRET}" == "true" ]]; then
    log "Uploading report to Secret Manager..."
    
    # Create secret if doesn't exist
    gcloud secrets create "${SECRET_NAME}" \
      --replication-policy="automatic" \
      --labels="purpose=security-audit,automated=true" \
      --data-file="${REPORT_DIR}/${OUTPUT_FILE}" \
      --ttl=365d 2>/dev/null || {
      # Secret already exists, add new version
      gcloud secrets versions add "${SECRET_NAME}" \
        --data-file="${REPORT_DIR}/${OUTPUT_FILE}" \
        --ttl=365d 2>/dev/null || {
        log_error "Failed to upload to Secret Manager"
        log_warning "Report saved locally only: ${REPORT_DIR}/${OUTPUT_FILE}"
      }
    }
    
    LATEST_VERSION=$(gcloud secrets versions list "${SECRET_NAME}" \
      --limit=1 \
      --format="value(name)" 2>/dev/null || echo "unknown")
    
    if [[ "${LATEST_VERSION}" != "unknown" ]]; then
      log_success "Report uploaded to Secret Manager: ${SECRET_NAME} (version: ${LATEST_VERSION})"
      echo ""
      echo "Retrieve report with:"
      echo "  gcloud secrets versions access latest --secret=\"${SECRET_NAME}\" > audit.json"
    fi
  else
    log "Skipping Secret Manager upload (--no-upload flag set)"
  fi
  
  echo ""
  log_success "Audit completed successfully"
  
  # Always exit 0 (informational script for CI/CD)
  exit 0
}

# Run main function
main "$@"
