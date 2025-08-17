output "kafka_bootstrap_servers" {
  description = "Kafka bootstrap servers for local development"
  value       = module.local.kafka_bootstrap_servers
}

output "kafka_external_host" {
  description = "Kafka external host"
  value       = module.local.kafka_external_host
}

output "kafka_external_port" {
  description = "Kafka external port"
  value       = module.local.kafka_external_port
}

output "kafka_internal_host" {
  description = "Kafka internal host (for container-to-container communication)"
  value       = module.local.kafka_internal_host
}

output "kafka_internal_port" {
  description = "Kafka internal port"
  value       = module.local.kafka_internal_port
}
