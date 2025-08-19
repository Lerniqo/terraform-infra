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
