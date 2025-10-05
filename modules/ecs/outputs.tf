output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "service_arns" {
  description = "Map of ECS service ARNs"
  value = {
    for name, service in aws_ecs_service.app_service : name => service.id
  }
}

output "task_definition_arns" {
  description = "Map of ECS task definition ARNs"
  value = {
    for name, task in aws_ecs_task_definition.app_task : name => task.arn
  }
}

# Note: ECS Fargate tasks get dynamic public IPs assigned when they start
# To get the actual public IPs, you would need to query the ECS service
# or use a data source after the tasks are running
output "service_info" {
  description = "Information about ECS services"
  value = {
    for name, service in aws_ecs_service.app_service : name => {
      arn           = service.id
      desired_count = service.desired_count
      launch_type   = service.launch_type
    }
  }
}

output "cloudwatch_log_groups" {
  description = "Map of CloudWatch log group names for ECS services"
  value = {
    for name, log_group in aws_cloudwatch_log_group.ecs_log_group : name => log_group.name
  }
}

output "cloudwatch_log_group_arns" {
  description = "Map of CloudWatch log group ARNs for ECS services"
  value = {
    for name, log_group in aws_cloudwatch_log_group.ecs_log_group : name => log_group.arn
  }
}
