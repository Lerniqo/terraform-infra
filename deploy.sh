#!/bin/bash

# Kafka Infrastructure Deployment Script
# This script helps deploy Kafka infrastructure to AWS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_color() {
    echo -e "${1}${2}${NC}"
}

print_header() {
    echo ""
    print_color "$BLUE" "=========================================="
    print_color "$BLUE" " Kafka Infrastructure Deployment"
    print_color "$BLUE" "=========================================="
    echo ""
}

check_prerequisites() {
    print_color "$BLUE" "Checking prerequisites..."
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_color "$RED" "Error: Terraform is not installed"
        exit 1
    fi
    print_color "$GREEN" "✓ Terraform is installed"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_color "$YELLOW" "Warning: AWS CLI is not installed (optional)"
    else
        print_color "$GREEN" "✓ AWS CLI is installed"
    fi
    
    # Check configuration file
    if [ ! -f "terraform.prod.tfvars" ]; then
        print_color "$RED" "Error: terraform.prod.tfvars not found"
        print_color "$YELLOW" "Please copy terraform.tfvars.example to terraform.prod.tfvars and customize it"
        exit 1
    fi
    print_color "$GREEN" "✓ Configuration file exists"
    
    echo ""
}

check_aws_credentials() {
    print_color "$BLUE" "Checking AWS credentials..."
    
    if aws sts get-caller-identity &> /dev/null; then
        AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "unknown")
        AWS_REGION=$(aws configure get region 2>/dev/null || echo "not set")
        print_color "$GREEN" "✓ AWS credentials are configured"
        print_color "$YELLOW" "Account: $AWS_ACCOUNT"
        print_color "$YELLOW" "Region: $AWS_REGION"
    else
        print_color "$RED" "Error: AWS credentials not configured"
        print_color "$YELLOW" "Please configure AWS credentials using one of these methods:"
        print_color "$YELLOW" "1. aws configure"
        print_color "$YELLOW" "2. Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)"
        print_color "$YELLOW" "3. IAM roles (if running on EC2)"
        exit 1
    fi
    echo ""
}

check_security_config() {
    print_color "$BLUE" "Checking security configuration..."
    
    # Check if trusted CIDR blocks are still using example values
    if grep -q "203.0.113.0/24" terraform.prod.tfvars; then
        print_color "$YELLOW" "Warning: You are using example trusted CIDR blocks"
        print_color "$YELLOW" "Please update trusted_cidr_blocks in terraform.prod.tfvars with your actual IP addresses"
        print_color "$YELLOW" "Current configuration allows access from example IPs only"
        echo ""
        read -p "Do you want to continue anyway? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_color "$YELLOW" "Please update terraform.prod.tfvars and run this script again"
            exit 1
        fi
    else
        print_color "$GREEN" "✓ Custom trusted CIDR blocks configured"
    fi
    echo ""
}

deploy_infrastructure() {
    print_color "$BLUE" "Deploying Kafka infrastructure..."
    
    # Initialize Terraform
    print_color "$YELLOW" "Initializing Terraform..."
    terraform init
    
    # Format and validate
    print_color "$YELLOW" "Formatting and validating Terraform files..."
    terraform fmt -recursive
    terraform validate
    
    # Plan deployment
    print_color "$YELLOW" "Planning deployment..."
    terraform plan -var-file="terraform.prod.tfvars"
    
    echo ""
    print_color "$YELLOW" "This will deploy Kafka infrastructure to AWS."
    print_color "$YELLOW" "Review the plan above carefully."
    echo ""
    read -p "Do you want to proceed with deployment? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_color "$YELLOW" "Applying Terraform configuration..."
        terraform apply -var-file="terraform.prod.tfvars"
        
        if [ $? -eq 0 ]; then
            print_color "$GREEN" "✓ Deployment completed successfully!"
            show_connection_info
        else
            print_color "$RED" "✗ Deployment failed"
            exit 1
        fi
    else
        print_color "$YELLOW" "Deployment cancelled"
        exit 0
    fi
}

show_connection_info() {
    echo ""
    print_color "$BLUE" "=========================================="
    print_color "$BLUE" " Kafka Connection Information"
    print_color "$BLUE" "=========================================="
    echo ""
    
    # Get outputs
    PUBLIC_IP=$(terraform output -raw kafka_public_ip 2>/dev/null || echo "Not available")
    BOOTSTRAP_SERVERS=$(terraform output -raw kafka_bootstrap_servers_prod 2>/dev/null || echo "Not available")
    SSH_COMMAND=$(terraform output -raw ssh_command 2>/dev/null || echo "Not configured")
    
    print_color "$YELLOW" "Public IP: $PUBLIC_IP"
    print_color "$YELLOW" "Bootstrap Servers: $BOOTSTRAP_SERVERS"
    print_color "$YELLOW" "SSH Command: $SSH_COMMAND"
    
    echo ""
    print_color "$GREEN" "Kafka is now ready for use!"
    print_color "$YELLOW" "Note: It may take a few minutes for Kafka to fully start up."
    
    if [ "$SSH_COMMAND" != "Not configured" ]; then
        echo ""
        print_color "$BLUE" "Available commands on the instance:"
        print_color "$YELLOW" "• kafka-status          - Check Kafka status"
        print_color "$YELLOW" "• kafka-topic-create    - Create new topics"
        print_color "$YELLOW" "• kafka-restart         - Restart Kafka"
        print_color "$YELLOW" "• kafka-info           - Show cluster info"
    fi
    
    echo ""
    print_color "$BLUE" "Example usage:"
    print_color "$YELLOW" "kafka-console-producer.sh --bootstrap-server $BOOTSTRAP_SERVERS --topic test-topic"
    print_color "$YELLOW" "kafka-console-consumer.sh --bootstrap-server $BOOTSTRAP_SERVERS --topic test-topic --from-beginning"
    echo ""
}

# Main execution
print_header
check_prerequisites
check_aws_credentials
check_security_config
deploy_infrastructure
