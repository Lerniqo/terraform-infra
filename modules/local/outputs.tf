output "network_name" {
  description = "Docker network name"
  value       = docker_network.kafka_network.name
}

output "kafka_bootstrap_servers" {
  description = "Kafka bootstrap servers for external clients"
  value       = "localhost:${var.ports.external}"
}

output "kafka_external_host" {
  description = "Kafka external host"
  value       = "localhost"
}

output "kafka_external_port" {
  description = "Kafka external port"
  value       = var.ports.external
}

output "kafka_internal_host" {
  description = "Kafka internal host for container communication"
  value       = "kafka"
}

output "kafka_internal_port" {
  description = "Kafka internal port"
  value       = var.ports.internal
}
