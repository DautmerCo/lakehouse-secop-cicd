locals {
  capas = {
    bronze = "Datos crudos de SECOP II tal como llegan de la API"
    silver = "Datos limpios y tipados (modelos de dbt)"
    gold   = "Modelo dimensional para análisis (modelos de dbt)"
  }
}

# Un esquema por capa, por ejemplo secop_dev_bronze.
resource "databricks_schema" "capa" {
  for_each = local.capas

  catalog_name = var.catalogo
  name         = "secop_${var.entorno}_${each.key}"
  comment      = each.value
}

resource "databricks_volume" "aterrizaje" {
  catalog_name = var.catalogo
  schema_name  = databricks_schema.capa["bronze"].name
  name         = "aterrizaje"
  volume_type  = "MANAGED"
  comment      = "Archivos JSON extraídos de la API de SECOP II"
}

resource "databricks_volume" "control" {
  catalog_name = var.catalogo
  schema_name  = databricks_schema.capa["bronze"].name
  name         = "control"
  volume_type  = "MANAGED"
  comment      = "Checkpoints y esquemas de Auto Loader"
}