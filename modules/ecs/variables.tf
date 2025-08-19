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
    image  = string
    port   = number
    public = bool
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
