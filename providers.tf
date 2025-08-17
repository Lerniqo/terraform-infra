# Provider configuration for local Docker-based Kafka infrastructure

provider "docker" {
  host = var.docker_host
}
