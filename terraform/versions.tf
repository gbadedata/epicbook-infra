terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Remote state in Azure Storage. The storage account was created outside Terraform,
  # in the same resource group, so Terraform never manages or destroys its own state.
  backend "azurerm" {
    resource_group_name  = "rg-oluwagbade-epicbook"
    storage_account_name = "stepicbooka70995"
    container_name       = "tfstate"
    key                  = "epicbook.tfstate"
  }
}

provider "azurerm" {
  features {}

  # The pipeline's service principal is scoped to one resource group, so it cannot
  # register resource providers at subscription level. They were registered beforehand.
  resource_provider_registrations = "none"
}
