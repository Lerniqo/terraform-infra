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
    image = string
    port  = number
  }))
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}
