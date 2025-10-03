#!/bin/bash

# Terraform State Lock Heartbeat Monitor
# This script monitors the DynamoDB table used for Terraform state locking
# and implements a heartbeat pattern to ensure lock health

set -e

# Configuration
TABLE_NAME="terraform-state-locks"
REGION="us-east-1"
HEARTBEAT_INTERVAL=30  # seconds
LOCK_TIMEOUT=300       # 5 minutes - consider lock stale after this time
HEARTBEAT_LOCK_ID="terraform-heartbeat-monitor"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages with timestamp
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to get current timestamp in epoch format
get_timestamp() {
    date +%s
}

# Function to check if AWS CLI is available and configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        log "${RED}Error: AWS CLI not found. Please install AWS CLI.${NC}"
        exit 1
    fi

    if ! aws sts get-caller-identity &> /dev/null; then
        log "${RED}Error: AWS CLI not configured or no valid credentials.${NC}"
        exit 1
    fi
}

# Function to check if DynamoDB table exists
check_table_exists() {
    if ! aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" &> /dev/null; then
        log "${RED}Error: DynamoDB table '$TABLE_NAME' not found in region '$REGION'.${NC}"
        exit 1
    fi
}

# Function to add heartbeat item to DynamoDB
add_heartbeat() {
    local timestamp=$(get_timestamp)
    local iso_timestamp=$(date -Iseconds)
    
    # Try to update the heartbeat (will overwrite existing heartbeat)
    aws dynamodb put-item \
        --table-name "$TABLE_NAME" \
        --region "$REGION" \
        --item '{
            "LockID": {"S": "'$HEARTBEAT_LOCK_ID'"},
            "Timestamp": {"N": "'$timestamp'"},
            "ISOTimestamp": {"S": "'$iso_timestamp'"},
            "Type": {"S": "heartbeat"},
            "Status": {"S": "active"}
        }' 2>/dev/null || {
        log "${RED}Failed to update heartbeat${NC}"
        return 1
    }
    
    log "${GREEN}Heartbeat updated successfully at $(date -Iseconds)${NC}"
    return 0
}

# Function to check for stale locks
check_stale_locks() {
    local current_timestamp=$(get_timestamp)
    local stale_threshold=$((current_timestamp - LOCK_TIMEOUT))
    
    log "${BLUE}Checking for stale locks (older than $LOCK_TIMEOUT seconds)...${NC}"
    
    # Scan for items with old timestamps
    local stale_items=$(aws dynamodb scan \
        --table-name "$TABLE_NAME" \
        --region "$REGION" \
        --filter-expression "#ts < :stale_threshold AND #lockid <> :heartbeat_id" \
        --expression-attribute-names '{"#ts": "Timestamp", "#lockid": "LockID"}' \
        --expression-attribute-values '{
            ":stale_threshold": {"N": "'$stale_threshold'"},
            ":heartbeat_id": {"S": "'$HEARTBEAT_LOCK_ID'"}
        }' \
        --query 'Items[].LockID.S' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$stale_items" ] && [ "$stale_items" != "None" ]; then
        log "${YELLOW}Found stale locks: $stale_items${NC}"
        log "${YELLOW}Consider manually removing stale locks if Terraform operations are stuck.${NC}"
        
        # Optionally, you can uncomment the following lines to automatically remove stale locks
        # WARNING: Only do this if you're sure no legitimate Terraform operations are running
        # for lock_id in $stale_items; do
        #     log "${YELLOW}Removing stale lock: $lock_id${NC}"
        #     aws dynamodb delete-item --table-name "$TABLE_NAME" --region "$REGION" \
        #         --key '{"LockID": {"S": "'$lock_id'"}}'
        # done
    else
        log "${GREEN}No stale locks found${NC}"
    fi
}

# Function to display current locks
show_current_locks() {
    log "${BLUE}Current locks in table:${NC}"
    
    aws dynamodb scan \
        --table-name "$TABLE_NAME" \
        --region "$REGION" \
        --query 'Items[].[LockID.S, ISOTimestamp.S, Type.S, Status.S]' \
        --output table 2>/dev/null || {
        log "${YELLOW}No locks found or error retrieving locks${NC}"
    }
}

# Function to cleanup heartbeat on exit
cleanup() {
    log "${YELLOW}Cleaning up heartbeat monitor...${NC}"
    aws dynamodb delete-item \
        --table-name "$TABLE_NAME" \
        --region "$REGION" \
        --key '{"LockID": {"S": "'$HEARTBEAT_LOCK_ID'"}}' &>/dev/null || true
    log "${GREEN}Heartbeat monitor stopped${NC}"
}

# Function to show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help         Show this help message"
    echo "  -i, --interval N   Set heartbeat interval in seconds (default: $HEARTBEAT_INTERVAL)"
    echo "  -t, --timeout N    Set lock timeout in seconds (default: $LOCK_TIMEOUT)"
    echo "  -s, --show         Show current locks and exit"
    echo "  -c, --check        Check for stale locks and exit"
    echo "  -d, --daemon       Run as daemon (continuous monitoring)"
    echo ""
    echo "Environment Variables:"
    echo "  AWS_REGION         Override default region ($REGION)"
    echo "  TABLE_NAME         Override table name ($TABLE_NAME)"
}

# Parse command line arguments
DAEMON_MODE=false
SHOW_ONLY=false
CHECK_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -i|--interval)
            HEARTBEAT_INTERVAL="$2"
            shift 2
            ;;
        -t|--timeout)
            LOCK_TIMEOUT="$2"
            shift 2
            ;;
        -s|--show)
            SHOW_ONLY=true
            shift
            ;;
        -c|--check)
            CHECK_ONLY=true
            shift
            ;;
        -d|--daemon)
            DAEMON_MODE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Override with environment variables if set
if [ -n "$AWS_REGION" ]; then
    REGION="$AWS_REGION"
fi

if [ -n "$TF_STATE_TABLE_NAME" ]; then
    TABLE_NAME="$TF_STATE_TABLE_NAME"
fi

# Main execution
main() {
    log "${BLUE}Starting Terraform State Lock Heartbeat Monitor${NC}"
    log "${BLUE}Table: $TABLE_NAME, Region: $REGION${NC}"
    
    # Pre-flight checks
    check_aws_cli
    check_table_exists
    
    if [ "$SHOW_ONLY" = true ]; then
        show_current_locks
        exit 0
    fi
    
    if [ "$CHECK_ONLY" = true ]; then
        check_stale_locks
        exit 0
    fi
    
    # Set up cleanup on exit
    trap cleanup EXIT INT TERM
    
    if [ "$DAEMON_MODE" = true ]; then
        log "${GREEN}Running in daemon mode (interval: ${HEARTBEAT_INTERVAL}s)${NC}"
        
        while true; do
            add_heartbeat
            check_stale_locks
            sleep "$HEARTBEAT_INTERVAL"
        done
    else
        # Single run
        add_heartbeat
        check_stale_locks
        show_current_locks
    fi
}

# Run main function
main "$@"