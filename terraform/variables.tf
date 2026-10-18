variable "project_name" {
  description = "Base name for all resources"
  type        = string
  default     = "nimbus"
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "East US"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)

  default = {
    environment = "Dev"
    owner       = "nimbus"
  }
}

# ACR
variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Basic"
}

# AKS
variable "aks_node_count" {
  description = "Number of nodes in the default AKS node pool"
  type        = number
  default     = 1
}

variable "aks_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v5"
}

# Key Vault
variable "kv_sku" {
  description = "SKU for Azure Key Vault"
  type        = string
  default     = "standard"
}

# Storage
variable "storage_replication_type" {
  description = "Replication type for the storage account"
  type        = string
  default     = "LRS"
}