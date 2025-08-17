variable "project" {
  type        = string
  description = "Project name for resource naming and tagging"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prod)"
}

variable "aws_region" {
  type        = string
  description = "AWS region for deployment"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for public subnet"
}

variable "kafka_version" {
  type        = string
  description = "Kafka version for Docker containers"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "root_volume_size" {
  type        = number
  description = "Root EBS volume size in GiB"
}

variable "ssh_key_name" {
  type        = string
  description = "Name of the AWS key pair for SSH access"
  default     = null
}

variable "trusted_cidr_blocks" {
  type        = list(string)
  description = "List of trusted CIDR blocks for SSH and Kafka access"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
  default     = {}
}
