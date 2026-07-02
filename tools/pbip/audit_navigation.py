#!/usr/bin/env python
"""Audita navegacion en un proyecto Power BI PBIP sin modificar archivos."""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


PALABRAS_NAVEGACION = ("nav_", "btn_", "button", "actionbutton")
SEVERIDADES = ("alta", "media", "baja", "pendiente_validacion")


def ruta_relativa(ruta: Path, raiz: Path) -> str:
    """Devuelve ruta relativa estable al repositorio."""
    try:
        return ruta.relative_to(raiz).as_posix()
    except ValueError:
        return ruta.as_posix()


def leer_json_seguro(ruta: Path) -> tuple[Any | None, str | None]:
    """Lee un JSON sin detener toda la auditoria ante errores."""
    try:
        with ruta.open("r", encoding="utf-8-sig") as archivo:
            return json.load(archivo), None
    except FileNotFoundError:
        return None, "archivo_no_existe"
    except json.JSONDecodeError as error:
        return None, f"json_invalido_linea_{error.lineno}_columna_{error.colno}"
    except OSError as error:
        return None, f"error_lectura_{error}"


def valor_literal(nodo: Any) -> str | None:
    """Extrae valores Literal de objetos PBIP."""
    if not isinstance(nodo, dict):
        return None
    try:
        valor = nodo["expr"]["Literal"]["Value"]
    except KeyError:
        return None
    if isinstance(valor, str):
        return valor.strip("'")
    return str(valor)


def valores_propiedad(contenedor: dict[str, Any], objeto: str, propiedad: str) -> list[str]:
    """Obtiene valores literales desde objetos visuales de Power BI."""
    valores: list[str] = []
    for item in contenedor.get(objeto, []):
        if not isinstance(item, dict):
            continue
        propiedades = item.get("properties", {})
        if propiedad in propiedades:
            valor = valor_literal(propiedades[propiedad])
            if valor:
                valores.append(valor)
    return valores


def nombre_pagina(datos: dict[str, Any] | None, id_pagina: str) -> str:
    """Obtiene nombre visible de pagina con fallback al id."""
    if not isinstance(datos, dict):
        return id_pagina
    for campo in ("displayName", "name", "display_name"):
        valor = datos.get(campo)
        if isinstance(valor, str) and valor.strip():
            return valor
    return id_pagina


def cargar_pages_json(carpeta_paginas: Path, raiz: Path) -> tuple[list[str], list[dict[str, Any]]]:
    """Lee pages.json para obtener orden/lista oficial de paginas."""
    alertas: list[dict[str, Any]] = []
    ruta_pages = carpeta_paginas / "pages.json"
    datos, error = leer_json_seguro(ruta_pages)
    if error:
        alertas.append(
            crear_alerta(
                "alta",
                "pages_json_no_usable",
                "No se pudo leer pages.json.",
                ruta_relativa(ruta_pages, raiz),
            )
        )
        return [], alertas
    if not isinstance(datos, dict):
        alertas.append(
            crear_alerta(
                "alta",
                "pages_json_formato_no_soportado",
                "pages.json no contiene un objeto JSON en la raiz.",
                ruta_relativa(ruta_pages, raiz),
            )
        )
        return [], alertas
    paginas = datos.get("pageOrder") or datos.get("pages") or []
    if not isinstance(paginas, list):
        alertas.append(
            crear_alerta(
                "pendiente_validacion",
                "pages_json_sin_lista_paginas",
                "No se identifico una lista de paginas interpretable en pages.json.",
                ruta_relativa(ruta_pages, raiz),
            )
        )
        return [], alertas
    return [pagina for pagina in paginas if isinstance(pagina, str)], alertas


def crear_alerta(severidad: str, tipo: str, mensaje: str, archivo: str, contexto: dict[str, Any] | None = None) -> dict[str, Any]:
    """Crea una alerta normalizada."""
    return {
        "severidad": severidad if severidad in SEVERIDADES else "pendiente_validacion",
        "tipo": tipo,
        "mensaje": mensaje,
        "archivo": archivo,
        "contexto": contexto or {},
    }


def es_visual_navegacion(ruta_visual: Path, datos: dict[str, Any]) -> bool:
    """Detecta visuales candidatos de navegacion por nombre, ruta o tipo."""
    ruta_texto = ruta_visual.as_posix().lower()
    nombre = str(datos.get("name", "")).lower()
    tipo_visual = str((datos.get("visual") or {}).get("visualType", "")).lower()
    return any(palabra in ruta_texto or palabra in nombre or palabra in tipo_visual for palabra in PALABRAS_NAVEGACION)


