"""Extrae contratos de SECOP II desde datos.gov.co y los deja en el Volume de aterrizaje.

Carga incremental: pide solo los contratos con ultima_actualizacion >= la marca de agua
guardada en el Volume de control. Como esa columna es una fecha sin hora, el último día
se vuelve a pedir completo; los duplicados se resuelven en Silver por id_contrato.
"""
import argparse
import gzip
import io
import json
import os
from datetime import datetime, timezone

import requests
from databricks.sdk import WorkspaceClient
from databricks.sdk.errors import NotFound
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

API = "https://www.datos.gov.co/resource/jbjy-vk9h.json"
FILAS_POR_PAGINA = 20_000

# Solo lo que usa el análisis. Se excluyen a propósito cuentas bancarias y documentos
# de supervisores, ordenadores del gasto y representantes legales.
COLUMNAS = [
    "id_contrato", "referencia_del_contrato", "proceso_de_compra", "urlproceso",
    "nombre_entidad", "nit_entidad", "codigo_entidad", "departamento", "ciudad",
    "orden", "sector", "rama", "entidad_centralizada",
    "estado_contrato", "tipo_de_contrato", "modalidad_de_contratacion",
    "codigo_de_categoria_principal", "objeto_del_contrato",
    "fecha_de_firma", "fecha_de_inicio_del_contrato", "fecha_de_fin_del_contrato",
    "tipodocproveedor", "documento_proveedor", "proveedor_adjudicado", "codigo_proveedor",
    "es_grupo", "es_pyme", "origen_de_los_recursos", "destino_gasto",
    "valor_del_contrato", "valor_facturado", "valor_pagado", "valor_pendiente_de_pago",
    "dias_adicionados", "espostconflicto", "ultima_actualizacion",
]


def crear_sesion() -> requests.Session:
    """Sesión HTTP que reintenta sola ante errores temporales (429 y 5xx)."""
    reintentos = Retry(total=5, backoff_factor=2, status_forcelist=[429, 500, 502, 503, 504])
    sesion = requests.Session()
    sesion.mount("https://", HTTPAdapter(max_retries=reintentos))
    token = os.getenv("SOCRATA_APP_TOKEN")  # opcional: da más cuota en la API
    if token:
        sesion.headers["X-App-Token"] = token
    return sesion


def paginas(sesion: requests.Session, desde: str):
    """Entrega los contratos actualizados desde `desde`, de a FILAS_POR_PAGINA."""
    desplazamiento = 0
    while True:
        respuesta = sesion.get(API, timeout=300, params={
            "$select": ",".join(COLUMNAS),
            "$where": f"ultima_actualizacion >= '{desde}'",
            "$order": ":id",  # orden estable para que la paginación no salte filas
            "$limit": FILAS_POR_PAGINA,
            "$offset": desplazamiento,
        })
        respuesta.raise_for_status()
        filas = respuesta.json()
        if not filas:
            return
        yield filas
        desplazamiento += len(filas)


def leer_marca(w: WorkspaceClient, ruta: str, inicial: str) -> str:
    try:
        return json.loads(w.files.download(ruta).contents.read())["ultima_actualizacion"]
    except NotFound:
        return inicial


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--entorno", choices=["dev", "prod"], default="dev")
    parser.add_argument("--desde-inicial", default="2026-10-01",
                        help="Fecha de arranque cuando todavía no hay marca de agua")
    parser.add_argument("--perfil", help="Perfil de la CLI. En GitHub Actions se omite "
                                         "y el SDK usa las variables de entorno")
    args = parser.parse_args()

    w = WorkspaceClient(profile=args.perfil) if args.perfil else WorkspaceClient()
    base = f"/Volumes/workspace/secop_{args.entorno}_bronze"
    ruta_marca = f"{base}/control/extraccion/marca_de_agua.json"

    desde = leer_marca(w, ruta_marca, args.desde_inicial)
    corrida = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    carpeta = f"{base}/aterrizaje/contratos/corrida={corrida}"
    print(f"Extrayendo contratos con ultima_actualizacion >= {desde}")

    total, maxima = 0, desde
    for n, filas in enumerate(paginas(crear_sesion(), desde), start=1):
        lineas = "\n".join(json.dumps(f, ensure_ascii=False) for f in filas)
        w.files.upload(f"{carpeta}/parte-{n:04d}.json.gz",
                       io.BytesIO(gzip.compress(lineas.encode("utf-8"))), overwrite=True)
        total += len(filas)
        maxima = max([maxima] + [f["ultima_actualizacion"] for f in filas
                                 if f.get("ultima_actualizacion")])
        print(f"  página {n}: {len(filas):,} filas")

    # La marca se mueve solo al final: si algo falla a mitad, la próxima corrida repite todo.
    if total:
        marca = {"ultima_actualizacion": maxima[:10], "corrida": corrida, "filas": total}
        w.files.upload(ruta_marca, io.BytesIO(json.dumps(marca).encode()), overwrite=True)
    print(f"Listo: {total:,} filas en {carpeta}" if total else "Sin contratos nuevos")


if __name__ == "__main__":
    main()