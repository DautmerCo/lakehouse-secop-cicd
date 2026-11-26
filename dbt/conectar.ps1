# Carga en esta sesión las variables que usa profiles.yml, a partir del perfil de la CLI.
# No guarda nada en disco: el token es OAuth y vence en una hora.
param([string]$Perfil = "DEFAULT")

$cfg = (databricks auth env --profile $Perfil -o json | ConvertFrom-Json).env
$env:DBT_DATABRICKS_HOST = $cfg.DATABRICKS_HOST -replace '^https://', ''
$env:DBT_DATABRICKS_TOKEN = (databricks auth token --profile $Perfil -o json | ConvertFrom-Json).access_token
$bodega = databricks warehouses list --profile $Perfil -o json | ConvertFrom-Json | Select-Object -First 1
$env:DBT_DATABRICKS_HTTP_PATH = $bodega.odbc_params.path

Write-Host "Variables de dbt cargadas (el token vence en una hora)."