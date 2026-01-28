# Fabric CA Module
#
# Cloud-agnostic module for deploying a Hyperledger Fabric Certificate Authority.
# Each organization operates its own CA for identity management.
#
# Usage:
#   module "org1_ca" {
#     source = "../modules/fabric-ca"
#
#     org_name = "org1"
#     msp_id   = "Org1MSP"
#
#     ca_admin_user     = var.ca_admin_user
#     ca_admin_password = var.ca_admin_password
#
#     kubernetes_namespace = "fabric-org1"
#     storage_class        = "standard-rwo"
#   }

terraform {
  required_version = ">= 1.5.0"
}

variable "org_name" {
  description = "Organization name (e.g., org1, tca, bata)"
  type        = string
}

variable "msp_id" {
  description = "MSP identifier (e.g., Org1MSP)"
  type        = string
}

variable "ca_admin_user" {
  description = "CA admin username"
  type        = string
  sensitive   = true
}

variable "ca_admin_password" {
  description = "CA admin password (must be at least 16 characters)"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.ca_admin_password) >= 16
    error_message = "CA admin password must be at least 16 characters."
  }
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for CA deployment"
  type        = string
}

variable "storage_class" {
  description = "Kubernetes storage class for persistent volumes"
  type        = string
}

variable "ca_resources" {
  description = "Resource requests/limits for CA container"
  type = object({
    requests_cpu    = string
    requests_memory = string
    limits_cpu      = string
    limits_memory   = string
  })
  default = {
    requests_cpu    = "100m"
    requests_memory = "128Mi"
    limits_cpu      = "250m"
    limits_memory   = "256Mi"
  }
}

# TLS configuration
variable "tls_enabled" {
  description = "Enable TLS for CA server"
  type        = bool
  default     = true
}

# CA server configuration
variable "ca_debug" {
  description = "Enable CA debug logging"
  type        = bool
  default     = false
}

variable "ca_db_type" {
  description = "Database type for CA (sqlite3, postgres, mysql)"
  type        = string
  default     = "sqlite3"
}

# CSR configuration
variable "csr_cn" {
  description = "Common Name for CA certificate"
  type        = string
  default     = ""
}

variable "csr_names" {
  description = "CSR subject names"
  type = object({
    country  = string
    state    = string
    locality = string
    org      = string
    ou       = string
  })
  default = {
    country  = "US"
    state    = "California"
    locality = "San Francisco"
    org      = "Tolling Network"
    ou       = ""
  }
}

# Outputs
output "ca_endpoint" {
  description = "CA server endpoint"
  value       = "ca.${var.org_name}.example.com:7054"
}

output "ca_fqdn" {
  description = "CA fully qualified domain name"
  value       = "ca.${var.org_name}.example.com"
}

output "ca_name" {
  description = "CA name for client configuration"
  value       = "ca-${var.org_name}"
}
