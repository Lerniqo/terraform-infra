# AWS App Runner Service Module
# This module creates an App Runner service with configurable options

# App Runner Service
resource "aws_apprunner_service" "app" {
  service_name = var.service_name

  source_configuration {
    # GitHub repository configuration
    code_repository {
      repository_url = var.repository_url
      
      source_code_version {
        type  = "BRANCH"
        value = var.branch_name
      }
      
      code_configuration {
        configuration_source = "API"
        
        code_configuration_values {
          runtime                = var.runtime
          build_command          = var.build_command
          start_command          = var.start_command
          runtime_environment_variables = var.environment_variables
          runtime_environment_secrets   = var.environment_secrets
        }
      }
    }
    
    # Auto deployments enabled
    auto_deployments_enabled = var.auto_deployments_enabled
  }

  # Instance configuration for AWS Free Tier
  instance_configuration {
    cpu               = var.cpu
    memory            = var.memory
    instance_role_arn = var.instance_role_arn
  }

  # Health check configuration
  health_check_configuration {
    protocol            = "HTTP"
    path                = var.health_check_path
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 5
  }

  # Network configuration
  network_configuration {
    ingress_configuration {
      is_publicly_accessible = var.is_publicly_accessible
    }
  }

  tags = var.tags
}

# App Runner VPC Connector (optional, for private resources)
resource "aws_apprunner_vpc_connector" "connector" {
  count = var.create_vpc_connector ? 1 : 0
  
  vpc_connector_name = "${var.service_name}-vpc-connector"
  subnets           = var.vpc_subnet_ids
  security_groups   = var.vpc_security_group_ids
  
  tags = var.tags
}
