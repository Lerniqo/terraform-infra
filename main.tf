module "local" {
  source  = "./modules/local"
  project = var.project_name
  ports   = var.kafka_ports
}
