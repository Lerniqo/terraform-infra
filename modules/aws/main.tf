# Data source for the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-igw"
  })
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-public-subnet"
  })
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-public-rt"
  })
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group for Kafka
resource "aws_security_group" "kafka" {
  name_prefix = "${var.project}-${var.environment}-kafka-"
  vpc_id      = aws_vpc.main.id

  # SSH access from trusted IPs only
  dynamic "ingress" {
    for_each = var.trusted_cidr_blocks
    content {
      description = "SSH from trusted networks"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # Kafka external listener from trusted IPs only
  dynamic "ingress" {
    for_each = var.trusted_cidr_blocks
    content {
      description = "Kafka external from trusted networks"
      from_port   = 9094
      to_port     = 9094
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-kafka-sg"
  })
}

# IAM Role for EC2 instance (for CloudWatch and SSM)
resource "aws_iam_role" "kafka_instance_role" {
  name = "${var.project}-${var.environment}-kafka-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "kafka_instance_profile" {
  name = "${var.project}-${var.environment}-kafka-instance-profile"
  role = aws_iam_role.kafka_instance_role.name

  tags = var.common_tags
}

# Attach SSM managed instance core policy
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.kafka_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch agent policy
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy" {
  role       = aws_iam_role.kafka_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# User Data script for EC2 instance
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    kafka_version = var.kafka_version
    project       = var.project
    environment   = var.environment
  }))
}

# EC2 Instance for Kafka
resource "aws_instance" "kafka" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.kafka.id]
  subnet_id              = aws_subnet.public.id
  iam_instance_profile   = aws_iam_instance_profile.kafka_instance_profile.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = merge(var.common_tags, {
      Name = "${var.project}-${var.environment}-kafka-root-volume"
    })
  }

  user_data                   = local.user_data
  user_data_replace_on_change = true

  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-kafka-instance"
  })

  lifecycle {
    create_before_destroy = true
  }
}
