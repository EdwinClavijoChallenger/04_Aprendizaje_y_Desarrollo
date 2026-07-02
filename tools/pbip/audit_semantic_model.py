#!/usr/bin/env python
"""Audita de forma local el modelo semantico TMDL de un PBIP."""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


SEVERIDADES = {"alta", "media", "baja", "pendiente_validacion"}
PREFIJOS_TABLA = ("Fct_", "Dim_", "Stg_")
PATRON_TECNICO = re.compile(r"^[A-Za-z0-9_ ]+$")
PATRON_TABLE = re.compile(r"^\s*table\s+(.+?)\s*$")
PATRON_COLUMN = re.compile(r"^\s*column\s+(.+?)(?:\s*=|\s*$)")
PATRON_MEASURE = re.compile(r"^\s*measure\s+(.+?)(?:\s*=|\s*$)")
PATRON_RELATIONSHIP = re.compile(r"^\s*relationship\s+(.+?)\s*$")
PATRON_PROPIEDAD = re.compile(r"^\s*([A-Za-z][A-Za-z0-9_]*):\s*(.*?)\s*$")


def ruta_relativa(ruta: Path, raiz: Path) -> str:
    """Devuelve ruta relativa estable."""
    try:
        return ruta.relative_to(raiz).as_posix()
    except ValueError:
        return ruta.as_posix()


def leer_texto_seguro(ruta: Path) -> tuple[str | None, str | None]:
    """Lee un archivo TMDL sin detener toda la auditoria si falla."""
    try:
        return ruta.read_text(encoding="utf-8-sig"), None
    except FileNotFoundError:
        return None, "El archivo no existe."
    except OSError as error:
        return None, f"No se pudo leer: {error}."
    except UnicodeDecodeError as error:
        return None, f"No se pudo decodificar como UTF-8: {error}."


def limpiar_nombre(nombre: str) -> str:
    """Normaliza nombres TMDL quitando comillas externas."""
    nombre = nombre.strip()
    if nombre.startswith("'") and nombre.endswith("'") and len(nombre) >= 2:
        return nombre[1:-1]
    if nombre.startswith('"') and nombre.endswith('"') and len(nombre) >= 2:
        return nombre[1:-1]
    return nombre


def agregar_alerta(
    alertas: list[dict[str, Any]],
    severidad: str,
    tipo: str,
    mensaje: str,
    evidencia: str | None = None,
    elementos: list[str] | None = None,
) -> None:
    """Agrega una alerta normalizada."""
    if severidad not in SEVERIDADES:
        severidad = "pendiente_validacion"
    alerta: dict[str, Any] = {
        "severidad": severidad,
        "tipo": tipo,
        "mensaje": mensaje,
    }
    if evidencia:
        alerta["evidencia"] = evidencia
    if elementos is not None:
        alerta["elementos"] = elementos
    alertas.append(alerta)


def tipo_tabla(nombre: str) -> str:
    """Infiere el tipo de tabla por prefijo o funcion."""
    if nombre.startswith("Fct_"):
        return "Fct_"
    if nombre.startswith("Dim_"):
        return "Dim_"
    if nombre.startswith("Stg_"):
        return "Stg_"
    if nombre.lower().startswith("medidas") or nombre in {"Medidas_AD", "_Medidas"}:
        return "medidas"
    return "otras"


def nombre_problematico(nombre: str) -> bool:
    """Detecta tildes, eñes, mojibake o caracteres tecnicos problemáticos."""
    try:
        nombre.encode("ascii")
    except UnicodeEncodeError:
        return True
    if any(fragmento in nombre for fragmento in ("Ã", "Â", "�")):
        return True
    return not bool(PATRON_TECNICO.fullmatch(nombre))


