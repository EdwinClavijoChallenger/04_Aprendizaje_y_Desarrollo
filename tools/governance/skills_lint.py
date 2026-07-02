#!/usr/bin/env python
"""Valida el gobierno local de skills del proyecto."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any


RAICES_SKILLS = {
    "oficial": ".agents/skills",
    "codex_local": ".codex/skills",
    "legacy": "Skills",
}

REFERENCIAS_LEGACY = [
    "tools/list_pbip_structure.py",
    "tools/prepare_commit_review.py",
    "Skills/",
]

PATRON_NOMBRE_TECNICO = re.compile(r"^[a-z0-9][a-z0-9_-]*$")
PATRON_TOOL = re.compile(r"(tools/[A-Za-z0-9_./-]+\.py)")


def ruta_relativa(ruta: Path, raiz: Path) -> str:
    """Devuelve una ruta relativa con separadores estables."""
    try:
        return ruta.relative_to(raiz).as_posix()
    except ValueError:
        return ruta.as_posix()


def leer_texto_seguro(ruta: Path) -> tuple[str | None, str | None]:
    """Lee un archivo de texto sin detener toda la ejecucion si falla."""
    try:
        return ruta.read_text(encoding="utf-8-sig"), None
    except FileNotFoundError:
        return None, "El archivo no existe."
    except OSError as error:
        return None, f"No se pudo leer el archivo: {error}."
    except UnicodeDecodeError as error:
        return None, f"No se pudo decodificar como UTF-8: {error}."


def parsear_front_matter(contenido: str) -> tuple[dict[str, str], str | None]:
    """Parsea front matter YAML simple con claves escalares."""
    lineas = contenido.splitlines()
    if not lineas or lineas[0].strip() != "---":
        return {}, "No se encontro front matter YAML inicial."

    cierre = None
    for indice, linea in enumerate(lineas[1:], start=1):
        if linea.strip() == "---":
            cierre = indice
            break

    if cierre is None:
        return {}, "El front matter YAML no tiene cierre."

    datos: dict[str, str] = {}
    for numero, linea in enumerate(lineas[1:cierre], start=2):
        texto = linea.strip()
        if not texto or texto.startswith("#"):
            continue
        if ":" not in texto:
            return datos, f"Linea YAML no interpretable en linea {numero}."
        clave, valor = texto.split(":", 1)
        clave = clave.strip()
        valor = valor.strip().strip('"').strip("'")
        if not clave:
            return datos, f"Clave YAML vacia en linea {numero}."
        datos[clave] = valor

    return datos, None


def nombre_tecnico_valido(nombre: str | None) -> bool:
    """Valida nombres tecnicos ASCII sin tildes ni caracteres problematicos."""
    if not nombre:
        return False
    try:
        nombre.encode("ascii")
    except UnicodeEncodeError:
        return False
    return bool(PATRON_NOMBRE_TECNICO.fullmatch(nombre))


def listar_skill_md(raiz: Path, carpeta_relativa: str) -> list[Path]:
    """Lista SKILL.md dentro de una raiz de skills sin fallar si no existe."""
    carpeta = raiz / carpeta_relativa
    if not carpeta.exists() or not carpeta.is_dir():
        return []
    return sorted(carpeta.glob("*/SKILL.md"), key=lambda ruta: ruta.as_posix().lower())


def detectar_referencias_tools(contenido: str, raiz: Path) -> list[dict[str, Any]]:
    """Detecta rutas tools/*.py mencionadas en una skill y valida existencia."""
    referencias: list[dict[str, Any]] = []
    vistas: set[str] = set()
    for coincidencia in PATRON_TOOL.finditer(contenido.replace("\\", "/")):
        ruta = coincidencia.group(1).rstrip("`.,);")
        if ruta in vistas:
            continue
        vistas.add(ruta)
        referencias.append(
            {
                "ruta": ruta,
                "existe": (raiz / ruta).exists(),
            }
        )
    return referencias


def detectar_referencias_legacy(contenido: str, ruta_skill: Path, raiz: Path) -> list[dict[str, str]]:
    """Busca referencias a rutas legacy dentro de una skill."""
    hallazgos: list[dict[str, str]] = []
    for patron in REFERENCIAS_LEGACY:
        if patron in contenido:
            hallazgos.append(
                {
                    "ruta_skill": ruta_relativa(ruta_skill, raiz),
                    "referencia": patron,
                    "motivo": "Referencia legacy encontrada en SKILL.md.",
                }
            )
    return hallazgos


def evaluar_skill(ruta_skill: Path, raiz: Path, ubicacion: str) -> dict[str, Any]:
    """Evalua una skill individual."""
    contenido, error_lectura = leer_texto_seguro(ruta_skill)
    nombre_carpeta = ruta_skill.parent.name
    alertas: list[str] = []

    front_matter: dict[str, str] = {}
    error_front_matter: str | None = None
    referencias_tools: list[dict[str, Any]] = []
    referencias_legacy: list[dict[str, str]] = []

    if error_lectura:
        alertas.append(error_lectura)
    elif contenido is not None:
        front_matter, error_front_matter = parsear_front_matter(contenido)
        if error_front_matter:
            alertas.append(error_front_matter)
        referencias_tools = detectar_referencias_tools(contenido, raiz)
        referencias_legacy = detectar_referencias_legacy(contenido, ruta_skill, raiz)

    nombre = front_matter.get("name")
    descripcion = front_matter.get("description")

    if ubicacion != "oficial":
        alertas.append("La skill no esta en la ubicacion oficial .agents/skills/.")
    if not nombre:
        alertas.append("Falta name en front matter.")
    if not descripcion:
        alertas.append("Falta description en front matter o esta vacia.")
    if nombre and not nombre_tecnico_valido(nombre):
        alertas.append("El name tiene tildes, espacios o caracteres tecnicos no permitidos.")
    if not nombre_tecnico_valido(nombre_carpeta):
        alertas.append("La carpeta de la skill tiene caracteres tecnicos no permitidos.")

    for referencia in referencias_tools:
        if not referencia["existe"]:
            alertas.append(f"La tool referenciada no existe: {referencia['ruta']}.")

    return {
        "ubicacion": ubicacion,
        "ruta": ruta_relativa(ruta_skill, raiz),
        "carpeta": nombre_carpeta,
        "name": nombre,
        "description": descripcion,
        "front_matter_valido": error_front_matter is None and bool(nombre) and bool(descripcion),
        "nombre_tecnico_valido": nombre_tecnico_valido(nombre) if nombre else False,
        "descripcion_valida": bool(descripcion),
        "referencias_tools": referencias_tools,
        "referencias_legacy": referencias_legacy,
        "alertas": alertas,
        "valida": ubicacion == "oficial" and not alertas,
    }


def detectar_duplicados(skills: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Detecta skills duplicadas por name o carpeta entre raices."""
    indice: dict[str, list[dict[str, Any]]] = {}
    for skill in skills:
        claves = {f"name:{skill.get('name')}" if skill.get("name") else None, f"carpeta:{skill.get('carpeta')}"}
        for clave in claves:
            if clave:
                indice.setdefault(clave, []).append(skill)

    duplicados: list[dict[str, Any]] = []
    for clave, elementos in sorted(indice.items()):
        ubicaciones = {elemento["ubicacion"] for elemento in elementos}
        if len(elementos) > 1 and len(ubicaciones) > 1:
            duplicados.append(
                {
                    "clave": clave,
                    "rutas": [elemento["ruta"] for elemento in elementos],
                    "ubicaciones": sorted(ubicaciones),
                    "motivo": "La misma skill aparece en ubicaciones distintas.",
                }
            )
    return duplicados


def inspeccionar_skills(ruta_repo: Path) -> dict[str, Any]:
    """Construye la salida JSON de gobierno de skills."""
    raiz = ruta_repo.expanduser().resolve()
    skills: list[dict[str, Any]] = []
    advertencias_raices: list[dict[str, Any]] = []

    for ubicacion, carpeta_relativa in RAICES_SKILLS.items():
        carpeta = raiz / carpeta_relativa
        existe = carpeta.exists()
        tiene_skills = bool(listar_skill_md(raiz, carpeta_relativa))
        advertencia = None
        if ubicacion == "legacy" and existe:
            advertencia = "Skills/ existe y debe tratarse como legacy."
        if ubicacion == "codex_local" and tiene_skills:
            advertencia = ".codex/skills/ tiene skills locales; no es ubicacion oficial del proyecto."
        advertencias_raices.append(
            {
                "ubicacion": ubicacion,
                "ruta": carpeta_relativa,
                "existe": existe,
                "tiene_skills": tiene_skills,
                "advertencia": advertencia,
            }
        )

        for ruta_skill in listar_skill_md(raiz, carpeta_relativa):
            skills.append(evaluar_skill(ruta_skill, raiz, ubicacion))

    duplicados = detectar_duplicados(skills)
    referencias_legacy = [
        referencia
        for skill in skills
        for referencia in skill.get("referencias_legacy", [])
    ]

    for duplicado in duplicados:
        for skill in skills:
            if skill["ruta"] in duplicado["rutas"]:
                skill["alertas"].append(duplicado["motivo"])
                skill["valida"] = False

    skills_validas = [skill for skill in skills if skill["valida"]]
    skills_con_alertas = [skill for skill in skills if skill["alertas"]]

    return {
        "repo": raiz.as_posix(),
        "raices_revisadas": advertencias_raices,
        "skills_detectadas": skills,
        "skills_validas": skills_validas,
        "skills_con_alertas": skills_con_alertas,
        "duplicados": duplicados,
        "referencias_legacy": referencias_legacy,
        "resumen": {
            "total_skills": len(skills),
            "validas": len(skills_validas),
            "alertas": len(skills_con_alertas),
            "duplicados": len(duplicados),
            "referencias_legacy": len(referencias_legacy),
        },
    }


def crear_parser() -> argparse.ArgumentParser:
    """Define argumentos de linea de comandos."""
    parser = argparse.ArgumentParser(
        description="Valida gobierno de skills locales y devuelve JSON."
    )
    parser.add_argument("ruta_repo", help="Ruta del repositorio a revisar.")
    parser.add_argument("--pretty", action="store_true", help="Imprime JSON indentado.")
    return parser


def main() -> int:
    """Punto de entrada CLI."""
    parser = crear_parser()
    argumentos = parser.parse_args()
    resultado = inspeccionar_skills(Path(argumentos.ruta_repo))
    print(json.dumps(resultado, ensure_ascii=False, indent=2 if argumentos.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
