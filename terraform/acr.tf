resource "azurerm_container_registry" "acr" {
  name                = "${var.project_name}acrdev01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.acr_sku
  admin_enabled       = false
  tags                = local.common_tags
}