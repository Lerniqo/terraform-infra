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

# Amplify Outputs
output "amplify_app_id" {
  description = "ID of the Amplify app"
  value       = length(module.amplify) > 0 ? module.amplify[0].app_id : ""
}

output "amplify_app_url" {
  description = "URL of the deployed Amplify application"
  value       = length(module.amplify) > 0 ? module.amplify[0].app_url : ""
}

output "amplify_default_domain" {
  description = "Default domain for the Amplify app"
  value       = length(module.amplify) > 0 ? module.amplify[0].default_domain : ""
}

output "amplify_custom_domain_url" {
  description = "Custom domain URL (if configured)"
  value       = length(module.amplify) > 0 ? module.amplify[0].custom_domain_url : ""
}

output "amplify_webhook_url" {
  description = "Amplify webhook URL for GitHub integration"
  value       = length(module.amplify) > 0 ? module.amplify[0].webhook_url : ""
  sensitive   = true
}

# GitHub Repository Outputs
# output "github_repository_url" {
#   description = "URL of the GitHub repository"
#   value       = module.github_frontend.repository_url
# }

# output "github_repository_clone_url" {
#   description = "HTTPS clone URL for the GitHub repository"
#   value       = module.github_frontend.repository_https_clone_url
# }

output "github_access_token" {
  description = "GitHub access token (from GitHub App or personal token)"
  value       = "Using personal access token"
  sensitive   = true
}

output "api_endpoints" {
  description = "API endpoints for each microservice"
  value = {
    "user-service"     = "${module.apigateway.api_gateway_url}/api/user-service"
    "progress-service" = "${module.apigateway.api_gateway_url}/api/progress-service"
    "content-service"  = "${module.apigateway.api_gateway_url}/api/content-service"
    "ai-service"       = "${module.apigateway.api_gateway_url}/api/ai-service"
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

# S3 Bucket Outputs
output "s3_bucket_ids" {
  description = "Map of S3 bucket names to their IDs"
  value       = length(module.s3) > 0 ? module.s3[0].bucket_ids : {}
}

output "s3_bucket_arns" {
  description = "Map of S3 bucket names to their ARNs"
  value       = length(module.s3) > 0 ? module.s3[0].bucket_arns : {}
}

output "s3_bucket_domain_names" {
  description = "Map of S3 bucket names to their domain names"
  value       = length(module.s3) > 0 ? module.s3[0].bucket_domain_names : {}
}

output "s3_bucket_regional_domain_names" {
  description = "Map of S3 bucket names to their regional domain names"
  value       = length(module.s3) > 0 ? module.s3[0].bucket_regional_domain_names : {}
}

output "s3_bucket_names" {
  description = "Map of S3 bucket names to their actual names"
  value       = length(module.s3) > 0 ? module.s3[0].bucket_names : {}
}

output "s3_buckets_info" {
  description = "Comprehensive information about created S3 buckets"
  value = length(module.s3) > 0 ? {
    for bucket_key, bucket_name in module.s3[0].bucket_names : bucket_key => {
      name                    = bucket_name
      id                      = module.s3[0].bucket_ids[bucket_key]
      arn                     = module.s3[0].bucket_arns[bucket_key]
      domain_name             = module.s3[0].bucket_domain_names[bucket_key]
      regional_domain_name    = module.s3[0].bucket_regional_domain_names[bucket_key]
      region                  = var.aws_region
      environment             = var.environment
    }
  } : {}
}
