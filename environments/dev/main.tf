# Development environment main configuration
# This file calls the App Runner module with dev-specific settings

# Local variables for better organization
locals {
  environment = "dev"
  project     = "my-nodejs-app"
  
  # Default tags for all resources in this environment
  common_tags = {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "Terraform"
  }
}

# App Runner service for Node.js application
module "nodejs_app" {
  source = "../../modules/apprunner"
  
  # Service configuration
  service_name   = "${local.project}-${local.environment}"
  repository_url = var.github_repository_url
  branch_name    = var.github_branch
  
  # Runtime configuration
  runtime       = "NODEJS_18"
  build_command = "npm install"
  start_command = "npm start"
  
  # Environment variables
  environment_variables = {
    NODE_ENV = "production"
    PORT     = "3000"
    # Add more environment variables as needed
  }
  
  # Free tier instance configuration
  cpu    = "0.25 vCPU"  # Free tier limit
  memory = "0.5 GB"     # Free tier limit
  
  # Health check
  health_check_path = var.health_check_path
  
  # Networking
  is_publicly_accessible = true
  
  # Auto deployments
  auto_deployments_enabled = var.auto_deployments_enabled
  
  # Tags
  tags = local.common_tags
}
