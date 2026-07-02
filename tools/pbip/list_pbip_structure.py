#!/usr/bin/env python
"""Inspecciona la estructura de un proyecto Power BI PBIP."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


CARPETAS_EXCLUIDAS = {
    ".git",
    ".hg",
    ".svn",
    ".venv",
    "venv",
    "env",
    "node_modules",
    "__pycache__",
    ".pytest_cache",
    ".mypy_cache",
    ".ruff_cache",
    "backups_codex",
    "backup",
    "backups",
    "tmp",
    "temp",
    "temporal",
    "temporales",
}


def ruta_relativa(ruta: Path, raiz: Path) -> str:
    """Devuelve una ruta relativa al proyecto, con separadores estables."""
    try:
        return ruta.relative_to(raiz).as_posix()
    except ValueError:
        return ruta.as_posix()


def ruta_excluida(ruta: Path, raiz: Path) -> bool:
    """Indica si una ruta pertenece a carpetas no oficiales o temporales."""
    try:
        partes = ruta.relative_to(raiz).parts
    except ValueError:
        partes = ruta.parts

    for parte in partes:
        nombre = parte.lower()
        if nombre in CARPETAS_EXCLUIDAS:
            return True
        if nombre.startswith("backup_") or nombre.startswith("tmp_") or nombre.startswith("temp_"):
            return True
    return False


def iterar_archivos_filtrados(raiz: Path, patron: str):
    """Itera archivos evitando carpetas excluidas desde el recorrido."""
    for ruta in raiz.rglob(patron):
        if ruta.is_file() and not ruta_excluida(ruta, raiz):
            yield ruta


def estado_ruta(ruta: Path, raiz: Path) -> dict[str, Any]:
    """Describe si una ruta existe y su ubicacion relativa."""
    return {
        "existe": ruta.exists(),
        "ruta": ruta_relativa(ruta, raiz),
    }


def listar_carpetas_principales(raiz: Path) -> list[dict[str, Any]]:
    """Lista las carpetas inmediatas del proyecto."""
    if not raiz.exists() or not raiz.is_dir():
        return []

    carpetas: list[dict[str, Any]] = []
    for ruta in sorted(raiz.iterdir(), key=lambda item: item.name.lower()):
        if ruta.is_dir():
            carpetas.append(
                {
                    "nombre": ruta.name,
                    "ruta": ruta_relativa(ruta, raiz),
                }
            )
    return carpetas


def listar_archivos_por_patron(raiz: Path, patron: str) -> list[str]:
    """Lista archivos por patron sin fallar si la raiz no existe."""
    if not raiz.exists() or not raiz.is_dir():
        return []

    return [
        ruta_relativa(ruta, raiz)
        for ruta in sorted(iterar_archivos_filtrados(raiz, patron), key=lambda item: item.as_posix().lower())
    ]


def detectar_pbip_activo(raiz: Path) -> dict[str, Any]:
    """Detecta el PBIP activo esperado del proyecto."""
    ruta_activa = raiz / "PBIP" / "Proyecto4.pbip"
    return {
        "existe": ruta_activa.exists(),
        "ruta": ruta_relativa(ruta_activa, raiz),
    }


def leer_json_seguro(ruta: Path) -> tuple[dict[str, Any] | None, str | None]:
    """Lee JSON y devuelve un error textual si no se puede parsear."""
    try:
        with ruta.open("r", encoding="utf-8-sig") as archivo:
            datos = json.load(archivo)
        if isinstance(datos, dict):
            return datos, None
        return None, "El JSON no contiene un objeto en la raiz."
    except FileNotFoundError:
        return None, "El archivo no existe."
    except json.JSONDecodeError as error:
        return None, f"JSON invalido: {error.msg} en linea {error.lineno}, columna {error.colno}."
    except OSError as error:
        return None, f"Error leyendo archivo: {error}."


def obtener_nombre_pagina(datos: dict[str, Any]) -> str | None:
    """Busca un nombre visible de pagina en campos comunes del PBIP."""
    for clave in ("displayName", "name", "display_name"):
        valor = datos.get(clave)
        if isinstance(valor, str) and valor.strip():
            return valor

    configuracion = datos.get("config")
    if isinstance(configuracion, dict):
        for clave in ("displayName", "name"):
            valor = configuracion.get(clave)
            if isinstance(valor, str) and valor.strip():
                return valor

    return None


def contar_visuales(carpeta_pagina: Path) -> int:
    """Cuenta visuales por archivos visual.json dentro de la pagina."""
    carpeta_visuales = carpeta_pagina / "visuals"
    if not carpeta_visuales.exists() or not carpeta_visuales.is_dir():
        return 0
    return sum(1 for ruta in carpeta_visuales.rglob("visual.json") if ruta.is_file())


def listar_paginas(raiz: Path) -> list[dict[str, Any]]:
    """Lista paginas del reporte leyendo cada page.json disponible."""
    carpeta_paginas = raiz / "PBIP" / "Proyecto.Report" / "definition" / "pages"
    if not carpeta_paginas.exists() or not carpeta_paginas.is_dir():
        return []

    paginas: list[dict[str, Any]] = []
    for page_json in sorted(carpeta_paginas.glob("*/page.json"), key=lambda item: item.as_posix().lower()):
        carpeta_pagina = page_json.parent
        datos, error = leer_json_seguro(page_json)
        pagina: dict[str, Any] = {
            "id_carpeta": carpeta_pagina.name,
            "nombre_visible": obtener_nombre_pagina(datos) if datos else None,
            "page_json": ruta_relativa(page_json, raiz),
            "cantidad_visuales": contar_visuales(carpeta_pagina),
        }
        if error:
            pagina["error"] = error
        paginas.append(pagina)

    return paginas


def listar_archivos_documentacion(raiz: Path, nombre_carpeta: str) -> dict[str, Any]:
    """Lista archivos de una carpeta sin leer su contenido completo."""
    carpeta = raiz / nombre_carpeta
    resultado: dict[str, Any] = estado_ruta(carpeta, raiz)
    resultado["archivos"] = []

    if not carpeta.exists() or not carpeta.is_dir():
        return resultado

    archivos: list[dict[str, Any]] = []
    for ruta in sorted(carpeta.rglob("*"), key=lambda item: item.as_posix().lower()):
        if ruta.is_file() and not ruta_excluida(ruta, raiz):
            try:
                estadisticas = ruta.stat()
                archivos.append(
                    {
                        "ruta": ruta_relativa(ruta, raiz),
                        "tamano_bytes": estadisticas.st_size,
                        "modificado_epoch": int(estadisticas.st_mtime),
                    }
                )
            except OSError as error:
                archivos.append(
                    {
                        "ruta": ruta_relativa(ruta, raiz),
                        "error": f"No se pudo leer metadatos: {error}.",
                    }
                )

    resultado["archivos"] = archivos
    return resultado


def inspeccionar_proyecto(ruta_proyecto: Path) -> dict[str, Any]:
    """Construye el resumen JSON de estructura del proyecto."""
    raiz = ruta_proyecto.expanduser().resolve()

    resultado: dict[str, Any] = {
        "proyecto": {
            "ruta": raiz.as_posix(),
            "existe": raiz.exists(),
            "es_directorio": raiz.is_dir(),
        },
        "carpetas_principales": listar_carpetas_principales(raiz),
        "pbip_activo": detectar_pbip_activo(raiz),
        "archivos_pbip": listar_archivos_por_patron(raiz, "*.pbip"),
        "rutas_clave": {
            "reporte": estado_ruta(raiz / "PBIP" / "Proyecto.Report", raiz),
            "modelo_semantico": estado_ruta(raiz / "PBIP" / "Proyecto.SemanticModel", raiz),
            "docs": estado_ruta(raiz / "Docs", raiz),
            "outputs": estado_ruta(raiz / "Outputs", raiz),
            "tools": estado_ruta(raiz / "tools", raiz),
        },
        "paginas_reporte": listar_paginas(raiz),
        "documentacion": listar_archivos_documentacion(raiz, "Docs"),
        "outputs": listar_archivos_documentacion(raiz, "Outputs"),
        "errores": [],
    }

    if not raiz.exists():
        resultado["errores"].append("La ruta del proyecto no existe.")
    elif not raiz.is_dir():
        resultado["errores"].append("La ruta del proyecto no es una carpeta.")

    return resultado


def crear_parser() -> argparse.ArgumentParser:
    """Configura argumentos de linea de comandos."""
    parser = argparse.ArgumentParser(
        description="Inspecciona la estructura de un proyecto Power BI PBIP y devuelve JSON."
    )
    parser.add_argument("ruta_proyecto", help="Ruta del proyecto a inspeccionar.")
    parser.add_argument(
        "--pretty",
        action="store_true",
        help="Imprime JSON con indentacion legible.",
    )
    return parser


def main() -> int:
    """Punto de entrada de la herramienta."""
    parser = crear_parser()
    argumentos = parser.parse_args()

    resultado = inspeccionar_proyecto(Path(argumentos.ruta_proyecto))
    indentacion = 2 if argumentos.pretty else None
    print(json.dumps(resultado, ensure_ascii=False, indent=indentacion))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
