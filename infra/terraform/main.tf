terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "learn-k8s"
    storage_account_name = "petkeeparctic"
    container_name       = "tfstate"
    key                  = "jenkins.tfstate"
  }
}

provider "azurerm" {
  features {}
}
