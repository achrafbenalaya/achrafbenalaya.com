// Resource group
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
}

// create a secdond resource group
resource "azurerm_resource_group" "second" {
  name     = "${var.prefix}-second-resources"
  location = var.location
}

// create a  resource group based on a variable count
resource "azurerm_resource_group" "count" {
  count = var.count
  name = "${var.prefix}-count-resources-${count.index}"
  location = var.location
}