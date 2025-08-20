# GitHub Repository Module Main Configuration
# This module creates and manages GitHub repositories with optional branch protection

# Reference existing GitHub repository
data "github_repository" "repo" {
  name = var.repository_name
}

# Create branch protection rule if enabled
resource "github_branch_protection" "protection" {
  count = var.enable_branch_protection ? 1 : 0
  
  repository_id = data.github_repository.repo.node_id
  pattern       = coalesce(var.protected_branch, data.github_repository.repo.default_branch)

  # Admin enforcement
  enforce_admins = var.enforce_admins

  # Required status checks
  dynamic "required_status_checks" {
    for_each = length(var.required_status_checks) > 0 ? [1] : []
    content {
      strict   = var.strict_status_checks
      contexts = var.required_status_checks
    }
  }

  # Pull request reviews
  dynamic "required_pull_request_reviews" {
    for_each = var.required_approving_review_count > 0 ? [1] : []
    content {
      dismiss_stale_reviews           = var.dismiss_stale_reviews
      require_code_owner_reviews      = var.require_code_owner_reviews
      required_approving_review_count = var.required_approving_review_count
      restrict_dismissals             = var.restrict_dismissals
    }
  }

  # Branch restrictions
  allows_deletions                = var.allows_deletions
  allows_force_pushes            = var.allows_force_pushes
  require_signed_commits         = var.require_signed_commits
  require_conversation_resolution = var.require_conversation_resolution
  lock_branch                    = var.lock_branch
}

# Create deploy keys
resource "github_repository_deploy_key" "deploy_keys" {
  for_each = var.deploy_keys

  title      = each.value.title
  repository = data.github_repository.repo.name
  key        = each.value.key
  read_only  = each.value.read_only
}

# Create repository files
resource "github_repository_file" "files" {
  for_each = var.repository_files

  repository          = data.github_repository.repo.name
  branch              = each.value.branch
  file                = each.key
  content             = each.value.content
  commit_message      = each.value.commit_message
  commit_author       = each.value.commit_author
  commit_email        = each.value.commit_email
  overwrite_on_create = each.value.overwrite_on_create

  depends_on = [data.github_repository.repo]
}

# Create webhook for AWS Amplify integration (if webhook URL is provided)
resource "github_repository_webhook" "amplify" {
  count = var.amplify_webhook_url != "" && var.amplify_webhook_url != null ? 1 : 0

  repository = data.github_repository.repo.name

  configuration {
    url          = var.amplify_webhook_url
    content_type = "json"
    insecure_ssl = false
  }

  active = true

  events = [
    "push",
    "pull_request"
  ]

  lifecycle {
    ignore_changes = [configuration[0].url]
  }
}
