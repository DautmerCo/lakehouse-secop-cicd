# Identidad de los consumidores de Gold (tableros, herramientas de BI).
resource "databricks_service_principal" "lectura_gold" {
  display_name = "secop-${var.entorno}-lectura-gold"
}

# databricks_grant (singular) AGREGA permisos a un principal sin tocar los demás.
# databricks_grants (plural) REEMPLAZA todos los permisos del objeto: sobre el catálogo
# compartido "workspace" borraría los permisos que ya existen.
resource "databricks_grant" "catalogo_lectura" {
  catalog    = var.catalogo
  principal  = databricks_service_principal.lectura_gold.application_id
  privileges = ["USE_CATALOG"]
}

resource "databricks_grant" "gold_lectura" {
  schema     = databricks_schema.capa["gold"].id
  principal  = databricks_service_principal.lectura_gold.application_id
  privileges = ["USE_SCHEMA", "SELECT"]
}