# Variables for the development environment

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ecs-multi-app"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "app_names" {
  description = "List of application names for ECR repositories"
  type        = list(string)
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

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "app_secrets" {
  description = "Map of application secrets stored in AWS Secrets Manager"
  type = map(map(string))
  default = {}
}

variable "app_env_vars" {
  description = "Map of application environment variables stored in AWS Systems Manager Parameter Store"
  type = map(map(string))
  default = {}
}

variable "domain_name" {
  description = "Base domain name for the applications (e.g., learniqo.linkpc.net)"
  type        = string
  default     = ""
}
