output "id_job" {
  description = "Id del job, para ejecutarlo desde la CLI o desde GitHub Actions"
  value       = databricks_job.secop.id
}