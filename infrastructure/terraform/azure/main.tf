# Azure Infrastructure for Tolling.Network
#
# Deploys:
# - AKS cluster
# - Org3: 2 peers + 1 CA
# - 1 orderer node (part of 5-node Raft cluster)

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }

  # Uncomment for remote state
  # backend "azurerm" {
  #   resource_group_name  = "tolling-network-state-rg"
  #   storage_account_name = "tollingnetworkstate"
  #   container_name       = "tfstate"
  #   key                  = "azure/terraform.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "location" {
  description = "Azure region"
  type        = string
  default     = "westus2"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "tolling-network-rg"
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
  default     = "tolling-network"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

variable "vm_size" {
  description = "VM size for worker nodes"
  type        = string
  default     = "Standard_D4s_v3"
}

# Secrets (should come from Key Vault in production)
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
# Resource Group
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name     = "${var.resource_group_name}-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "tolling-network"
  }
}

# -----------------------------------------------------------------------------
# Virtual Network
# -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "main" {
  name                = "${var.cluster_name}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# -----------------------------------------------------------------------------
# AKS Cluster
# -----------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.cluster_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.cluster_name}-${var.environment}"
  kubernetes_version  = "1.29"

  default_node_pool {
    name                = "default"
    node_count          = var.node_count
    vm_size             = var.vm_size
    vnet_subnet_id      = azurerm_subnet.aks.id
    enable_auto_scaling = false

    tags = {
      Environment = var.environment
      Component   = "fabric"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  azure_policy_enabled = true

  tags = {
    Environment = var.environment
    Project     = "tolling-network"
  }
}

# -----------------------------------------------------------------------------
# Log Analytics (for monitoring)
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.cluster_name}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Key Vault (for secrets)
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                       = "${var.cluster_name}-kv-${var.environment}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge",
    ]
  }

  # Allow AKS to access Key Vault
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id

    secret_permissions = [
      "Get",
      "List",
    ]
  }

  tags = {
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "kube_config" {
  description = "Kubernetes config"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "resource_group" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "location" {
  description = "Azure region"
  value       = var.location
}

output "get_credentials_command" {
  description = "Command to get cluster credentials"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.main.vault_uri
}
