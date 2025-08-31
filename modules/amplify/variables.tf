# AWS Amplify Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "repository_url" {
  description = "GitHub repository URL for the frontend application"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token for repository access"
  type        = string
  sensitive   = true
}

variable "iam_service_role_arn" {
  description = "ARN of the IAM service role for AWS Amplify"
  type        = string
}

variable "main_branch_name" {
  description = "Name of the main branch (main, master, etc.)"
  type        = string
  default     = "main"
}

variable "build_spec" {
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

variable "environment_variables" {
  description = "Environment variables for the Amplify app"
  type        = map(string)
  default     = {}
}

variable "branch_environment_variables" {
  description = "Environment variables specific to the branch"
  type        = map(string)
  default     = {}
}

variable "api_gateway_url" {
  description = "URL of the API Gateway for backend integration"
  type        = string
}

variable "domain_name" {
  description = "Custom domain name for the frontend application"
  type        = string
  default     = ""
}

variable "enable_auto_build" {
  description = "Enable automatic builds when code is pushed to the connected branch"
  type        = bool
  default     = true
}

variable "enable_auto_branch_deletion" {
  description = "Automatically delete branches in Amplify when corresponding branches are deleted in repository"
  type        = bool
  default     = true
}

variable "enable_auto_subdomain" {
  description = "Enable automatic subdomain creation for new branches"
  type        = bool
  default     = false
}

variable "create_s3_bucket" {
  description = "Whether to create an S3 bucket for the Amplify app"
  type        = bool
  default     = false
}

variable "s3_bucket_suffix" {
  description = "Suffix for the S3 bucket name"
  type        = string
  default     = "amplify-assets"
}

variable "s3_enable_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}
