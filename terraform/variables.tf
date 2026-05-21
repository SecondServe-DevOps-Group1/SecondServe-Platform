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

variable "supabase_database_url" {
  description = "Supabase database connection URL"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
}
