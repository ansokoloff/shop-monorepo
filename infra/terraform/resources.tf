resource "azurerm_resource_group" "main" {
  name     = "rg-shop-${var.environment}"
  location = var.location
}
