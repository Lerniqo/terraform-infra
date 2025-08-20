# API Gateway Module Variables

variable "security_group_id" {
  description = "Security group ID for the VPC Link"
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener for VPC Link integration"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "services" {
  description = "Map of services to expose through API Gateway"
  type = map(object({
    auth_required = bool
    description   = string
    host         = string
  }))
  default = {}
}

variable "private_subnets" {
  description = "List of private subnet IDs for VPC Link"
  type        = list(string)
}

variable "domain_name" {
  description = "Domain name for the services"
  type        = string
  default     = ""
}

variable "enable_auth" {
  description = "Enable Cognito authentication"
  type        = bool
  default     = false
}

variable "cognito_user_pool_arn" {
  description = "ARN of the Cognito User Pool for authentication"
  type        = string
  default     = ""
}

variable "authorizer_role_arn" {
  description = "ARN of the IAM role for API Gateway authorizer"
  type        = string
  default     = ""
}

variable "api_quota_limit" {
  description = "API quota limit per day"
  type        = number
  default     = 10000
}

variable "api_rate_limit" {
  description = "API rate limit (requests per second)"
  type        = number
  default     = 100
}

variable "api_burst_limit" {
  description = "API burst limit"
  type        = number
  default     = 200
}
