# Databricks notebook source
# MAGIC %md
# MAGIC # Bronze: contratos de SECOP II
# MAGIC Lee con Auto Loader los `.json.gz` nuevos del Volume de aterrizaje y los agrega a la tabla
# MAGIC `contratos` sin transformarlos. Los tipos y la limpieza se hacen en Silver, con dbt.

# COMMAND ----------

from pyspark.sql import functions as F

dbutils.widgets.text("entorno", "dev")
entorno = dbutils.widgets.get("entorno")

tabla = f"workspace.secop_{entorno}_bronze.contratos"
aterrizaje = f"/Volumes/workspace/secop_{entorno}_bronze/aterrizaje/contratos"
control = f"/Volumes/workspace/secop_{entorno}_bronze/control/autoloader/contratos"

# COMMAND ----------

flujo = (
    spark.readStream.format("cloudFiles")
    .option("cloudFiles.format", "json")
    .option("cloudFiles.schemaLocation", f"{control}/esquema")
    .option("cloudFiles.inferColumnTypes", "false")         # todo como texto en Bronze
    .option("cloudFiles.schemaEvolutionMode", "addNewColumns")
    .option("cloudFiles.partitionColumns", "corrida")       # sale de la carpeta corrida=...
    .load(aterrizaje)
    .withColumn("_archivo", F.col("_metadata.file_path"))
    .withColumn("_ingerido_en", F.current_timestamp())
)

(
    flujo.writeStream
    .option("checkpointLocation", f"{control}/checkpoint")
    .option("mergeSchema", "true")
    .trigger(availableNow=True)
    .toTable(tabla)
    .awaitTermination()
)

# COMMAND ----------

display(spark.sql(f"""
    SELECT corrida, count(*) AS filas, count(DISTINCT id_contrato) AS contratos
    FROM {tabla}
    GROUP BY corrida
    ORDER BY corrida
"""))