# Fabric Peer Module
#
# Cloud-agnostic module for deploying a Hyperledger Fabric peer.
# This module is designed to work with Bevel operator on any Kubernetes cluster.
#
# Usage:
#   module "org1_peer" {
#     source = "../modules/fabric-peer"
#
#     org_name     = "org1"
#     peer_name    = "peer0"
#     msp_id       = "Org1MSP"
#     channel_name = "interop"
#
#     kubernetes_namespace = "fabric-org1"
#     storage_class        = "standard-rwo"  # Cloud-specific
#
#     couchdb_user     = var.couchdb_user
#     couchdb_password = var.couchdb_password
#   }

terraform {
  required_version = ">= 1.5.0"
}

variable "org_name" {
  description = "Organization name (e.g., org1, tca, bata)"
  type        = string
}

variable "peer_name" {
  description = "Peer name (e.g., peer0, peer1)"
  type        = string
}

variable "msp_id" {
  description = "MSP identifier (e.g., Org1MSP)"
  type        = string
}

variable "channel_name" {
  description = "Initial channel to join"
  type        = string
  default     = "interop"
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for peer deployment"
  type        = string
}

variable "storage_class" {
  description = "Kubernetes storage class for persistent volumes"
  type        = string
}

variable "couchdb_user" {
  description = "CouchDB admin username"
  type        = string
  sensitive   = true
}

variable "couchdb_password" {
  description = "CouchDB admin password"
  type        = string
  sensitive   = true
}

variable "peer_resources" {
  description = "Resource requests/limits for peer container"
  type = object({
    requests_cpu    = string
    requests_memory = string
    limits_cpu      = string
    limits_memory   = string
  })
  default = {
    requests_cpu    = "500m"
    requests_memory = "512Mi"
    limits_cpu      = "1000m"
    limits_memory   = "1Gi"
  }
}

variable "couchdb_resources" {
  description = "Resource requests/limits for CouchDB container"
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

# Outputs will be populated when Kubernetes resources are added
output "peer_endpoint" {
  description = "Peer gRPC endpoint"
  value       = "${var.peer_name}.${var.org_name}.example.com:7051"
}

output "peer_fqdn" {
  description = "Peer fully qualified domain name"
  value       = "${var.peer_name}.${var.org_name}.example.com"
}
