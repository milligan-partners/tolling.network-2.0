# GCP Infrastructure for Tolling.Network
#
# Deploys:
# - GKE cluster
# - Org1: 2 peers + 1 CA
# - Org4: 2 peers + 1 CA
# - 2 orderer nodes (part of 5-node Raft cluster)

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }

  # Uncomment for remote state
  # backend "gcs" {
  #   bucket = "tolling-network-terraform-state"
  #   prefix = "gcp"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-west1"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "tolling-network"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "node_count" {
  description = "Number of nodes per zone"
  type        = number
  default     = 1
}

variable "machine_type" {
  description = "GKE node machine type"
  type        = string
  default     = "e2-standard-4"
}

# Secrets (should come from Secret Manager in production)
variable "couchdb_password" {
  description = "CouchDB admin password"
  type        = string
  sensitive   = true
}

variable "ca_admin_password" {
  description = "Fabric CA admin password"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# GKE Cluster
# -----------------------------------------------------------------------------

resource "google_container_cluster" "primary" {
  name     = "${var.cluster_name}-${var.environment}"
  location = var.region

  # We can't create a cluster with no node pool, so we create the smallest
  # possible default node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Enable Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Network configuration
  network    = "default"
  subnetwork = "default"

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Master authorized networks (restrict in production)
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All (restrict in production)"
    }
  }

  # Enable network policy
  network_policy {
    enabled = true
  }

  # Logging and monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    disk_size_gb = 100
    disk_type    = "pd-ssd"

    # Enable Workload Identity on nodes
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      environment = var.environment
      component   = "fabric"
    }

    tags = ["fabric-node"]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# -----------------------------------------------------------------------------
# Fabric Components (using modules)
# -----------------------------------------------------------------------------

# TODO: Uncomment when Kubernetes provider is configured
#
# module "org1_peer0" {
#   source = "../modules/fabric-peer"
#
#   org_name     = "org1"
#   peer_name    = "peer0"
#   msp_id       = "Org1MSP"
#
#   kubernetes_namespace = "fabric-org1"
#   storage_class        = "standard-rwo"
#
#   couchdb_user     = "admin"
#   couchdb_password = var.couchdb_password
# }
#
# module "org1_ca" {
#   source = "../modules/fabric-ca"
#
#   org_name = "org1"
#   msp_id   = "Org1MSP"
#
#   ca_admin_user     = "admin"
#   ca_admin_password = var.ca_admin_password
#
#   kubernetes_namespace = "fabric-org1"
#   storage_class        = "standard-rwo"
# }

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "region" {
  description = "GCP region"
  value       = var.region
}

output "get_credentials_command" {
  description = "Command to get cluster credentials"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${var.region} --project ${var.project_id}"
}
