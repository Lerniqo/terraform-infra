# Outputs for the development environment

output "app_runner_service_url" {
  description = "URL of the deployed Node.js application"
  value       = module.nodejs_app.service_url
}

output "app_runner_service_arn" {
  description = "ARN of the App Runner service"
  value       = module.nodejs_app.service_arn
}

output "app_runner_service_status" {
  description = "Current status of the App Runner service"
  value       = module.nodejs_app.service_status
}
