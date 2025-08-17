# Local environment module (for dev)
module "local" {
  count   = var.environment == "dev" ? 1 : 0
  source  = "./modules/local"
  project = "${var.project_name}-${var.environment}"
  ports   = var.kafka_ports
}

# AWS environment module (for prod)
module "aws" {
  count               = var.environment == "prod" ? 1 : 0
  source              = "./modules/aws"
  project             = var.project_name
  environment         = var.environment
  aws_region          = var.aws_region
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  kafka_version       = var.kafka_version
  instance_type       = var.instance_type
  root_volume_size    = var.root_volume_size
  ssh_key_name        = var.ssh_key_name
  trusted_cidr_blocks = var.trusted_cidr_blocks
  common_tags = merge(var.common_tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}
