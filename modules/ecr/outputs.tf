output "repository_urls" {
  description = "Map of ECR repository URLs keyed by app name"
  value = {
    for repo_key, repo in aws_ecr_repository.app_repos : repo_key => repo.repository_url
  }
}

output "repository_arns" {
  description = "Map of ECR repository ARNs keyed by app name"
  value = {
    for repo_key, repo in aws_ecr_repository.app_repos : repo_key => repo.arn
  }
}

output "repository_names" {
  description = "Map of ECR repository names keyed by app name"
  value = {
    for repo_key, repo in aws_ecr_repository.app_repos : repo_key => repo.name
  }
}

output "secrets_arns" {
  description = "Map of AWS Secrets Manager secret ARNs keyed by app name"
  value = {
    for secret_key, secret in aws_secretsmanager_secret.app_secrets : secret_key => secret.arn
  }
}

output "parameter_arns" {
  description = "Map of AWS Systems Manager Parameter Store parameter ARNs keyed by app name"
  value = {
    for param_key, param in aws_ssm_parameter.app_env_vars : param_key => param.arn
  }
}

output "secrets_names" {
  description = "Map of AWS Secrets Manager secret names keyed by app name"
  value = {
    for secret_key, secret in aws_secretsmanager_secret.app_secrets : secret_key => secret.name
  }
}

output "parameter_names" {
  description = "Map of AWS Systems Manager Parameter Store parameter names keyed by app name"
  value = {
    for param_key, param in aws_ssm_parameter.app_env_vars : param_key => param.name
  }
}
