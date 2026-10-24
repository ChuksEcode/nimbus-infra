terraform {
  backend "azurerm" {
    resource_group_name  = "nimbus-rg"
    storage_account_name = "nimbusstate01"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}