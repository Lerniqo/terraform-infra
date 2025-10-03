#!/bin/bash

# Terraform State Lock Heartbeat Validation Script
# This script validates the heartbeat monitoring setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Terraform State Lock Heartbeat Validation ===${NC}"

# Check 1: Verify heartbeat script exists and is executable
if [[ -x "./heartbeat-monitor.sh" ]]; then
    echo -e "${GREEN}✓ heartbeat-monitor.sh exists and is executable${NC}"
else
    echo -e "${RED}✗ heartbeat-monitor.sh not found or not executable${NC}"
    exit 1
fi

# Check 2: Test AWS CLI configuration
echo -e "\n${BLUE}Checking AWS CLI configuration...${NC}"
if aws sts get-caller-identity &>/dev/null; then
    echo -e "${GREEN}✓ AWS CLI is configured and working${NC}"
else
    echo -e "${RED}✗ AWS CLI not configured properly${NC}"
    exit 1
fi

# Check 3: Test DynamoDB table access
echo -e "\n${BLUE}Checking DynamoDB table access...${NC}"
TABLE_NAME="terraform-state-locks"
REGION="us-east-1"

if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" &>/dev/null; then
    echo -e "${GREEN}✓ DynamoDB table '$TABLE_NAME' exists and is accessible${NC}"
else
    echo -e "${RED}✗ DynamoDB table '$TABLE_NAME' not found or not accessible${NC}"
    exit 1
fi

# Check 4: Test heartbeat functionality
echo -e "\n${BLUE}Testing heartbeat functionality...${NC}"
if ./heartbeat-monitor.sh --show &>/dev/null; then
    echo -e "${GREEN}✓ Heartbeat script runs successfully${NC}"
else
    echo -e "${RED}✗ Heartbeat script failed to run${NC}"
    exit 1
fi

# Check 5: Test single heartbeat operation
echo -e "\n${BLUE}Testing single heartbeat operation...${NC}"
if ./heartbeat-monitor.sh 2>/dev/null | grep -q "Heartbeat updated successfully\|Heartbeat update skipped"; then
    echo -e "${GREEN}✓ Single heartbeat operation works${NC}"
else
    echo -e "${YELLOW}⚠ Single heartbeat operation may have issues${NC}"
fi

# Check 6: Test stale lock detection
echo -e "\n${BLUE}Testing stale lock detection...${NC}"
if ./heartbeat-monitor.sh --check &>/dev/null; then
    echo -e "${GREEN}✓ Stale lock detection works${NC}"
else
    echo -e "${RED}✗ Stale lock detection failed${NC}"
    exit 1
fi

# Check 7: Verify systemd service file (if exists)
if [[ -f "terraform-heartbeat.service" ]]; then
    echo -e "\n${BLUE}Checking systemd service file...${NC}"
    if grep -q "heartbeat-monitor.sh" terraform-heartbeat.service; then
        echo -e "${GREEN}✓ Systemd service file looks correct${NC}"
    else
        echo -e "${YELLOW}⚠ Systemd service file may need review${NC}"
    fi
fi

# Final summary
echo -e "\n${GREEN}=== Validation Complete ===${NC}"
echo -e "${GREEN}The heartbeat monitoring system is properly configured and working!${NC}"

echo -e "\n${BLUE}Usage examples:${NC}"
echo "  Single run:      ./heartbeat-monitor.sh"
echo "  Show locks:      ./heartbeat-monitor.sh --show"
echo "  Check stale:     ./heartbeat-monitor.sh --check"
echo "  Daemon mode:     ./heartbeat-monitor.sh --daemon"
echo "  Help:            ./heartbeat-monitor.sh --help"

echo -e "\n${BLUE}To set up as a service:${NC}"
echo "  sudo cp terraform-heartbeat.service /etc/systemd/system/"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl enable terraform-heartbeat"
echo "  sudo systemctl start terraform-heartbeat"