def extraer_texto_visual(datos: dict[str, Any]) -> str | None:
    """Extrae texto visible o alternativo del boton."""
    visual = datos.get("visual") or {}
    objetos = visual.get("objects") or {}
    contenedores = visual.get("visualContainerObjects") or {}

    textos = valores_propiedad(objetos, "text", "text")
    if textos:
        return textos[0]

    alternativos = valores_propiedad(contenedores, "general", "altText")
    if alternativos:
        return alternativos[0]

    tooltips = valores_propiedad(contenedores, "visualLink", "tooltip")
    if tooltips:
        return tooltips[0]

    return None


def extraer_accion(datos: dict[str, Any]) -> tuple[str | None, str | None, str]:
    """Extrae tipo de accion y destino de navegacion si existen."""
    visual = datos.get("visual") or {}
    contenedores = visual.get("visualContainerObjects") or {}
    objetos = visual.get("objects") or {}
    candidatos = [contenedores, objetos]

    for contenedor in candidatos:
        tipos = valores_propiedad(contenedor, "visualLink", "type")
        destinos = valores_propiedad(contenedor, "visualLink", "navigationSection")
        if tipos or destinos:
            return (tipos[0] if tipos else None, destinos[0] if destinos else None, "interpretado")

    return None, None, "pendiente_validacion"


def cargar_paginas(carpeta_paginas: Path, raiz: Path, ids_pages_json: list[str]) -> tuple[list[dict[str, Any]], dict[str, str], list[dict[str, Any]]]:
    """Carga metadata de paginas del reporte."""
    paginas: list[dict[str, Any]] = []
    nombres_por_id: dict[str, str] = {}
    alertas: list[dict[str, Any]] = []
    ids_pages_json_set = set(ids_pages_json)

    for page_json in sorted(carpeta_paginas.glob("*/page.json"), key=lambda item: item.as_posix().lower()):
        id_pagina = page_json.parent.name
        datos, error = leer_json_seguro(page_json)
        nombre = nombre_pagina(datos if isinstance(datos, dict) else None, id_pagina)
        nombres_por_id[id_pagina] = nombre
        visuales = list((page_json.parent / "visuals").rglob("visual.json")) if (page_json.parent / "visuals").exists() else []
        pagina = {
            "id": id_pagina,
            "nombre": nombre,
            "ruta": ruta_relativa(page_json, raiz),
            "en_pages_json": id_pagina in ids_pages_json_set if ids_pages_json else None,
            "cantidad_visuales": len(visuales),
        }
        if error:
            pagina["estado"] = "pendiente_validacion"
            pagina["error"] = error
            alertas.append(
                crear_alerta(
                    "pendiente_validacion",
                    "page_json_no_interpretable",
                    "No se pudo interpretar page.json.",
                    ruta_relativa(page_json, raiz),
                    {"pagina": id_pagina, "error": error},
                )
            )
        else:
            pagina["estado"] = "ok"
        paginas.append(pagina)

    return paginas, nombres_por_id, alertas


