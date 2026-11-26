data "databricks_sql_warehouse" "principal" {
  name = "Serverless Starter Warehouse"
}

resource "databricks_dashboard" "secop" {
  display_name      = "SECOP II · Contratación pública"
  warehouse_id      = data.databricks_sql_warehouse.principal.id
  file_path         = "${path.module}/../dashboards/secop.lvdash.json"
  parent_path       = "/Shared/secop/${var.entorno}"
  dataset_catalog   = var.catalogo
  dataset_schema    = databricks_schema.capa["gold"].name
  embed_credentials = true
}