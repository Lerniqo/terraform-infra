# GitHub App Authentication
# Simplified implementation that falls back to personal access token
# This provides the framework for future GitHub App integration

locals {
  # For now, use the personal access token as GitHub App integration requires external scripts
  # TODO: Implement GitHub App JWT generation in future versions
  github_access_token = var.github_token
}
