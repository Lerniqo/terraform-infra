# Variables for the development environment

variable "github_repository_url" {
  description = "GitHub repository URL for the Node.js application"
  type        = string
  # Example: "https://github.com/yourusername/your-nodejs-app"
}

variable "github_branch" {
  description = "GitHub branch to deploy from"
  type        = string
  default     = "main"
}

variable "health_check_path" {
  description = "Health check endpoint path"
  type        = string
  default     = "/health"
}

variable "auto_deployments_enabled" {
  description = "Enable automatic deployments when code is pushed to the branch"
  type        = bool
  default     = true
}
