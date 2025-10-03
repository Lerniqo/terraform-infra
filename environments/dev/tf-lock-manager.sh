#!/bin/bash

# Terraform State Lock Management Script
# Helper script for managing terraform state locks with heartbeat monitoring

set -e

TABLE_NAME="terraform-state-locks"
REGION="us-east-1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HEARTBEAT_SCRIPT="$SCRIPT_DIR/heartbeat-monitor.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to force unlock a specific lock
force_unlock() {
    local lock_id="$1"
    if [ -z "$lock_id" ]; then
        log "${RED}Error: Lock ID required${NC}"
        return 1
    fi
    
    log "${YELLOW}Force unlocking: $lock_id${NC}"
    aws dynamodb delete-item \
        --table-name "$TABLE_NAME" \
        --region "$REGION" \
        --key "{\"LockID\": {\"S\": \"$lock_id\"}}" && \
    log "${GREEN}Successfully unlocked: $lock_id${NC}" || \
    log "${RED}Failed to unlock: $lock_id${NC}"
}

# Function to force unlock all locks (except heartbeat)
force_unlock_all() {
    log "${YELLOW}WARNING: This will force unlock ALL terraform state locks!${NC}"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        log "${BLUE}Operation cancelled${NC}"
        return 0
    fi
    
    # Get all lock IDs except heartbeat
    local lock_ids=$(aws dynamodb scan \
        --table-name "$TABLE_NAME" \
        --region "$REGION" \
        --filter-expression "#lockid <> :heartbeat_id" \
        --expression-attribute-names '{"#lockid": "LockID"}' \
        --expression-attribute-values '{":heartbeat_id": {"S": "terraform-heartbeat-monitor"}}' \
        --query 'Items[].LockID.S' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$lock_ids" ] && [ "$lock_ids" != "None" ]; then
        for lock_id in $lock_ids; do
            force_unlock "$lock_id"
        done
    else
        log "${GREEN}No locks to remove${NC}"
    fi
}

# Function to show lock status with detailed information
show_detailed_status() {
    log "${BLUE}Detailed Terraform State Lock Status${NC}"
    echo "========================================"
    
    # Check if heartbeat monitor is running
    if pgrep -f "heartbeat-monitor.sh" > /dev/null; then
        log "${GREEN}Heartbeat monitor is running${NC}"
    else
        log "${YELLOW}Heartbeat monitor is not running${NC}"
    fi
    
    # Show all locks with timestamps
    echo ""
    log "${BLUE}Current locks:${NC}"
    aws dynamodb scan \
        --table-name "$TABLE_NAME" \
        --region "$REGION" \
        --query 'Items[]' \
        --output table 2>/dev/null || {
        log "${YELLOW}No locks found or error retrieving locks${NC}"
    }
    
    # Check for stale locks
    echo ""
    "$HEARTBEAT_SCRIPT" --check
}

# Function to start heartbeat monitoring
start_heartbeat() {
    if pgrep -f "heartbeat-monitor.sh.*daemon" > /dev/null; then
        log "${YELLOW}Heartbeat monitor is already running${NC}"
        return 0
    fi
    
    log "${GREEN}Starting heartbeat monitor in background...${NC}"
    nohup "$HEARTBEAT_SCRIPT" --daemon > /tmp/terraform-heartbeat.log 2>&1 &
    sleep 2
    
    if pgrep -f "heartbeat-monitor.sh.*daemon" > /dev/null; then
        log "${GREEN}Heartbeat monitor started successfully${NC}"
        log "${BLUE}Log file: /tmp/terraform-heartbeat.log${NC}"
    else
        log "${RED}Failed to start heartbeat monitor${NC}"
        return 1
    fi
}

# Function to stop heartbeat monitoring
stop_heartbeat() {
    local pids=$(pgrep -f "heartbeat-monitor.sh.*daemon" || echo "")
    
    if [ -z "$pids" ]; then
        log "${YELLOW}Heartbeat monitor is not running${NC}"
        return 0
    fi
    
    log "${YELLOW}Stopping heartbeat monitor...${NC}"
    kill $pids
    sleep 2
    
    # Cleanup heartbeat entry
    aws dynamodb delete-item \
        --table-name "$TABLE_NAME" \
        --region "$REGION" \
        --key '{"LockID": {"S": "terraform-heartbeat-monitor"}}' &>/dev/null || true
    
    log "${GREEN}Heartbeat monitor stopped${NC}"
}

# Function to show usage
usage() {
    echo "Terraform State Lock Management Tool"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  status              Show detailed lock status"
    echo "  start-heartbeat     Start heartbeat monitoring"
    echo "  stop-heartbeat      Stop heartbeat monitoring"
    echo "  restart-heartbeat   Restart heartbeat monitoring"
    echo "  unlock <lock-id>    Force unlock a specific lock"
    echo "  unlock-all          Force unlock all locks (except heartbeat)"
    echo "  clean               Remove stale locks"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 start-heartbeat"
    echo "  $0 unlock environments/dev/terraform.tfstate"
    echo "  $0 unlock-all"
}

# Main command handling
case "${1:-}" in
    status)
        show_detailed_status
        ;;
    start-heartbeat)
        start_heartbeat
        ;;
    stop-heartbeat)
        stop_heartbeat
        ;;
    restart-heartbeat)
        stop_heartbeat
        sleep 2
        start_heartbeat
        ;;
    unlock)
        if [ -z "$2" ]; then
            echo "Error: Lock ID required"
            echo "Usage: $0 unlock <lock-id>"
            exit 1
        fi
        force_unlock "$2"
        ;;
    unlock-all)
        force_unlock_all
        ;;
    clean)
        "$HEARTBEAT_SCRIPT" --check
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo "Error: Unknown command '${1:-}'"
        echo ""
        usage
        exit 1
        ;;
esac