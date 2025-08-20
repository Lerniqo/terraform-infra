# Outputs for the development environment

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.networking.public_subnets
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.networking.private_subnets
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

# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.alb.alb_zone_id
}

output "execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = module.iam.execution_role_arn
}

output "task_role_arn" {
  description = "ARN of the ECS task role"
  value       = module.iam.task_role_arn
}

# API Gateway Outputs
output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = module.apigateway.api_gateway_url
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = module.apigateway.api_gateway_id
}

output "api_endpoints" {
  description = "API endpoints for each microservice"
  value = {
    "user-service"     = "${module.apigateway.api_gateway_url}/user-service"
    "progress-service" = "${module.apigateway.api_gateway_url}/progress-service"
    "content-service"  = "${module.apigateway.api_gateway_url}/content-service"
    "ai-service"       = "${module.apigateway.api_gateway_url}/ai-service"
  }
}

# Instructions for getting public IPs
output "note_public_ips" {
  description = "Note about getting public IPs of running tasks"
  value = "To get public IPs of running ECS tasks, use: aws ecs list-tasks --cluster ${module.ecs.cluster_id} --query 'taskArns[*]' --output table && aws ecs describe-tasks --cluster ${module.ecs.cluster_id} --tasks <task-arn> --query 'tasks[*].attachments[*].details[?name==`networkInterfaceId`].value' --output table"
}

output "public_apps_info" {
  description = "Information about publicly accessible applications"
  value = {
    for app_name, app_config in var.apps : app_name => {
      port         = app_config.port
      public       = app_config.public
      service_arn  = module.ecs.service_arns[app_name]
      image        = local.apps_with_ecr_images[app_name].image
    }
    if app_config.public == true
  }
}

output "private_apps_info" {
  description = "Information about private applications"
  value = {
    for app_name, app_config in var.apps : app_name => {
      port         = app_config.port
      public       = app_config.public
      service_arn  = module.ecs.service_arns[app_name]
      image        = local.apps_with_ecr_images[app_name].image
    }
    if app_config.public == false
  }
}
