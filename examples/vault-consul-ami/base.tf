# Configure the Azure Provider
provider "azurerm" { }

# Create a resource group
resource "azurerm_resource_group" "network" {
  name     = "production"
  location = "West US"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "network" {
  name                = "production-network"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.network.location}"
  resource_group_name = "${azurerm_resource_group.network.name}"

  subnet {
    name           = "web"
    address_prefix = "10.0.1.0/24"
  }

  subnet {
    name           = "app"
    address_prefix = "10.0.2.0/24"
  }

  subnet {
    name           = "db"
    address_prefix = "10.0.3.0/24"
  }
}