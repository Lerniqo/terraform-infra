# GitHub Repository Module Variables
# This module creates and manages GitHub repositories with configurable settings

variable "repository_name" {
  description = "Name of the repository to create"
  type        = string
}

variable "repository_description" {
  description = "Description for the repository"
  type        = string
  default     = "Repository managed by Terraform"
}

variable "repository_visibility" {
  description = "Visibility of the repository (public or private)"
  type        = string
  default     = "private"
  
  validation {
    condition     = contains(["public", "private"], var.repository_visibility)
    error_message = "Repository visibility must be either 'public' or 'private'."
  }
}

variable "auto_init" {
  description = "Whether to auto-initialize the repository with a README"
  type        = bool
  default     = true
}

variable "gitignore_template" {
  description = "Template to use for .gitignore file"
  type        = string
  default     = null
}

variable "license_template" {
  description = "License template to use for the repository"
  type        = string
  default     = null
}

variable "homepage_url" {
  description = "URL of the homepage for this repository"
  type        = string
  default     = null
}

variable "topics" {
  description = "List of topics for the repository"
  type        = list(string)
  default     = []
}

variable "has_issues" {
  description = "Enable issues for the repository"
  type        = bool
  default     = true
}

variable "has_projects" {
  description = "Enable projects for the repository"
  type        = bool
  default     = false
}

variable "has_wiki" {
  description = "Enable wiki for the repository"
  type        = bool
  default     = false
}

variable "has_downloads" {
  description = "Enable downloads for the repository"
  type        = bool
  default     = false
}

variable "vulnerability_alerts" {
  description = "Enable vulnerability alerts"
  type        = bool
  default     = true
}

variable "delete_branch_on_merge" {
  description = "Delete head branch after a pull request merge"
  type        = bool
  default     = true
}

variable "allow_merge_commit" {
  description = "Allow merge commits"
  type        = bool
  default     = true
}

variable "allow_squash_merge" {
  description = "Allow squash merging"
  type        = bool
  default     = true
}

variable "allow_rebase_merge" {
  description = "Allow rebase merging"
  type        = bool
  default     = true
}

variable "allow_auto_merge" {
  description = "Allow auto-merge on pull requests"
  type        = bool
  default     = false
}

variable "squash_merge_commit_title" {
  description = "Default commit title for squash merges"
  type        = string
  default     = "COMMIT_OR_PR_TITLE"
}

variable "squash_merge_commit_message" {
  description = "Default commit message for squash merges"
  type        = string
  default     = "COMMIT_MESSAGES"
}

# Branch Protection Variables
variable "enable_branch_protection" {
  description = "Whether to enable branch protection rules for the default branch"
  type        = bool
  default     = false
}

variable "protected_branch" {
  description = "Branch to protect (defaults to repository default branch)"
  type        = string
  default     = null
}

variable "enforce_admins" {
  description = "Enforce branch protection for repository administrators"
  type        = bool
  default     = false
}

variable "required_status_checks" {
  description = "List of required status checks for branch protection"
  type        = list(string)
  default     = []
}

variable "strict_status_checks" {
  description = "Require branches to be up to date before merging"
  type        = bool
  default     = true
}

variable "require_code_owner_reviews" {
  description = "Require code owner reviews for branch protection"
  type        = bool
  default     = false
}

variable "required_approving_review_count" {
  description = "Number of required approving reviews"
  type        = number
  default     = 1
  
  validation {
    condition     = var.required_approving_review_count >= 0 && var.required_approving_review_count <= 6
    error_message = "Required approving review count must be between 0 and 6."
  }
}

variable "dismiss_stale_reviews" {
  description = "Dismiss stale reviews when new commits are pushed"
  type        = bool
  default     = true
}

variable "restrict_dismissals" {
  description = "Restrict who can dismiss pull request reviews"
  type        = bool
  default     = false
}

variable "require_signed_commits" {
  description = "Require signed commits"
  type        = bool
  default     = false
}

variable "require_conversation_resolution" {
  description = "Require conversation resolution before merging"
  type        = bool
  default     = true
}

variable "allows_deletions" {
  description = "Allow deletions of the protected branch"
  type        = bool
  default     = false
}

variable "allows_force_pushes" {
  description = "Allow force pushes to the protected branch"
  type        = bool
  default     = false
}

variable "lock_branch" {
  description = "Lock the branch (read-only)"
  type        = bool
  default     = false
}

# Deploy Keys Variables
variable "deploy_keys" {
  description = "Map of deploy keys to create for the repository"
  type = map(object({
    title     = string
    key       = string
    read_only = optional(bool, true)
  }))
  default = {}
}

# Repository Files Variables
variable "repository_files" {
  description = "Map of files to create in the repository"
  type = map(object({
    content             = string
    branch              = optional(string, "main")
    commit_message      = optional(string, "Add file via Terraform")
    commit_author       = optional(string)
    commit_email        = optional(string)
    overwrite_on_create = optional(bool, false)
  }))
  default = {}
}

variable "amplify_webhook_url" {
  description = "AWS Amplify webhook URL for automated deployments"
  type        = string
  default     = ""
  sensitive   = true
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

variable "github_token" {
  description = "GitHub personal access token (alternative to GitHub App)"
  type        = string
  default     = ""
  sensitive   = true
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
