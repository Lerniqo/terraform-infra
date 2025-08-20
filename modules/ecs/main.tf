# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  for_each = var.apps

  name              = "/ecs/${var.cluster_name}/${each.key}"
  retention_in_days = 7

  tags = {
    Name        = "${var.cluster_name}-${each.key}-logs"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ECS Task Definitions
resource "aws_ecs_task_definition" "app_task" {
  for_each = var.apps

  family                   = "${var.cluster_name}-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn
  task_role_arn           = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = each.key
      image     = each.value.image
      essential = true
      
      portMappings = [
        {
          containerPort = each.value.port
          hostPort      = each.value.port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_log_group[each.key].name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }

      environment = concat([
        {
          name  = "NODE_ENV"
          value = var.environment
        },
        {
          name  = "PORT"
          value = tostring(each.value.port)
        },
        {
          name  = "APP_ENV"
          value = var.environment
        }
      ], [
        for key, value in each.value.environment_vars : {
          name  = key
          value = value
        }
      ])

      secrets = concat(
        # Secrets from AWS Secrets Manager
        contains(keys(var.secrets_arns), each.key) ? [
          for secret_key in keys(jsondecode(data.aws_secretsmanager_secret_version.app_secrets[each.key].secret_string)) : {
            name      = secret_key
            valueFrom = "${var.secrets_arns[each.key]}:${secret_key}::"
          }
        ] : [],
        # Individual secrets defined in app configuration
        [
          for key, value in each.value.secrets : {
            name      = key
            valueFrom = value
          }
        ]
      )

      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:${each.value.port}/health || exit 1"
        ]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.cluster_name}-${each.key}-task"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Application = each.key
  }
}

# ECS Services
resource "aws_ecs_service" "app_service" {
  for_each = var.apps

  name            = "${var.cluster_name}-${each.key}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app_task[each.key].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets
    security_groups  = [var.security_group_id]
    assign_public_ip = each.value.public
  }

  # Add load balancer configuration if target group ARN is provided
  dynamic "load_balancer" {
    for_each = contains(keys(var.target_group_arns), each.key) ? [1] : []
    content {
      target_group_arn = var.target_group_arns[each.key]
      container_name   = each.key
      container_port   = each.value.port
    }
  }

  depends_on = [aws_ecs_task_definition.app_task]

  tags = {
    Name        = "${var.cluster_name}-${each.key}-service"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Application = each.key
    Public      = tostring(each.value.public)
  }
}

# Data source for current AWS region
data "aws_region" "current" {}

# Data source for reading secrets from AWS Secrets Manager
data "aws_secretsmanager_secret_version" "app_secrets" {
  for_each = var.secrets_arns

  secret_id = each.value
}