def auditar_visuales(
    carpeta_paginas: Path,
    raiz: Path,
    ids_validos: set[str],
    nombres_por_id: dict[str, str],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    """Audita visuales candidatos de navegacion."""
    navegacion: list[dict[str, Any]] = []
    alertas: list[dict[str, Any]] = []

    for visual_json in sorted(carpeta_paginas.glob("*/visuals/**/visual.json"), key=lambda item: item.as_posix().lower()):
        try:
            id_pagina = visual_json.relative_to(carpeta_paginas).parts[0]
        except ValueError:
            id_pagina = visual_json.parts[-4]
        datos, error = leer_json_seguro(visual_json)
        if error:
            if any(palabra in visual_json.as_posix().lower() for palabra in PALABRAS_NAVEGACION):
                alertas.append(
                    crear_alerta(
                        "pendiente_validacion",
                        "visual_json_no_interpretable",
                        "Visual candidato a navegacion no interpretable.",
                        ruta_relativa(visual_json, raiz),
                        {"pagina_origen": id_pagina, "error": error},
                    )
                )
            continue
        if not isinstance(datos, dict) or not es_visual_navegacion(visual_json, datos):
            continue

        tipo_visual = (datos.get("visual") or {}).get("visualType")
        tipo_accion, destino, estado = extraer_accion(datos)
        nombre_visual = datos.get("name") or visual_json.parent.name
        texto = extraer_texto_visual(datos)
        destino_existe = destino in ids_validos if destino else False
        entrada = {
            "pagina_origen_id": id_pagina,
            "pagina_origen": nombres_por_id.get(id_pagina, id_pagina),
            "visual": nombre_visual,
            "ruta": ruta_relativa(visual_json, raiz),
            "texto": texto,
            "tipo_visual": tipo_visual,
            "tipo_accion": tipo_accion,
            "destino_id": destino,
            "destino": nombres_por_id.get(destino, destino) if destino else None,
            "destino_existe": destino_existe,
            "estado": estado,
        }
        navegacion.append(entrada)

        if not destino:
            alertas.append(
                crear_alerta(
                    "media",
                    "navegacion_sin_destino",
                    "Visual de navegacion sin destino identificable.",
                    entrada["ruta"],
                    {"pagina_origen": entrada["pagina_origen"], "visual": nombre_visual},
                )
            )
        elif not destino_existe:
            alertas.append(
                crear_alerta(
                    "alta",
                    "destino_no_existe",
                    "Visual de navegacion apunta a una pagina no detectada.",
                    entrada["ruta"],
                    {"destino_id": destino, "visual": nombre_visual},
                )
            )

    return navegacion, alertas


def alertar_paginas_sin_navegacion(paginas: list[dict[str, Any]], navegacion: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Genera alertas para paginas sin visuales de navegacion detectados."""
    paginas_con_nav = {item["pagina_origen_id"] for item in navegacion}
    alertas = []
    for pagina in paginas:
        if pagina["id"] not in paginas_con_nav:
            alertas.append(
                crear_alerta(
                    "media",
                    "pagina_sin_navegacion_detectada",
                    "No se detectaron visuales de navegacion en la pagina.",
                    pagina["ruta"],
                    {"pagina": pagina["nombre"], "pagina_id": pagina["id"]},
                )
            )
    return alertas


def alertar_duplicados(navegacion: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Detecta rutas de navegacion repetidas por pagina origen y destino."""
    alertas: list[dict[str, Any]] = []
    contador = Counter((item["pagina_origen_id"], item.get("destino_id"), item.get("texto")) for item in navegacion if item.get("destino_id"))
    rutas_por_clave: dict[tuple[str, str | None, str | None], list[str]] = defaultdict(list)
    for item in navegacion:
        clave = (item["pagina_origen_id"], item.get("destino_id"), item.get("texto"))
        rutas_por_clave[clave].append(item["ruta"])

    for clave, cantidad in contador.items():
        if cantidad > 1:
            pagina_id, destino_id, texto = clave
            alertas.append(
                crear_alerta(
                    "baja",
                    "navegacion_duplicada",
                    "Se detectaron visuales de navegacion duplicados para el mismo origen, destino y texto.",
                    rutas_por_clave[clave][0],
                    {
                        "pagina_origen_id": pagina_id,
                        "destino_id": destino_id,
                        "texto": texto,
                        "cantidad": cantidad,
                        "rutas": rutas_por_clave[clave],
                    },
                )
            )
    return alertas


def resumir_alertas(alertas: list[dict[str, Any]]) -> dict[str, int]:
    """Resume alertas por severidad."""
    conteo = Counter(alerta["severidad"] for alerta in alertas)
    return {
        "criticas": conteo["alta"],
        "medias": conteo["media"],
        "bajas": conteo["baja"],
        "pendientes_validacion": conteo["pendiente_validacion"],
    }


def auditar_navegacion(ruta_repo: Path) -> dict[str, Any]:
    """Ejecuta auditoria de navegacion PBIP."""
    raiz = ruta_repo.expanduser().resolve()
    carpeta_reporte = raiz / "PBIP" / "Proyecto.Report"
    carpeta_paginas = carpeta_reporte / "definition" / "pages"
    alertas: list[dict[str, Any]] = []

    ids_pages_json, alertas_pages = cargar_pages_json(carpeta_paginas, raiz)
    alertas.extend(alertas_pages)
    paginas, nombres_por_id, alertas_paginas = cargar_paginas(carpeta_paginas, raiz, ids_pages_json)
    alertas.extend(alertas_paginas)

    ids_validos = set(ids_pages_json) if ids_pages_json else {pagina["id"] for pagina in paginas}
    navegacion, alertas_nav = auditar_visuales(carpeta_paginas, raiz, ids_validos, nombres_por_id)
    alertas.extend(alertas_nav)
    alertas.extend(alertar_paginas_sin_navegacion(paginas, navegacion))
    alertas.extend(alertar_duplicados(navegacion))

    return {
        "repo": raiz.as_posix(),
        "pbip_report": ruta_relativa(carpeta_reporte, raiz),
        "pages_detectadas": len(paginas),
        "visuales_navegacion_detectados": len(navegacion),
        "paginas": paginas,
        "navegacion": navegacion,
        "alertas": alertas,
        "resumen": resumir_alertas(alertas),
    }


def crear_parser() -> argparse.ArgumentParser:
    """Configura argumentos CLI."""
    parser = argparse.ArgumentParser(
        description="Audita navegacion de un proyecto Power BI PBIP y devuelve JSON."
    )
    parser.add_argument("ruta_repo", help="Ruta del repositorio PBIP.")
    parser.add_argument("--pretty", action="store_true", help="Imprime JSON indentado.")
    return parser


def main() -> int:
    """Punto de entrada CLI."""
    parser = crear_parser()
    argumentos = parser.parse_args()
    resultado = auditar_navegacion(Path(argumentos.ruta_repo))
    print(json.dumps(resultado, ensure_ascii=False, indent=2 if argumentos.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
