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
      image  = "${module.ecr.repository_urls[app_name]}:latest"
      port   = app_config.port
      public = app_config.public
    }
  }
}

# Networking Module
# Creates VPC, 2 public subnets, internet gateway, route table, and security group
module "networking" {
  source = "../../modules/networking"

  project_name            = var.project_name
  environment             = var.environment
  vpc_cidr                = var.vpc_cidr
  public_subnet_cidrs     = var.public_subnet_cidrs
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

  project_name = var.project_name
  app_names    = var.app_names
  environment  = var.environment
}

# ECS Module
# Creates ECS cluster, task definitions, and services
module "ecs" {
  source = "../../modules/ecs"

  cluster_name        = var.cluster_name
  environment         = var.environment
  apps                = local.apps_with_ecr_images
  subnets             = module.networking.public_subnets
  security_group_id   = module.networking.security_group_id
  execution_role_arn  = module.iam.execution_role_arn
  task_role_arn       = module.iam.task_role_arn
}
