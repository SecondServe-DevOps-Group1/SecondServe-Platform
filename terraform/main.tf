# Free Tier Azure Terraform Configuration for FoodHawk Platform
# Uses Azure Free Account benefits and free tiers where possible

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "foodhawk_rg" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.azure_region

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Azure Container Registry (Basic Tier)
# Note: Basic tier costs ~$5/month, but required for pipeline image storage
resource "azurerm_container_registry" "foodhawk_acr" {
  name                = "${var.project_name}acr${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.foodhawk_rg.name
  location            = azurerm_resource_group.foodhawk_rg.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = {
    Environment = var.environment
  }
}

# Azure Database for PostgreSQL (Free Tier - B1bs Burstable)
# Note: Available free for 12 months with Azure Free Account
resource "azurerm_postgresql_flexible_server" "foodhawk_db" {
  name                   = "${var.project_name}-db-${random_string.suffix.result}"
  resource_group_name    = azurerm_resource_group.foodhawk_rg.name
  location               = azurerm_resource_group.foodhawk_rg.location
  version                = "15"
  administrator_login    = var.db_username
  administrator_password = var.db_password

  # B1s is available on Azure for Students
  storage_mb                   = 32768
  sku_name                     = "B_Standard_B1s"
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_postgresql_flexible_server_database" "foodhawk_db" {
  name      = "foodhawk"
  server_id = azurerm_postgresql_flexible_server.foodhawk_db.id
  charset   = "UTF8"
  collation = "en_US_UTF8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  name                = "allow-azure-services"
  server_id           = azurerm_postgresql_flexible_server.foodhawk_db.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Azure App Service Plan (Free Tier F1)
# Free tier: 1 GB storage, 60 minutes CPU/day
resource "azurerm_service_plan" "foodhawk_app_plan" {
  name                = "${var.project_name}-app-plan"
  location            = azurerm_resource_group.foodhawk_rg.location
  resource_group_name = azurerm_resource_group.foodhawk_rg.name
  os_type             = "Linux"
  sku_name            = "F1" # Free tier

  tags = {
    Environment = var.environment
  }
}

# Backend Web App (Python/FastAPI on Free Tier)
resource "azurerm_linux_web_app" "backend" {
  name                = "${var.project_name}-backend-${random_string.suffix.result}"
  location            = azurerm_resource_group.foodhawk_rg.location
  resource_group_name = azurerm_resource_group.foodhawk_rg.name
  service_plan_id     = azurerm_service_plan.foodhawk_app_plan.id

  # Use ACR image
  site_config {
    linux_fx_version = "DOCKER|${azurerm_container_registry.foodhawk_acr.login_server}/foodhawk-backend:latest"
    always_on        = false # Disable to stay within free tier limits
  }

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL"      = "https://${azurerm_container_registry.foodhawk_acr.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME" = azurerm_container_registry.foodhawk_acr.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD" = azurerm_container_registry.foodhawk_acr.admin_password
    "DATABASE_URL"                    = "postgresql://${var.db_username}:${var.db_password}@${azurerm_postgresql_flexible_server.foodhawk_db.fqdn}:5432/foodhawk"
    "SECRET_KEY"                      = var.secret_key
    "JWT_ALGORITHM"                   = "HS256"
    "ACCESS_TOKEN_EXPIRE_MINUTES"     = "1440"
    "WEBSITES_PORT"                   = "8000"
  }

  tags = {
    Environment = var.environment
  }
}

# Azure Static Web Apps (Free Tier for Frontend)
# Free tier: Unlimited static sites, 100 GB bandwidth/month
resource "azurerm_static_web_app" "frontend" {
  name                = "${var.project_name}-frontend-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.foodhawk_rg.name
  location            = azurerm_resource_group.foodhawk_rg.location
  sku_tier             = "Free"
  sku_size             = "Free"

  # For Static Web Apps, you typically deploy via GitHub Actions
  # This creates the resource, but deployment is done via CI/CD
  
  tags = {
    Environment = var.environment
  }
}

# Random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}
