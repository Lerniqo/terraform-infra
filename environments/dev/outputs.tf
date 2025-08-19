# Outputs for the development environment

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.networking.public_subnets
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.networking.security_group_id
}

output "ecr_repository_urls" {
  description = "Map of ECR repository URLs"
  value       = module.ecr.repository_urls
}

output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs.cluster_id
}

output "ecs_service_arns" {
  description = "Map of ECS service ARNs"
  value       = module.ecs.service_arns
}

output "execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = module.iam.execution_role_arn
}

output "task_role_arn" {
  description = "ARN of the ECS task role"
  value       = module.iam.task_role_arn
}

# Instructions for getting public IPs
output "note_public_ips" {
  description = "Note about getting public IPs of running tasks"
  value = "To get public IPs of running ECS tasks, use: aws ecs list-tasks --cluster ${module.ecs.cluster_id} --query 'taskArns[*]' --output table && aws ecs describe-tasks --cluster ${module.ecs.cluster_id} --tasks <task-arn> --query 'tasks[*].attachments[*].details[?name==`networkInterfaceId`].value' --output table"
}
