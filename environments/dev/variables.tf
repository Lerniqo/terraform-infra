# Variables for the development environment

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ecs-multi-app"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "app_names" {
  description = "List of application names for ECR repositories"
  type        = list(string)
}

variable "apps" {
  description = "Map of applications with their configuration"
  type = map(object({
    image             = string
    port              = number
    public            = bool
    environment_vars  = optional(map(string), {})
    secrets          = optional(map(string), {})
  }))
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "app_secrets" {
  description = "Map of application secrets stored in AWS Secrets Manager"
  type = map(map(string))
  default = {}
}

variable "app_env_vars" {
  description = "Map of application environment variables stored in AWS Systems Manager Parameter Store"
  type = map(map(string))
  default = {}
}

variable "domain_name" {
  description = "Base domain name for the applications (e.g., learniqo.linkpc.net)"
  type        = string
  default     = ""
}

variable "api_gateway_services" {
  description = "Map of services to expose through API Gateway"
  type = map(object({
    auth_required = bool
    description   = string
    host         = string
  }))
  default = {}
}

variable "amplify_app_url" {
  description = "AWS Amplify application URL for frontend routing"
  type        = string
  default     = ""
}

# Amplify Configuration Variables
variable "frontend_repository_url" {
  description = "GitHub repository URL for the frontend application"
  type        = string
  default     = ""
}

variable "github_token" {
  description = "GitHub personal access token for repository access"
  type        = string
  sensitive   = true
  default     = ""
}

# GitHub App Configuration
variable "github_app_id" {
  description = "GitHub App ID for authentication"
  type        = string
  default     = ""
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = string
  default     = ""
}

variable "github_app_private_key" {
  description = "GitHub App private key (PEM format)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "use_github_app" {
  description = "Whether to use GitHub App authentication instead of personal access token"
  type        = bool
  default     = false
}

variable "frontend_branch_name" {
  description = "Name of the frontend main branch"
  type        = string
  default     = "main"
}

variable "amplify_build_spec" {
  description = "Build specification for Amplify"
  type        = string
  default     = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm install
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: .next
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
          - .next/cache/**/*
  EOT
}
