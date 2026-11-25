variable "perfil_databricks" {
  description = "Perfil de ~/.databrickscfg con el que se conecta Terraform"
  type        = string
  default     = "DEFAULT"
}

variable "catalogo" {
  description = "Catálogo de Unity Catalog donde viven los esquemas"
  type        = string
  default     = "workspace"
}

variable "entorno" {
  description = "Entorno a desplegar: dev o prod"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.entorno)
    error_message = "El entorno debe ser dev o prod."
  }
}