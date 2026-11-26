output "id_job" {
  description = "Id del job, para ejecutarlo desde la CLI o desde GitHub Actions"
  value       = databricks_job.secop.id
}

output "id_lectura_gold" {
  description = "application_id del service principal que lee Gold"
  value       = databricks_service_principal.lectura_gold.application_id
}