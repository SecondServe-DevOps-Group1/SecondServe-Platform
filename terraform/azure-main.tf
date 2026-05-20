# Terraform configuration for FoodHawk Platform on Azure
# Uses Azure Container Apps for serverless container deployment

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

# Azure Container Registry
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

# Container Apps Environment
resource "azurerm_container_app_environment" "foodhawk_env" {
  name                = "${var.project_name}-env"
  location            = azurerm_resource_group.foodhawk_rg.location
  resource_group_name = azurerm_resource_group.foodhawk_rg.name

  tags = {
    Environment = var.environment
  }
}

# Azure Database for PostgreSQL
resource "azurerm_postgresql_flexible_server" "foodhawk_db" {
  name                   = "${var.project_name}-db-${random_string.suffix.result}"
  resource_group_name    = azurerm_resource_group.foodhawk_rg.name
  location               = azurerm_resource_group.foodhawk_rg.location
  version                = "15"
  administrator_login    = var.db_username
  administrator_password = var.db_password

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

# Backend Container App
resource "azurerm_container_app" "backend" {
  name                         = "${var.project_name}-backend"
  resource_group_name          = azurerm_resource_group.foodhawk_rg.name
  container_app_environment_id = azurerm_container_app_environment.foodhawk_env.id
  revision_mode                = "Single"

  configuration {
    ingress {
      external_enabled = true
      target_port     = 8000
      traffic_weight {
        percentage = 100
        latest_revision = true
      }
    }

    secrets {
      name  = "database-url"
      value = "postgresql://${var.db_username}:${var.db_password}@${azurerm_postgresql_flexible_server.foodhawk_db.fqdn}:5432/foodhawk"
    }

    secrets {
      name  = "secret-key"
      value = var.secret_key
    }
  }

  template {
    container {
      name  = "backend"
      image = "${azurerm_container_registry.foodhawk_acr.login_server}/${var.backend_image}:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name        = "DATABASE_URL"
        secret_name = "database-url"
      }

      env {
        name        = "SECRET_KEY"
        secret_name = "secret-key"
      }

      env {
        name  = "JWT_ALGORITHM"
        value = "HS256"
      }

      env {
        name  = "ACCESS_TOKEN_EXPIRE_MINUTES"
        value = "1440"
      }
    }

    min_replicas = 1
    max_replicas = 10
  }

  tags = {
    Environment = var.environment
  }
}

# Frontend Container App
resource "azurerm_container_app" "frontend" {
  name                         = "${var.project_name}-frontend"
  resource_group_name          = azurerm_resource_group.foodhawk_rg.name
  container_app_environment_id = azurerm_container_app_environment.foodhawk_env.id
  revision_mode                = "Single"

  configuration {
    ingress {
      external_enabled = true
      target_port     = 80
      traffic_weight {
        percentage = 100
        latest_revision = true
      }
    }
  }

  template {
    container {
      name  = "frontend"
      image = "${azurerm_container_registry.foodhawk_acr.login_server}/${var.frontend_image}:latest"
      cpu    = 0.5
      memory = "0.5Gi"
    }

    min_replicas = 1
    max_replicas = 10
  }

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
