output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.foodhawk_rg.name
}

output "container_registry_url" {
  description = "Login server URL of the container registry"
  value       = azurerm_container_registry.foodhawk_acr.login_server
}

output "container_registry_username" {
  description = "Username for the container registry"
  value       = azurerm_container_registry.foodhawk_acr.admin_username
  sensitive   = true
}

output "backend_url" {
  description = "URL of the backend web app"
  value       = azurerm_linux_web_app.backend.default_hostname
}

output "frontend_url" {
  description = "URL of the frontend static web app"
  value       = azurerm_static_web_app.frontend.default_host_name
}

output "database_hostname" {
  description = "Hostname of the SQL database"
  value       = azurerm_mssql_server.foodhawk_db.fqdn
}
