variable "azure_region" {
  description = "Azure region for deployment"
  type        = string
  default     = "eastus"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "foodhawk"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "backend_image" {
  description = "Docker image name for backend (without tag)"
  type        = string
  default     = "foodhawk-backend"
}

variable "frontend_image" {
  description = "Docker image name for frontend (without tag)"
  type        = string
  default     = "foodhawk-frontend"
}

variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
}
