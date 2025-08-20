# Application Load Balancer Module
# Creates ALB with target groups for ECS services

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnets

  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Target Groups for each application
resource "aws_lb_target_group" "app_tg" {
  for_each = var.apps

  name     = substr("${var.environment}-${each.key}-tg", 0, 32)
  port     = each.value.port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-${each.key}-tg"
    Environment = var.environment
    Application = each.key
    ManagedBy   = "Terraform"
  }
}

# HTTP Listener (will redirect to HTTPS in production)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  # Default action - can be customized per requirement
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Service not found"
      status_code  = "404"
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-http-listener"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Listener Rules for different applications based on Host header
resource "aws_lb_listener_rule" "app_rules" {
  for_each = var.apps

  listener_arn = aws_lb_listener.http.arn
  priority     = 100 + index(keys(var.apps), each.key)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg[each.key].arn
  }

  condition {
    host_header {
      values = var.domain_name != "" ? ["${each.key}.${var.domain_name}"] : ["${each.key}.${aws_lb.main.dns_name}"]
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-${each.key}-rule"
    Environment = var.environment
    Application = each.key
    ManagedBy   = "Terraform"
  }
}
