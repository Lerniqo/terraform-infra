# Variables for the App Runner module

variable "service_name" {
  description = "Name of the App Runner service"
  type        = string
}

variable "repository_url" {
  description = "GitHub repository URL for the application"
  type        = string
}

variable "branch_name" {
  description = "Git branch to deploy from"
  type        = string
  default     = "main"
}

variable "runtime" {
  description = "Runtime for the application (e.g., NODEJS_18)"
  type        = string
  default     = "NODEJS_18"
}

variable "build_command" {
  description = "Command to build the application"
  type        = string
  default     = "npm install"
}

variable "start_command" {
  description = "Command to start the application"
  type        = string
  default     = "npm start"
}

variable "environment_variables" {
  description = "Environment variables for the application"
  type        = map(string)
  default     = {}
}

variable "environment_secrets" {
  description = "Environment secrets for the application (from AWS Systems Manager Parameter Store)"
  type        = map(string)
  default     = {}
}

variable "auto_deployments_enabled" {
  description = "Enable automatic deployments from repository"
  type        = bool
  default     = true
}

variable "cpu" {
  description = "CPU allocation for the service (0.25 vCPU for Free Tier)"
  type        = string
  default     = "0.25 vCPU"
}

variable "memory" {
  description = "Memory allocation for the service (0.5 GB for Free Tier)"
  type        = string
  default     = "0.5 GB"
}

variable "instance_role_arn" {
  description = "IAM role ARN for the App Runner instance (optional)"
  type        = string
  default     = null
}

variable "health_check_path" {
  description = "Path for health check"
  type        = string
  default     = "/"
}

variable "is_publicly_accessible" {
  description = "Whether the App Runner service is publicly accessible"
  type        = bool
  default     = true
}

variable "create_vpc_connector" {
  description = "Whether to create a VPC connector for private resources"
  type        = bool
  default     = false
}

variable "vpc_subnet_ids" {
  description = "List of VPC subnet IDs for the VPC connector"
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs for the VPC connector"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to the App Runner service"
  type        = map(string)
  default     = {}
}
