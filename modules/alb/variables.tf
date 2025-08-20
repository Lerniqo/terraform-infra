variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB will be created"
  type        = string
}

variable "subnets" {
  description = "List of subnet IDs for the ALB"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "domain_name" {
  description = "Base domain name for the applications"
  type        = string
  default     = ""
}

variable "apps" {
  description = "Map of applications with their configurations"
  type = map(object({
    port   = number
    public = bool
  }))
}

variable "default_app" {
  description = "Default application to route traffic to"
  type        = string
  default     = "user-service"
}
