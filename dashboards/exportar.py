"""Exporta un tablero AI/BI de Databricks al JSON versionado en el repo.

Flujo para cambiar el tablero: se edita el desplegado en Databricks, se exporta con
este script, se revisa el diff y se abre un PR. Terraform lo vuelve a desplegar.
"""
import argparse
import json
from pathlib import Path

from databricks.sdk import WorkspaceClient

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--nombre", default="SECOP II · Contratación pública",
                    help="Nombre del tablero en Databricks")
parser.add_argument("--perfil", default="DEFAULT", help="Perfil de la CLI")
parser.add_argument("--salida", type=Path,
                    default=Path(__file__).with_name("secop.lvdash.json"))
args = parser.parse_args()

w = WorkspaceClient(profile=args.perfil)
tablero = next((d for d in w.lakeview.list() if d.display_name == args.nombre), None)
if tablero is None:
    raise SystemExit(f"No se encontró el tablero '{args.nombre}'")

contenido = json.loads(w.lakeview.get(tablero.dashboard_id).serialized_dashboard)

# El catálogo y el esquema los define Terraform (dataset_catalog / dataset_schema),
# así el mismo JSON sirve para dev y prod.
for dataset in contenido.get("datasets", []):
    dataset.pop("catalog", None)
    dataset.pop("schema", None)

args.salida.write_text(json.dumps(contenido, indent=2, ensure_ascii=False) + "\n",
                       encoding="utf-8", newline="\n")
print(f"Exportado '{args.nombre}' a {args.salida.name}")
