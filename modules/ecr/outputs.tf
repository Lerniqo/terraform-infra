output "repository_urls" {
  description = "Map of ECR repository URLs"
  value = {
    for name, repo in aws_ecr_repository.app_repos : name => repo.repository_url
  }
}

output "repository_arns" {
  description = "Map of ECR repository ARNs"
  value = {
    for name, repo in aws_ecr_repository.app_repos : name => repo.arn
  }
}
