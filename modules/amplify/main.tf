# AWS Amplify Module
# Creates Amplify app for frontend hosting

# Amplify App
resource "aws_amplify_app" "main" {
  name          = "${var.project_name}-${var.environment}-frontend"
  description   = "Frontend application for ${var.project_name}"
  
  # GitHub repository integration
  repository    = var.repository_url
  access_token  = var.github_token

  # IAM service role for Amplify
  iam_service_role_arn = var.iam_service_role_arn

  # Build settings
  build_spec = var.build_spec

  # Enable SSR by setting platform to WEB_COMPUTE
  platform = "WEB_COMPUTE"

  # Environment variables
  environment_variables = merge(
    var.environment_variables,
    {
      REACT_APP_API_URL = var.api_gateway_url
    }
  )

  # Auto branch creation and build settings
  enable_branch_auto_build = var.enable_auto_build
  enable_branch_auto_deletion = var.enable_auto_branch_deletion

  # Custom rules for SPA routing
  custom_rule {
    source = "/<*>"
    status = "404-200"
    target = "/index.html"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Main branch (e.g., main/master)
# Main branch (e.g., main/master)
resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.main.id
  branch_name = var.main_branch_name

  enable_auto_build = var.enable_auto_build
  stage            = var.environment == "prod" ? "PRODUCTION" : "DEVELOPMENT"

  environment_variables = var.branch_environment_variables

  tags = {
    Name        = "${var.project_name}-${var.environment}-main-branch"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Webhook for GitHub integration
resource "aws_amplify_webhook" "main" {
  app_id      = aws_amplify_app.main.id
  branch_name = aws_amplify_branch.main.branch_name
  description = "GitHub webhook for ${var.project_name} ${var.environment} deployment"
}

# Domain association (optional) - disabled for now
# resource "aws_amplify_domain_association" "main" {
#   count = var.domain_name != "" ? 1 : 0

#   app_id      = aws_amplify_app.main.id
#   domain_name = var.domain_name

#   # Subdomain configuration
#   sub_domain {
#     branch_name = aws_amplify_branch.main.branch_name
#     prefix      = var.environment == "prod" ? "" : var.environment
#   }

#   # Wait for certificate validation
#   wait_for_verification = true
# }

# S3 Bucket for Amplify assets (optional)
resource "aws_s3_bucket" "amplify_assets" {
  count = var.create_s3_bucket ? 1 : 0

  bucket = "${var.project_name}-${var.environment}-${var.s3_bucket_suffix}"

  tags = {
    Name        = "${var.project_name}-${var.environment}-${var.s3_bucket_suffix}"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "Amplify Assets"
  }
}

# S3 Bucket Versioning for Amplify assets
resource "aws_s3_bucket_versioning" "amplify_assets" {
  count = var.create_s3_bucket && var.s3_enable_versioning ? 1 : 0

  bucket = aws_s3_bucket.amplify_assets[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Public Access Block for Amplify assets
resource "aws_s3_bucket_public_access_block" "amplify_assets" {
  count = var.create_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.amplify_assets[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
