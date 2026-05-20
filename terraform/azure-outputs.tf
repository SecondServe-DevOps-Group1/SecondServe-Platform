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
  description = "URL of the backend container app"
  value       = azurerm_container_app.backend.ingress[0].fqdn
}

output "frontend_url" {
  description = "URL of the frontend container app"
  value       = azurerm_container_app.frontend.ingress[0].fqdn
}

output "database_hostname" {
  description = "Hostname of the PostgreSQL database"
  value       = azurerm_postgresql_flexible_server.foodhawk_db.fqdn
}

output "container_app_environment_id" {
  description = "ID of the container app environment"
  value       = azurerm_container_app_environment.foodhawk_env.id
}
