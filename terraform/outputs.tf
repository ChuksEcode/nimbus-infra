# Resource Group
output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "resource_group_location" {
  description = "The Azure region of the resource group"
  value       = azurerm_resource_group.rg.location
}

# Azure Container Registry
output "acr_name" {
  description = "The name of the Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "The login server URL for ACR"
  value       = azurerm_container_registry.acr.login_server
}

# AKS
output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_kubelet_identity" {
  description = "The kubelet identity object ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# Key Vault
output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.kv.name
}

# Storage
output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.sa.name
}

output "storage_container_name" {
  description = "The Terraform state storage container"
  value       = azurerm_storage_container.tfstate.name
}