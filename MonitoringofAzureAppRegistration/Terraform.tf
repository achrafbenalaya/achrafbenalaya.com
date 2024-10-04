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

}