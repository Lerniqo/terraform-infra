# Kafka Terraform Infrastructure Makefile

.PHONY: help init plan apply destroy fmt validate clean ssh-prod info-prod

# Default environment
ENV ?= prod
VAR_FILE = terraform.$(ENV).tfvars

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
NC = \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)Kafka Infrastructure Management$(NC)"
	@echo "$(YELLOW)Available commands:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Initialize Terraform
	@echo "$(BLUE)Initializing Terraform...$(NC)"
	terraform init

validate: fmt ## Validate Terraform configuration
	@echo "$(BLUE)Validating Terraform configuration...$(NC)"
	terraform validate

fmt: ## Format Terraform files
	@echo "$(BLUE)Formatting Terraform files...$(NC)"
	terraform fmt -recursive

plan: validate ## Plan Terraform deployment
	@echo "$(BLUE)Planning Terraform deployment for $(ENV) environment...$(NC)"
	@if [ ! -f $(VAR_FILE) ]; then \
		echo "$(RED)Error: $(VAR_FILE) not found!$(NC)"; \
		exit 1; \
	fi
	terraform plan -var-file=$(VAR_FILE)

apply: validate ## Apply Terraform configuration
	@echo "$(BLUE)Applying Terraform configuration for $(ENV) environment...$(NC)"
	@if [ ! -f $(VAR_FILE) ]; then \
		echo "$(RED)Error: $(VAR_FILE) not found!$(NC)"; \
		exit 1; \
	fi
	terraform apply -var-file=$(VAR_FILE)

destroy: ## Destroy Terraform infrastructure
	@echo "$(RED)Destroying Terraform infrastructure for $(ENV) environment...$(NC)"
	@if [ ! -f $(VAR_FILE) ]; then \
		echo "$(RED)Error: $(VAR_FILE) not found!$(NC)"; \
		exit 1; \
	fi
	terraform destroy -var-file=$(VAR_FILE)

output: ## Show Terraform outputs
	@echo "$(BLUE)Terraform outputs for $(ENV) environment:$(NC)"
	terraform output

info-prod: ## Show production Kafka connection information
	@echo "$(BLUE)Production Kafka Information:$(NC)"
	@echo "$(YELLOW)Public IP:$(NC) $$(terraform output -raw kafka_public_ip 2>/dev/null || echo 'Not available')"
	@echo "$(YELLOW)Bootstrap Servers:$(NC) $$(terraform output -raw kafka_bootstrap_servers_prod 2>/dev/null || echo 'Not available')"
	@echo "$(YELLOW)SSH Command:$(NC) $$(terraform output -raw ssh_command 2>/dev/null || echo 'Not configured')"
	@echo "$(YELLOW)VPC ID:$(NC) $$(terraform output -raw vpc_id 2>/dev/null || echo 'Not available')"
	@echo "$(YELLOW)Security Group:$(NC) $$(terraform output -raw security_group_id 2>/dev/null || echo 'Not available')"

ssh-prod: ## SSH into production Kafka instance
	@SSH_CMD=$$(terraform output -raw ssh_command 2>/dev/null); \
	if [ -z "$$SSH_CMD" ] || [ "$$SSH_CMD" = "null" ]; then \
		echo "$(RED)Error: SSH not configured$(NC)"; \
		exit 1; \
	else \
		eval $$SSH_CMD; \
	fi

clean: ## Clean Terraform temporary files
	@echo "$(BLUE)Cleaning Terraform temporary files...$(NC)"
	rm -rf .terraform/
	rm -f .terraform.lock.hcl
	rm -f terraform.tfplan

check-aws: ## Check AWS credentials
	@echo "$(BLUE)Checking AWS credentials...$(NC)"
	@aws sts get-caller-identity > /dev/null 2>&1 && \
		echo "$(GREEN)AWS credentials configured$(NC)" || \
		echo "$(RED)AWS credentials not configured$(NC)"

# Development environment
dev-up: ## Start local development environment
	$(MAKE) apply ENV=dev

dev-down: ## Stop local development environment
	$(MAKE) destroy ENV=dev

# Quick deployment shortcuts
quick-prod: init check-aws plan apply ## Quick production deployment
