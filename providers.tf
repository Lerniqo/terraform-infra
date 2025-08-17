# Provider configuration for multi-environment Kafka infrastructure

# AWS provider for production environment
provider "aws" {
  region = var.aws_region

  # Only use explicit credentials if provided, otherwise use default AWS credential chain
  access_key = var.aws_access_key != "" ? var.aws_access_key : null
  secret_key = var.aws_secret_key != "" ? var.aws_secret_key : null

  default_tags {
    tags = merge(var.common_tags, {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    })
  }
}

# Docker provider for local development
# Note: This is only used when environment = "dev"
provider "docker" {
  host = var.docker_host
}
