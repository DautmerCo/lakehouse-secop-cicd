# El notebook se sube desde el repo; si cambias el .py, el próximo apply lo actualiza.
# Va en /Shared para que la ruta no incluya tu correo.
resource "databricks_notebook" "ingesta_bronze" {
  source = "${path.module}/../bronze/ingesta_bronze.py"
  path   = "/Shared/secop/${var.entorno}/ingesta_bronze"
}

resource "databricks_job" "secop" {
  name = "[${var.entorno}] secop_pipeline"

  parameter {
    name    = "entorno"
    default = var.entorno
  }

  # Sin bloque de clúster: en Free Edition corre en cómputo serverless.
  task {
    task_key    = "bronze"
    max_retries = 1

    notebook_task {
      notebook_path = databricks_notebook.ingesta_bronze.path
    }
  }
}