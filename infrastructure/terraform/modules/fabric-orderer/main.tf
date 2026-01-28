# Fabric Orderer Module
#
# Cloud-agnostic module for deploying a Hyperledger Fabric Raft orderer node.
# The ordering service should be distributed across clouds for resilience.
#
# Usage:
#   module "orderer1" {
#     source = "../modules/fabric-orderer"
#
#     orderer_name = "orderer1"
#     orderer_id   = 1
#     msp_id       = "OrdererMSP"
#
#     raft_cluster_members = [
#       "orderer1.example.com:7050",
#       "orderer2.example.com:7050",
#       "orderer3.example.com:7050",
#       "orderer4.example.com:7050",
#       "orderer5.example.com:7050",
#     ]
#
#     kubernetes_namespace = "fabric-orderer"
#     storage_class        = "standard-rwo"
#   }

terraform {
  required_version = ">= 1.5.0"
}

variable "orderer_name" {
  description = "Orderer node name (e.g., orderer1, orderer2)"
  type        = string
}

variable "orderer_id" {
  description = "Orderer node ID in the Raft cluster (1-5)"
  type        = number
  validation {
    condition     = var.orderer_id >= 1 && var.orderer_id <= 5
    error_message = "Orderer ID must be between 1 and 5."
  }
}

variable "msp_id" {
  description = "MSP identifier for the orderer organization"
  type        = string
  default     = "OrdererMSP"
}

variable "raft_cluster_members" {
  description = "List of all Raft cluster member endpoints"
  type        = list(string)
  validation {
    condition     = length(var.raft_cluster_members) >= 3
    error_message = "Raft cluster requires at least 3 members for fault tolerance."
  }
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for orderer deployment"
  type        = string
}

variable "storage_class" {
  description = "Kubernetes storage class for persistent volumes"
  type        = string
}

variable "orderer_resources" {
  description = "Resource requests/limits for orderer container"
  type = object({
    requests_cpu    = string
    requests_memory = string
    limits_cpu      = string
    limits_memory   = string
  })
  default = {
    requests_cpu    = "250m"
    requests_memory = "256Mi"
    limits_cpu      = "500m"
    limits_memory   = "512Mi"
  }
}

# Raft configuration
variable "raft_tick_interval" {
  description = "Raft tick interval in milliseconds"
  type        = string
  default     = "500ms"
}

variable "raft_election_tick" {
  description = "Number of ticks before triggering leader election"
  type        = number
  default     = 10
}

variable "raft_heartbeat_tick" {
  description = "Number of ticks between heartbeats"
  type        = number
  default     = 1
}

# Outputs
output "orderer_endpoint" {
  description = "Orderer gRPC endpoint"
  value       = "${var.orderer_name}.example.com:7050"
}

output "orderer_fqdn" {
  description = "Orderer fully qualified domain name"
  value       = "${var.orderer_name}.example.com"
}

output "is_leader_eligible" {
  description = "Whether this orderer can become Raft leader"
  value       = true
}
