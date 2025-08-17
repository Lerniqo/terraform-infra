variable "environment" {
  type        = string
  description = "Environment name (dev, prod)"
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

variable "project_name" {
  type        = string
  description = "Project/stack name used for tagging and naming."
  default     = "kafka"
}

variable "docker_host" {
  type        = string
  description = "Docker host for local development"
  default     = "unix:///var/run/docker.sock"
}

variable "kafka_ports" {
  type = object({
    external = number
    internal = number
  })
  description = "Kafka port configuration"
  default = {
    external = 9094
    internal = 9092
  }
}

# AWS-specific variables
variable "aws_region" {
  type        = string
  description = "AWS region for prod environment"
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC in prod environment"
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for public subnet"
  default     = "10.10.1.0/24"
}

variable "kafka_version" {
  type        = string
  description = "Kafka version for Docker containers"
  default     = "3.7.0"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for Kafka"
  default     = "t3.medium"
}

variable "root_volume_size" {
  type        = number
  description = "Root EBS volume size in GiB"
  default     = 50
}

variable "ssh_key_name" {
  type        = string
  description = "Name of the AWS key pair for SSH access"
  default     = null
}

variable "trusted_cidr_blocks" {
  type        = list(string)
  description = "List of trusted CIDR blocks for SSH and Kafka access"
  default     = ["203.0.113.0/24", "198.51.100.25/32"]
}

variable "aws_access_key" {
  type        = string
  description = "AWS access key for prod environment"
  default     = ""
  sensitive   = true
}

variable "aws_secret_key" {
  type        = string
  description = "AWS secret key for prod environment"
  default     = ""
  sensitive   = true
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
  default     = {}
}
