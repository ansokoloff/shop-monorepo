resource "azurerm_resource_group" "main" {
  name     = "rg-shop-${var.environment}"
  location = var.location

  tags = {
    managed_by = "terraform"
    environment = var.environment
  }
}
