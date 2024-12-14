resource "azurerm_automation_account" "automation-account" {
  name                = "cloudopsmonitoring-poc-001"
  location            = azurerm_resource_group.inframonitor_prd_rg.location
  resource_group_name = azurerm_resource_group.inframonitor_prd_rg.name
  sku_name            = "Basic"

}


resource "azurerm_logic_app_workflow" "monitoringspn-logic_app_workflow" {
  name                = "logic-monitor-poc-001"
  location            = azurerm_resource_group.inframonitor_prd_rg.location
  resource_group_name = azurerm_resource_group.inframonitor_prd_rg.name

  lifecycle {
    ignore_changes = [
      parameters, workflow_parameters
    ]
  }
}


resource "azurerm_resource_group" "inframonitor_prd_rg" {
  name     = "rg-monitor-poc-001"
  location = "francentral"

}# Define variables for reusability and flexibility
variable "resource_group_name" {
  default = "rg-monitor-poc-001"
}

variable "location" {
  default = "francentral"
}

variable "automation_account_name" {
  default = "cloudopsmonitoring-poc-001"
}

variable "logic_app_name" {
  default = "logic-monitor-poc-001"
}

# Resource Group
resource "azurerm_resource_group" "inframonitor_prd_rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    environment = "poc"
    project     = "monitoring"
  }
}

# Automation Account
resource "azurerm_automation_account" "automation-account" {
  name                = var.automation_account_name
  location            = azurerm_resource_group.inframonitor_prd_rg.location
  resource_group_name = azurerm_resource_group.inframonitor_prd_rg.name
  sku_name            = "Basic"

  tags = {
    environment = "poc"
    project     = "monitoring"
  }
}

# Logic App Workflow
resource "azurerm_logic_app_workflow" "monitoringspn-logic_app_workflow" {
  name                = var.logic_app_name
  location            = azurerm_resource_group.inframonitor_prd_rg.location
  resource_group_name = azurerm_resource_group.inframonitor_prd_rg.name

  lifecycle {
    ignore_changes = [
      parameters, workflow_parameters
    ]
  }

  tags = {
    environment = "poc"
    project     = "monitoring"
  }
}# Define variables for reusability and flexibility
variable "resource_group_name" {
  default = "rg-monitor-poc-001"
}

variable "location" {
  default = "francentral"
}

variable "automation_account_name" {
  default = "cloudopsmonitoring-poc-001"
}

variable "logic_app_name" {
  default = "logic-monitor-poc-001"
}

# Resource Group
resource "azurerm_resource_group" "inframonitor_prd_rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    environment = "poc"
    project     = "monitoring"
  }
}

# Automation Account
resource "azurerm_automation_account" "automation-account" {
  name                = var.automation_account_name
  location            = azurerm_resource_group.inframonitor_prd_rg.location
  resource_group_name = azurerm_resource_group.inframonitor_prd_rg.name
  sku_name            = "Basic"

  tags = {
    environment = "poc"
    project     = "monitoring"
  }
}

# Logic App Workflow
resource "azurerm_logic_app_workflow" "monitoringspn-logic_app_workflow" {
  name                = var.logic_app_name
  location            = azurerm_resource_group.inframonitor_prd_rg.location
  resource_group_name = azurerm_resource_group.inframonitor_prd_rg.name

  lifecycle {
    ignore_changes = [
      parameters, workflow_parameters
    ]
  }

  tags = {
    environment = "poc"
    project     = "monitoring"
  }
}git checkout -b feat/enhancementgit checkout -b feat/enhancement