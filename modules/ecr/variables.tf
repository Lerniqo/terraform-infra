variable "app_names" {
  description = "List of application names for ECR repositories"
  type        = list(string)
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}
