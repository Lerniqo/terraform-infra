# API Gateway Module
# Creates HTTP API Gateway with VPC Link integration to private ECS services

# HTTP API Gateway
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-${var.environment}-api"
  description   = "API Gateway for ${var.project_name} microservices"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers     = ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key", "X-Amz-Security-Token"]
    max_age           = 300
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-api"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# VPC Link for private integration with ALB (using v2 for HTTP API)
resource "aws_apigatewayv2_vpc_link" "main" {
  name               = "${var.project_name}-${var.environment}-vpc-link"
  subnet_ids         = var.private_subnets
  security_group_ids = [var.security_group_id]

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc-link"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Create integrations for each microservice - root routes
resource "aws_apigatewayv2_integration" "service_integration_root" {
  for_each = var.services

  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "HTTP_PROXY"
  integration_uri  = var.alb_listener_arn

  integration_method      = "ANY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_apigatewayv2_vpc_link.main.id
  timeout_milliseconds    = 30000

  request_parameters = {
    "overwrite:header.Host" = each.value.host
    "overwrite:path"        = "/"
  }
}

# Create integrations for each microservice - proxy routes
resource "aws_apigatewayv2_integration" "service_integration_proxy" {
  for_each = var.services

  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "HTTP_PROXY"
  integration_uri  = var.alb_listener_arn

  integration_method      = "ANY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_apigatewayv2_vpc_link.main.id
  timeout_milliseconds    = 30000

  request_parameters = {
    "overwrite:header.Host" = each.value.host
    "overwrite:path"        = "/$request.path.proxy"
  }
}

# Create routes for each service - root level
resource "aws_apigatewayv2_route" "service_route_root" {
  for_each = var.services

  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /${each.key}"
  target    = "integrations/${aws_apigatewayv2_integration.service_integration_root[each.key].id}"
}

# Create routes for each service - with paths
resource "aws_apigatewayv2_route" "service_route_paths" {
  for_each = var.services

  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /${each.key}/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.service_integration_proxy[each.key].id}"
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = var.environment
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip            = "$context.identity.sourceIp"
      requestTime   = "$context.requestTime"
      httpMethod    = "$context.httpMethod"
      routeKey      = "$context.routeKey"
      status        = "$context.status"
      protocol      = "$context.protocol"
      responseLength = "$context.responseLength"
      error = {
        message      = "$context.error.message"
        messageString = "$context.error.messageString"
      }
      integration = {
        error             = "$context.integration.error"
        integrationStatus = "$context.integration.integrationStatus"
        latency          = "$context.integration.latency"
        requestId        = "$context.integration.requestId"
        status           = "$context.integration.status"
      }
    })
  }

  default_route_settings {
    throttling_rate_limit  = var.api_rate_limit
    throttling_burst_limit = var.api_burst_limit
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-stage"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# CloudWatch Log Group for API Gateway logs
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-${var.environment}-api-logs"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
