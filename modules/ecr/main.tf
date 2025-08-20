# ECR Repositories
resource "aws_ecr_repository" "app_repos" {
  for_each = toset(var.app_names)

  name                 = "${var.project_name}-${var.environment}-${each.value}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-${each.value}"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Application = each.value
  }
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "app_repos_policy" {
  for_each = aws_ecr_repository.app_repos

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# AWS Secrets Manager secrets for each application
resource "aws_secretsmanager_secret" "app_secrets" {
  for_each = var.app_secrets != null ? var.app_secrets : {}

  name        = "${var.project_name}-${var.environment}-${each.key}-secrets"
  description = "Secrets for ${each.key} application"

  tags = {
    Name        = "${var.project_name}-${var.environment}-${each.key}-secrets"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Application = each.key
  }
}

# Store the secret values
resource "aws_secretsmanager_secret_version" "app_secrets_version" {
  for_each = var.app_secrets != null ? var.app_secrets : {}

  secret_id     = aws_secretsmanager_secret.app_secrets[each.key].id
  secret_string = jsonencode(each.value)
}

# AWS Systems Manager Parameter Store parameters for environment variables
resource "aws_ssm_parameter" "app_env_vars" {
  for_each = var.app_env_vars != null ? var.app_env_vars : {}

  name        = "/${var.project_name}/${var.environment}/${each.key}"
  description = "Environment variables for ${each.key} application"
  type        = "String"
  value       = jsonencode(each.value)

  tags = {
    Name        = "${var.project_name}-${var.environment}-${each.key}-env-vars"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Application = each.key
  }
}
