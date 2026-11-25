terraform {
  required_version = ">= 1.6"

  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.0"
    }
  }
}

# Usa la misma conexión que la CLI: así ninguna dirección ni token queda en el código.
provider "databricks" {
  profile = var.perfil_databricks
}