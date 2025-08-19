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

      environment = [
        {
          name  = "NODE_ENV"
          value = var.environment
        },
        {
          name  = "PORT"
          value = tostring(each.value.port)
        }
      ]
    }
  ])

  tags = {
    Name        = "${var.cluster_name}-${each.key}-task"
    Environment = var.environment
    ManagedBy   = "Terraform"
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
    assign_public_ip = true
  }

  depends_on = [aws_ecs_task_definition.app_task]

  tags = {
    Name        = "${var.cluster_name}-${each.key}-service"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Data source for current AWS region
data "aws_region" "current" {}
