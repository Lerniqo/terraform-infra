variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ECS tasks are running"
  type        = string
}

variable "apps_requiring_eip" {
  description = "Map of applications that need Elastic IPs"
  type        = map(object({
    service_name = string
  }))
  default = {}
}
