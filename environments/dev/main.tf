# Terraform configuration for development environment
# ECS Fargate multi-app deployment with supporting AWS infrastructure

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Remote state backend configuration
  backend "s3" {
    bucket         = "terraform-state-lerniqo-dev"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Local values to merge ECR repository URLs with app configurations
locals {
  apps_with_ecr_images = {
    for app_name, app_config in var.apps : app_name => {
      image             = "${module.ecr.repository_urls[app_name]}:latest"
      port              = app_config.port
      public            = app_config.public
      environment_vars  = lookup(app_config, "environment_vars", {})
      secrets          = lookup(app_config, "secrets", {})
    }
  }
}

# Networking Module
# Creates VPC, 2 public subnets, 2 private subnets, internet gateway, NAT gateway, route tables, and security group
module "networking" {
  source = "../../modules/networking"

  project_name            = var.project_name
  environment             = var.environment
  vpc_cidr                = var.vpc_cidr
  public_subnet_cidrs     = var.public_subnet_cidrs
  private_subnet_cidrs    = var.private_subnet_cidrs
  availability_zones      = slice(data.aws_availability_zones.available.names, 0, 2)
  apps                    = var.apps
}

# IAM Module
# Creates ECS task execution role and task role
module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment
}

# ECR Module
# Creates ECR repositories for each application
module "ecr" {
  source = "../../modules/ecr"

  project_name  = var.project_name
  app_names     = var.app_names
  environment   = var.environment
  app_secrets   = var.app_secrets
  app_env_vars  = var.app_env_vars
}

# ALB Module
# Creates internal Application Load Balancer for routing traffic to ECS services
module "alb" {
  source = "../../modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  subnets           = module.networking.private_subnets
  security_group_id = module.networking.security_group_id
  domain_name       = var.domain_name
  apps              = local.apps_with_ecr_images
}

# ECS Module
# Creates ECS cluster, task definitions, and services
module "ecs" {
  source = "../../modules/ecs"

  cluster_name        = var.cluster_name
  environment         = var.environment
  apps                = local.apps_with_ecr_images
  subnets             = module.networking.private_subnets
  security_group_id   = module.networking.security_group_id
  execution_role_arn  = module.iam.execution_role_arn
  task_role_arn       = module.iam.task_role_arn
  secrets_arns        = module.ecr.secrets_arns
  parameter_arns      = module.ecr.parameter_arns
  target_group_arns   = module.alb.target_group_arns
  alb_dns_name        = module.alb.alb_dns_name
}

# Amplify Module
# Creates AWS Amplify app for frontend hosting
module "amplify" {
  count = var.frontend_repository_url != "" ? 1 : 0
  source = "../../modules/amplify"

  project_name          = var.project_name
  environment           = var.environment
  repository_url        = var.frontend_repository_url
  # Use direct GitHub token for repository access
  github_token          = var.github_token
  iam_service_role_arn  = module.iam.amplify_service_role_arn
  main_branch_name      = var.frontend_branch_name
  api_gateway_url       = module.apigateway.api_gateway_url
  domain_name           = var.domain_name
  build_spec            = var.amplify_build_spec

  # Enable auto-build and auto-deployment features
  enable_auto_build            = true
  enable_auto_branch_deletion  = true
  enable_auto_subdomain        = false

  environment_variables = {
    NEXT_PUBLIC_API_URL = module.apigateway.api_gateway_url
    NEXT_APP_ENV     = var.environment
  }

  branch_environment_variables = {
    NEXT_PUBLIC_API_URL = module.apigateway.api_gateway_url
    NEXT_APP_ENV     = var.environment
  }
}

# API Gateway Module
# Creates API Gateway with VPC Link integration to private ALB
module "apigateway" {
  source = "../../modules/apigateway"

  project_name      = var.project_name
  environment       = var.environment
  alb_listener_arn  = module.alb.listener_arn
  domain_name       = var.domain_name
  private_subnets   = module.networking.private_subnets
  security_group_id = module.networking.security_group_id
  amplify_app_url   = length(module.amplify) > 0 ? module.amplify[0].default_domain : ""

  services = var.api_gateway_services

  # CORS configuration
  allow_credentials = true
  cors_allowed_origins = [ "http://localhost:3000", var.cors_allowed_origin ]

  # API Gateway throttling and quota settings
  api_quota_limit = 10000
  api_rate_limit  = 100
  api_burst_limit = 200

  # Disable Cognito auth for now (can be enabled later)
  enable_auth = false
}

# S3 Module
# Creates S3 buckets based on the provided list of bucket names
module "s3" {
  count = var.s3_bucket_names != "" ? 1 : 0
  source = "../../modules/s3"

  project_name  = var.project_name
  environment   = var.environment
  bucket_names  = split(",", var.s3_bucket_names)
  enable_versioning = true
  enable_encryption = true
  block_public_access = true

  lifecycle_rules = [
    {
      id      = "versioning_cleanup"
      enabled = true
      prefix  = ""
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        }
      ]
      expiration = {
        days = 365
      }
      noncurrent_version_expiration = {
        days = 7
      }
    }
  ]
}
