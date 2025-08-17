# Environment-aware outputs
output "environment" {
  description = "Current environment"
  value       = var.environment
}

# Local environment outputs (dev)
output "kafka_bootstrap_servers" {
  description = "Kafka bootstrap servers for local development"
  value       = var.environment == "dev" ? module.local[0].kafka_bootstrap_servers : null
}

output "kafka_external_host" {
  description = "Kafka external host"
  value       = var.environment == "dev" ? module.local[0].kafka_external_host : null
}

output "kafka_external_port" {
  description = "Kafka external port"
  value       = var.environment == "dev" ? module.local[0].kafka_external_port : null
}

output "kafka_internal_host" {
  description = "Kafka internal host (for container-to-container communication)"
  value       = var.environment == "dev" ? module.local[0].kafka_internal_host : null
}

output "kafka_internal_port" {
  description = "Kafka internal port"
  value       = var.environment == "dev" ? module.local[0].kafka_internal_port : null
}

# AWS environment outputs (prod)
output "kafka_instance_id" {
  description = "Kafka EC2 instance ID"
  value       = var.environment == "prod" ? module.aws[0].instance_id : null
}

output "kafka_public_ip" {
  description = "Kafka EC2 instance public IP"
  value       = var.environment == "prod" ? module.aws[0].kafka_public_ip : null
}

output "kafka_bootstrap_servers_prod" {
  description = "Kafka bootstrap servers for production"
  value       = var.environment == "prod" ? module.aws[0].kafka_bootstrap_servers : null
}

output "ssh_command" {
  description = "SSH command to connect to the Kafka instance"
  value       = var.environment == "prod" ? module.aws[0].ssh_command : null
}

output "vpc_id" {
  description = "VPC ID"
  value       = var.environment == "prod" ? module.aws[0].vpc_id : null
}

output "security_group_id" {
  description = "Security Group ID"
  value       = var.environment == "prod" ? module.aws[0].security_group_id : null
}

output "public_subnet_id" {
  description = "Public subnet ID (prod environment)"
  value       = var.environment == "prod" ? module.aws[0].subnet_id : null
}
