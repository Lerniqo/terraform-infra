.PHONY: init plan apply destroy up down clean

# Initialize Terraform
init:
	terraform init

# Plan the infrastructure changes
plan:
	terraform plan

# Apply the infrastructure changes
apply:
	terraform apply -auto-approve

# Destroy the infrastructure
destroy:
	terraform destroy -auto-approve

# Start Kafka (alias for apply)
up: apply

# Stop Kafka (alias for destroy)
down: destroy

# Clean up Terraform state and cache
clean:
	rm -rf .terraform terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl

# Show current Terraform state
status:
	terraform show

# Validate Terraform configuration
validate:
	terraform validate

# Format Terraform files
fmt:
	terraform fmt -recursive

# Check Kafka status
kafka-status:
	docker ps --filter "name=kafka" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# View Kafka logs
kafka-logs:
	docker logs $$(docker ps -q --filter "name=kafka") --follow