def extraer_tablas(raiz: Path, definicion: Path, alertas: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    """Extrae tablas, columnas y medidas desde tables/*.tmdl."""
    carpeta_tablas = definicion / "tables"
    tablas: list[dict[str, Any]] = []
    medidas: list[dict[str, Any]] = []

    if not carpeta_tablas.exists():
        agregar_alerta(
            alertas,
            "alta",
            "ruta_faltante",
            "No existe la carpeta tables/ del modelo semantico.",
            ruta_relativa(carpeta_tablas, raiz),
        )
        return tablas, medidas

    for archivo in sorted(carpeta_tablas.glob("*.tmdl"), key=lambda ruta: ruta.name.lower()):
        contenido, error = leer_texto_seguro(archivo)
        if error or contenido is None:
            agregar_alerta(alertas, "pendiente_validacion", "lectura_tmdl", error or "Archivo no interpretable.", ruta_relativa(archivo, raiz))
            continue

        nombre_tabla = archivo.stem
        columnas: list[dict[str, Any]] = []
        medidas_tabla: list[dict[str, Any]] = []
        tabla_oculta = False
        actual: dict[str, Any] | None = None
        tipo_actual: str | None = None

        for numero, linea in enumerate(contenido.splitlines(), start=1):
            match_tabla = PATRON_TABLE.match(linea)
            if match_tabla:
                nombre_tabla = limpiar_nombre(match_tabla.group(1))
                actual = None
                tipo_actual = "table"
                continue

            match_columna = PATRON_COLUMN.match(linea)
            if match_columna:
                actual = {
                    "nombre": limpiar_nombre(match_columna.group(1)),
                    "visible": True,
                    "tipo_dato": None,
                    "linea": numero,
                }
                columnas.append(actual)
                tipo_actual = "column"
                continue

            match_medida = PATRON_MEASURE.match(linea)
            if match_medida:
                actual = {
                    "tabla": nombre_tabla,
                    "nombre": limpiar_nombre(match_medida.group(1)),
                    "displayFolder": None,
                    "linea": numero,
                    "archivo": ruta_relativa(archivo, raiz),
                }
                medidas_tabla.append(actual)
                medidas.append(actual)
                tipo_actual = "measure"
                continue

            texto = linea.strip()
            if texto == "isHidden":
                if tipo_actual == "column" and actual is not None:
                    actual["visible"] = False
                elif tipo_actual == "table":
                    tabla_oculta = True
                continue

            propiedad = PATRON_PROPIEDAD.match(linea)
            if propiedad and actual is not None:
                clave, valor = propiedad.group(1), propiedad.group(2)
                if tipo_actual == "column" and clave == "dataType":
                    actual["tipo_dato"] = valor
                if tipo_actual == "measure" and clave == "displayFolder":
                    actual["displayFolder"] = valor

        tablas.append(
            {
                "nombre": nombre_tabla,
                "tipo": tipo_tabla(nombre_tabla),
                "archivo": ruta_relativa(archivo, raiz),
                "oculta": tabla_oculta,
                "columnas_total": len(columnas),
                "columnas_visibles": sum(1 for columna in columnas if columna["visible"]),
                "columnas_ocultas": sum(1 for columna in columnas if not columna["visible"]),
                "columnas": columnas,
                "medidas_total": len(medidas_tabla),
                "medidas": [medida["nombre"] for medida in medidas_tabla],
            }
        )

    return tablas, medidas


def separar_columna(referencia: str | None) -> tuple[str | None, str | None]:
    """Separa referencias tipo Tabla.Columna."""
    if not referencia or "." not in referencia:
        return None, None
    tabla, columna = referencia.split(".", 1)
    return limpiar_nombre(tabla), limpiar_nombre(columna)


def extraer_relaciones(raiz: Path, definicion: Path, alertas: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Extrae relaciones desde relationships.tmdl."""
    archivo = definicion / "relationships.tmdl"
    relaciones: list[dict[str, Any]] = []
    contenido, error = leer_texto_seguro(archivo)
    if error or contenido is None:
        agregar_alerta(alertas, "alta", "relationships_tmdl", error or "relationships.tmdl no interpretable.", ruta_relativa(archivo, raiz))
        return relaciones

    actual: dict[str, Any] | None = None
    for numero, linea in enumerate(contenido.splitlines(), start=1):
        match_relacion = PATRON_RELATIONSHIP.match(linea)
        if match_relacion:
            if actual is not None:
                relaciones.append(actual)
            actual = {
                "nombre": limpiar_nombre(match_relacion.group(1)),
                "fromColumn": None,
                "toColumn": None,
                "fromTable": None,
                "toTable": None,
                "fromColumnName": None,
                "toColumnName": None,
                "activa": True,
                "cardinalidad": None,
                "crossFilteringBehavior": None,
                "linea": numero,
                "archivo": ruta_relativa(archivo, raiz),
            }
            continue

        if actual is None:
            continue

        propiedad = PATRON_PROPIEDAD.match(linea)
        if not propiedad:
            continue
        clave, valor = propiedad.group(1), propiedad.group(2)
        if clave == "fromColumn":
            actual["fromColumn"] = valor
            actual["fromTable"], actual["fromColumnName"] = separar_columna(valor)
        elif clave == "toColumn":
            actual["toColumn"] = valor
            actual["toTable"], actual["toColumnName"] = separar_columna(valor)
        elif clave in {"isActive", "active"}:
            actual["activa"] = valor.lower() not in {"false", "0"}
        elif clave in {"cardinality", "fromCardinality", "toCardinality"}:
            actual["cardinalidad"] = valor if actual["cardinalidad"] is None else f"{actual['cardinalidad']} | {clave}:{valor}"
        elif clave == "crossFilteringBehavior":
            actual["crossFilteringBehavior"] = valor

    if actual is not None:
        relaciones.append(actual)
    return relaciones


def validar_modelo(
    raiz: Path,
    definicion: Path,
    tablas: list[dict[str, Any]],
    relaciones: list[dict[str, Any]],
    medidas: list[dict[str, Any]],
    alertas: list[dict[str, Any]],
) -> None:
    """Genera alertas de gobierno del modelo."""
    tablas_por_nombre = {tabla["nombre"]: tabla for tabla in tablas}
    columnas_por_tabla = {
        tabla["nombre"]: {columna["nombre"] for columna in tabla["columnas"]}
        for tabla in tablas
    }

    for requerido in ("model.tmdl", "relationships.tmdl"):
        ruta = definicion / requerido
        if not ruta.exists():
            agregar_alerta(alertas, "alta", "archivo_faltante", f"No existe {requerido}.", ruta_relativa(ruta, raiz))

    expressions = definicion / "expressions.tmdl"
    if not expressions.exists():
        agregar_alerta(alertas, "baja", "archivo_opcional_faltante", "No existe expressions.tmdl.", ruta_relativa(expressions, raiz))

    roles = definicion / "roles"
    if not roles.exists():
        agregar_alerta(alertas, "baja", "roles_no_detectados", "No existe carpeta roles/; validar si el modelo no requiere RLS.", ruta_relativa(roles, raiz))

    cultures = definicion / "cultures"
    if not cultures.exists():
        agregar_alerta(alertas, "baja", "cultures_no_detectado", "No existe carpeta cultures/.", ruta_relativa(cultures, raiz))

    tablas_sin_prefijo = [
        tabla["nombre"]
        for tabla in tablas
        if tabla["tipo"] == "otras"
    ]
    if tablas_sin_prefijo:
        agregar_alerta(
            alertas,
            "media",
            "tablas_sin_prefijo",
            "Hay tablas sin prefijo Fct_, Dim_, Stg_ o tabla de medidas reconocida.",
            elementos=tablas_sin_prefijo[:20],
        )

    tablas_relacionadas = set()
    relaciones_sin_cardinalidad: list[str] = []
    relaciones_columnas_invalidas: list[str] = []
    pares = Counter()

    for relacion in relaciones:
        from_table = relacion.get("fromTable")
        to_table = relacion.get("toTable")
        from_column = relacion.get("fromColumnName")
        to_column = relacion.get("toColumnName")

        if from_table:
            tablas_relacionadas.add(from_table)
        if to_table:
            tablas_relacionadas.add(to_table)
        if from_table and to_table:
            pares[tuple(sorted((from_table, to_table)))] += 1
        if relacion.get("cardinalidad") is None:
            relaciones_sin_cardinalidad.append(relacion["nombre"])
        if from_table not in tablas_por_nombre or to_table not in tablas_por_nombre:
            relaciones_columnas_invalidas.append(relacion["nombre"])
            continue
        if from_column not in columnas_por_tabla.get(from_table, set()):
            relaciones_columnas_invalidas.append(f"{relacion['nombre']} ({relacion.get('fromColumn')})")
        if to_column not in columnas_por_tabla.get(to_table, set()):
            relaciones_columnas_invalidas.append(f"{relacion['nombre']} ({relacion.get('toColumn')})")

    if relaciones_sin_cardinalidad:
        agregar_alerta(
            alertas,
            "pendiente_validacion",
            "relaciones_sin_cardinalidad",
            "Hay relaciones sin cardinalidad explicita en TMDL; Power BI puede inferirla, pero la tool no la confirma.",
            elementos=relaciones_sin_cardinalidad[:20],
        )

    if relaciones_columnas_invalidas:
        agregar_alerta(
            alertas,
            "alta",
            "relaciones_columnas_no_encontradas",
            "Hay relaciones con tabla o columna no encontrada en tables/*.tmdl.",
            elementos=relaciones_columnas_invalidas[:20],
        )

    duplicados = [
        f"{par[0]} <-> {par[1]} ({conteo})"
        for par, conteo in pares.items()
        if conteo > 1
    ]
    if duplicados:
        agregar_alerta(
            alertas,
            "media",
            "multiples_relaciones_tablas",
            "Hay multiples relaciones entre los mismos pares de tablas; validar intencionalidad.",
            elementos=duplicados[:20],
        )

    hechos_sin_relacion = [
        tabla["nombre"]
        for tabla in tablas
        if tabla["tipo"] == "Fct_" and tabla["nombre"] not in tablas_relacionadas
    ]
    dimensiones_sin_relacion = [
        tabla["nombre"]
        for tabla in tablas
        if tabla["tipo"] == "Dim_" and tabla["nombre"] not in tablas_relacionadas
    ]
    if hechos_sin_relacion:
        agregar_alerta(alertas, "media", "hechos_sin_relacion", "Hay hechos sin relacion detectada.", elementos=hechos_sin_relacion)
    if dimensiones_sin_relacion:
        agregar_alerta(alertas, "media", "dimensiones_sin_relacion", "Hay dimensiones sin relacion detectada.", elementos=dimensiones_sin_relacion)

    medidas_fuera = sorted({medida["tabla"] for medida in medidas if tipo_tabla(medida["tabla"]) != "medidas"})
    if medidas_fuera:
        agregar_alerta(
            alertas,
            "media",
            "medidas_fuera_tabla_medidas",
            "Hay medidas definidas fuera de una tabla de medidas reconocida.",
            elementos=medidas_fuera,
        )

    nombres_problematicos: list[str] = []
    for tabla in tablas:
        if nombre_problematico(tabla["nombre"]):
            nombres_problematicos.append(f"tabla:{tabla['nombre']}")
        for columna in tabla["columnas"]:
            if nombre_problematico(columna["nombre"]):
                nombres_problematicos.append(f"columna:{tabla['nombre']}[{columna['nombre']}]")
    for medida in medidas:
        if nombre_problematico(medida["nombre"]):
            nombres_problematicos.append(f"medida:{medida['tabla']}[{medida['nombre']}]")

    if nombres_problematicos:
        agregar_alerta(
            alertas,
            "media",
            "nombres_tecnicos_problematicos",
            "Se detectaron nombres con tildes, eñes, mojibake, espacios especiales o caracteres no recomendados.",
            elementos=nombres_problematicos[:30],
        )


def construir_resumen(tablas: list[dict[str, Any]], relaciones: list[dict[str, Any]], medidas: list[dict[str, Any]], alertas: list[dict[str, Any]]) -> dict[str, int]:
    """Calcula conteos principales."""
    conteo_alertas = Counter(alerta["severidad"] for alerta in alertas)
    return {
        "tablas_total": len(tablas),
        "hechos": sum(1 for tabla in tablas if tabla["tipo"] == "Fct_"),
        "dimensiones": sum(1 for tabla in tablas if tabla["tipo"] == "Dim_"),
        "staging": sum(1 for tabla in tablas if tabla["tipo"] == "Stg_"),
        "medidas_total": len(medidas),
        "relaciones_total": len(relaciones),
        "alertas_altas": conteo_alertas["alta"],
        "alertas_medias": conteo_alertas["media"],
        "alertas_bajas": conteo_alertas["baja"],
        "pendientes_validacion": conteo_alertas["pendiente_validacion"],
    }


def auditar_modelo(ruta_repo: Path) -> dict[str, Any]:
    """Audita el modelo semantico del PBIP."""
    raiz = ruta_repo.expanduser().resolve()
    definicion = raiz / "PBIP" / "Proyecto.SemanticModel" / "definition"
    alertas: list[dict[str, Any]] = []

    if not definicion.exists():
        agregar_alerta(
            alertas,
            "alta",
            "ruta_faltante",
            "No existe PBIP/Proyecto.SemanticModel/definition/.",
            ruta_relativa(definicion, raiz),
        )
        return {
            "repo": raiz.as_posix(),
            "semantic_model_path": ruta_relativa(definicion, raiz),
            "tablas": [],
            "relaciones": [],
            "medidas": [],
            "alertas": alertas,
            "resumen": construir_resumen([], [], [], alertas),
        }

    tablas, medidas = extraer_tablas(raiz, definicion, alertas)
    relaciones = extraer_relaciones(raiz, definicion, alertas)
    validar_modelo(raiz, definicion, tablas, relaciones, medidas, alertas)

    return {
        "repo": raiz.as_posix(),
        "semantic_model_path": ruta_relativa(definicion, raiz),
        "tablas": tablas,
        "relaciones": relaciones,
        "medidas": medidas,
        "alertas": alertas,
        "resumen": construir_resumen(tablas, relaciones, medidas, alertas),
    }


def crear_parser() -> argparse.ArgumentParser:
    """Define argumentos CLI."""
    parser = argparse.ArgumentParser(
        description="Audita el modelo semantico TMDL de un proyecto PBIP y devuelve JSON."
    )
    parser.add_argument("ruta_repo", help="Ruta del repositorio a revisar.")
    parser.add_argument("--pretty", action="store_true", help="Imprime JSON indentado.")
    return parser


def main() -> int:
    """Punto de entrada."""
    parser = crear_parser()
    argumentos = parser.parse_args()
    resultado = auditar_modelo(Path(argumentos.ruta_repo))
    print(json.dumps(resultado, ensure_ascii=False, indent=2 if argumentos.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
