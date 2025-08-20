variable "app_names" {
  description = "List of application names for ECR repositories"
  type        = list(string)
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "app_secrets" {
  description = "Map of application secrets stored in AWS Secrets Manager"
  type = map(map(string))
  default = null
}

variable "app_env_vars" {
  description = "Map of application environment variables stored in AWS Systems Manager Parameter Store"
  type = map(map(string))
  default = null
}
