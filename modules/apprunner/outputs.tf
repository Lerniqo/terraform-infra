# Outputs for the App Runner module

output "service_arn" {
  description = "ARN of the App Runner service"
  value       = aws_apprunner_service.app.arn
}

output "service_id" {
  description = "ID of the App Runner service"
  value       = aws_apprunner_service.app.service_id
}

output "service_url" {
  description = "Default domain of the App Runner service"
  value       = aws_apprunner_service.app.service_url
}

output "service_status" {
  description = "Current status of the App Runner service"
  value       = aws_apprunner_service.app.status
}

output "vpc_connector_arn" {
  description = "ARN of the VPC connector (if created)"
  value       = var.create_vpc_connector ? aws_apprunner_vpc_connector.connector[0].arn : null
}
