# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "disabled"
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
  cpu                      = "128"
  memory                   = "256"
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
        },
        {
          name  = "INTERNAL_ALB_DNS"
          value = var.alb_dns_name
        },
        {
          name  = "SERVICE_DISCOVERY_URL"
          value = "http://${var.alb_dns_name}"
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
          "netstat -an | grep ${each.value.port} | grep LISTEN > /dev/null; if [ $? -eq 0 ]; then exit 0; else exit 1; fi"
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

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight           = 100
  }

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

# Auto-scaling for ECS services
resource "aws_appautoscaling_target" "ecs_target" {
  for_each = var.apps

  max_capacity       = 2
  min_capacity       = 0
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app_service[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy" {
  for_each = var.apps

  name               = "${each.key}-scale-down"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 30.0
  }
}

# Data source for current AWS region
data "aws_region" "current" {}

# Data source for reading secrets from AWS Secrets Manager
data "aws_secretsmanager_secret_version" "app_secrets" {
  for_each = var.secrets_arns

  secret_id = each.value
}
