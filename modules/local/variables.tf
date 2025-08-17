variable "project" {
  type        = string
  description = "Project name for resource naming"
}

variable "ports" {
  type = object({
    external = number
    internal = number
  })
  description = "Kafka port configuration"
}
