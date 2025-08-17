variable "project_name" {
  type        = string
  description = "Project/stack name used for tagging and naming."
  default     = "kafka-local"
}

variable "docker_host" {
  type        = string
  description = "Docker host for local development"
  default     = "unix:///var/run/docker.sock"
}

variable "kafka_ports" {
  type = object({
    external = number
    internal = number
  })
  description = "Kafka port configuration"
  default = {
    external = 9094
    internal = 9092
  }
}
