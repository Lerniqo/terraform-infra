# Elastic IP Module for stable public IP addresses
# This module creates Elastic IPs that can be associated with ECS tasks

resource "aws_eip" "app_eip" {
  for_each = var.apps_requiring_eip
  
  domain = "vpc"
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-${each.key}-eip"
    Environment = var.environment
    Application = each.key
    ManagedBy   = "Terraform"
  }
}

# Data source to get network interface of running ECS tasks
data "aws_network_interfaces" "ecs_enis" {
  for_each = var.apps_requiring_eip
  
  filter {
    name   = "description"
    values = ["*${each.key}*"]
  }
  
  filter {
    name   = "status"
    values = ["in-use"]
  }
  
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# Associate Elastic IP with ECS task network interface
resource "aws_eip_association" "app_eip_assoc" {
  for_each = var.apps_requiring_eip
  
  allocation_id        = aws_eip.app_eip[each.key].id
  network_interface_id = length(data.aws_network_interfaces.ecs_enis[each.key].ids) > 0 ? data.aws_network_interfaces.ecs_enis[each.key].ids[0] : null
  
  # This ensures we don't try to associate if no ENI is found
  count = length(data.aws_network_interfaces.ecs_enis[each.key].ids) > 0 ? 1 : 0
}
