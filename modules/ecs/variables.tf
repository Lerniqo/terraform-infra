variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "apps" {
  description = "Map of applications with their configuration"
  type = map(object({
    image             = string
    port              = number
    public            = bool
    environment_vars  = optional(map(string), {})
    secrets          = optional(map(string), {})
  }))
}

variable "subnets" {
  description = "List of subnet IDs for ECS services"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for ECS services"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "secrets_arns" {
  description = "Map of AWS Secrets Manager secret ARNs keyed by app name"
  type        = map(string)
  default     = {}
}

variable "parameter_arns" {
  description = "Map of AWS Systems Manager Parameter Store parameter ARNs keyed by app name"
  type        = map(string)
  default     = {}
}

variable "target_group_arns" {
  description = "Map of ALB target group ARNs keyed by app name"
  type        = map(string)
  default     = {}
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer for inter-service communication"
  type        = string
  default     = ""
}
