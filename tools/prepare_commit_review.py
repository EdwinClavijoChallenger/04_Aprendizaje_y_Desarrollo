#!/usr/bin/env python
"""Prepara evidencia JSON para commits controlados del proyecto."""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path
from typing import Any


DOCUMENTOS_GOBIERNO = [
    "README.md",
    "AGENTS.md",
    "Docs/PROJECT_CONTEXT.md",
    "Docs/AI_INSTRUCTIONS.md",
    "Docs/COMMIT_GUIDELINES.md",
    "Docs/FOLDER_STRUCTURE.md",
    "Docs/BRAND_GUIDELINES.md",
    "Docs/DATA_MODEL.md",
]


def ejecutar_git(argumentos: list[str], raiz: Path) -> dict[str, Any]:
    """Ejecuta un comando git de solo lectura y captura errores."""
    comando = ["git", *argumentos]
    try:
        proceso = subprocess.run(
            comando,
            cwd=raiz,
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        return {
            "comando": " ".join(comando),
            "codigo_salida": proceso.returncode,
            "stdout": proceso.stdout.rstrip(),
            "stderr": proceso.stderr.rstrip(),
            "ok": proceso.returncode == 0,
        }
    except OSError as error:
        return {
            "comando": " ".join(comando),
            "codigo_salida": None,
            "stdout": "",
            "stderr": f"No se pudo ejecutar git: {error}",
            "ok": False,
        }


def obtener_rama(status_sb: str) -> dict[str, Any]:
    """Extrae rama y sincronizacion basica desde git status -sb."""
    primera_linea = status_sb.splitlines()[0] if status_sb else ""
    rama = None
    upstream = None
    sincronizacion = "sin_datos"

    if primera_linea.startswith("## "):
        contenido = primera_linea[3:]
        if "..." in contenido:
            rama, resto = contenido.split("...", 1)
            if " " in resto:
                upstream, marcas = resto.split(" ", 1)
                sincronizacion = marcas.strip("[]")
            else:
                upstream = resto
                sincronizacion = "sin_diferencias_reportadas"
        else:
            rama = contenido

    return {
        "rama_actual": rama,
        "upstream": upstream,
        "sincronizacion": sincronizacion,
        "linea_estado": primera_linea,
    }


def normalizar_ruta(ruta: str) -> str:
    """Normaliza separadores para clasificacion estable."""
    return ruta.strip().replace("\\", "/")


def bloque_archivo(ruta: str) -> str:
    """Clasifica una ruta por bloque funcional del proyecto."""
    ruta = normalizar_ruta(ruta)
    if ruta.startswith("PBIP/Proyecto.Report/"):
        return "PBIP Report"
    if ruta.startswith("PBIP/Proyecto.SemanticModel/"):
        return "PBIP SemanticModel"
    if ruta.startswith("Docs/") or ruta == "README.md" or ruta == "AGENTS.md":
        return "Docs"
    if ruta.startswith("Outputs/"):
        return "Outputs"
    if ruta.startswith("Skills/") or ruta.startswith("skills/"):
        return "Skills"
    if ruta.startswith("tools/"):
        return "tools"
    if ruta.startswith("contracts/"):
        return "contracts"
    if ruta.startswith(".codex/"):
        return ".codex"
    if ruta.startswith("Data/") or ruta.startswith("data/") or "tmp" in ruta.lower() or "temp" in ruta.lower():
        return "temporales"
    return "otros"


def es_excluido_por_defecto(ruta: str, incluir_outputs: bool) -> tuple[bool, str | None]:
    """Indica si una ruta deberia excluirse por defecto del commit."""
    bloque = bloque_archivo(ruta)
    if bloque == "Outputs" and not incluir_outputs:
        return True, "Outputs se excluye por defecto salvo autorizacion explicita."
    if bloque in {".codex", "contracts", "temporales"}:
        return True, f"{bloque} se excluye por defecto salvo instruccion explicita."
    return False, None


def parsear_status_short(texto: str) -> dict[str, Any]:
    """Clasifica archivos usando la salida de git status --short."""
    clasificacion: dict[str, Any] = {
        "modificados": [],
        "nuevos": [],
        "eliminados": [],
        "renombrados": [],
        "staged": [],
        "untracked": [],
        "todos": [],
    }

    for linea in texto.splitlines():
        if not linea:
            continue
        estado = linea[:2]
        ruta_original = linea[3:] if len(linea) > 3 else ""
        ruta = normalizar_ruta(ruta_original)
        if " -> " in ruta:
            ruta = ruta.split(" -> ", 1)[1]
        entrada = {"estado": estado, "ruta": ruta, "bloque": bloque_archivo(ruta)}
        clasificacion["todos"].append(entrada)

        indice, trabajo = estado[0], estado[1]
        if estado == "??":
            clasificacion["untracked"].append(entrada)
            clasificacion["nuevos"].append(entrada)
            continue
        if indice != " ":
            clasificacion["staged"].append(entrada)
        if "M" in estado:
            clasificacion["modificados"].append(entrada)
        if "A" in estado:
            clasificacion["nuevos"].append(entrada)
        if "D" in estado:
            clasificacion["eliminados"].append(entrada)
        if "R" in estado:
            clasificacion["renombrados"].append(entrada)
        if trabajo == "?" and entrada not in clasificacion["untracked"]:
            clasificacion["untracked"].append(entrada)

    return clasificacion


def agrupar_por_bloque(archivos: list[dict[str, Any]]) -> dict[str, list[str]]:
    """Agrupa rutas por bloque."""
    bloques: dict[str, list[str]] = {}
    for archivo in archivos:
        bloque = archivo["bloque"]
        bloques.setdefault(bloque, []).append(archivo["ruta"])
    return bloques


def documentos_a_revisar(archivos: list[dict[str, Any]]) -> list[dict[str, str]]:
    """Sugiere documentacion de gobierno segun los cambios detectados."""
    sugerencias: dict[str, str] = {}

    for archivo in archivos:
        ruta = archivo["ruta"]
        if ruta.startswith("PBIP/Proyecto.SemanticModel/"):
            sugerencias["Docs/DATA_MODEL.md"] = "Cambio en modelo semantico."
        if ruta.startswith("PBIP/Proyecto.Report/") and "/visuals/" in ruta:
            sugerencias["Docs/BRAND_GUIDELINES.md"] = "Cambio visual del reporte."
            sugerencias["Docs/PROJECT_CONTEXT.md"] = "Cambio visual o funcional del reporte."
        if ruta.startswith("tools/") or ruta.startswith("Skills/") or ruta.startswith("skills/"):
            sugerencias["Docs/FOLDER_STRUCTURE.md"] = "Cambio en herramientas o skills locales."
            sugerencias["Docs/AI_INSTRUCTIONS.md"] = "Cambio en flujos asistidos por IA."
        if ruta == "Docs/COMMIT_GUIDELINES.md":
            sugerencias["Docs/COMMIT_GUIDELINES.md"] = "Cambio en reglas de commit."

    return [{"documento": doc, "motivo": motivo} for doc, motivo in sorted(sugerencias.items())]


def sugerir_commit(archivos: list[dict[str, Any]], scope: str | None) -> dict[str, Any]:
    """Sugiere tipo, alcance y texto de commit."""
    bloques = {archivo["bloque"] for archivo in archivos}
    rutas = [archivo["ruta"] for archivo in archivos]

    tipo = "chore"
    alcance = scope

    if any(ruta.startswith("Docs/") for ruta in rutas) and not any(
        ruta.startswith(("PBIP/", "tools/", "Skills/", "skills/")) for ruta in rutas
    ):
        tipo = "docs"
        alcance = alcance or "docs"
    elif any(ruta.startswith("PBIP/Proyecto.SemanticModel/") for ruta in rutas):
        tipo = "fix" if any("correccion" in ruta.lower() for ruta in rutas) else "feat"
        alcance = alcance or "model"
    elif any(ruta.startswith("PBIP/Proyecto.Report/") for ruta in rutas):
        tipo = "fix" if any("visual" in ruta.lower() for ruta in rutas) else "feat"
        alcance = alcance or "visuals"
    elif "tools" in bloques or "Skills" in bloques:
        tipo = "chore"
        alcance = alcance or "tools"
    else:
        alcance = alcance or "pbip"

    descripcion = "prepara cambios controlados del proyecto"
    if "tools" in bloques and "Skills" in bloques:
        descripcion = "agrega preparacion controlada de commits"
    elif "PBIP Report" in bloques:
        descripcion = "actualiza visuales del reporte"
    elif "PBIP SemanticModel" in bloques:
        descripcion = "actualiza modelo semantico"
    elif "Docs" in bloques:
        descripcion = "actualiza documentacion del proyecto"

    cuerpo = [
        "- Resume archivos modificados, nuevos, eliminados y staged.",
        "- Clasifica cambios por bloque del proyecto.",
        "- Sugiere documentos de gobierno a revisar.",
        "- Mantiene staging, commit y push bajo autorizacion explicita.",
    ]

    return {
        "tipo": tipo,
        "alcance": alcance,
        "mensaje": f"{tipo}({alcance}): {descripcion}",
        "cuerpo": cuerpo,
    }


def construir_staging_sugerido(archivos: list[dict[str, Any]], incluir_outputs: bool) -> list[str]:
    """Construye comandos de staging explicitos por rutas no excluidas."""
    rutas: list[str] = []
    for archivo in archivos:
        excluido, _ = es_excluido_por_defecto(archivo["ruta"], incluir_outputs)
        if not excluido and archivo["ruta"] not in rutas:
            rutas.append(archivo["ruta"])

    if not rutas:
        return []
    rutas_citadas = " ".join(f'"{ruta}"' for ruta in rutas)
    return [f"git add -- {rutas_citadas}"]


def preparar_revision(raiz: Path, incluir_outputs: bool, scope: str | None) -> dict[str, Any]:
    """Genera la evidencia completa para preparar un commit."""
    raiz = raiz.expanduser().resolve()
    errores: list[str] = []

    comandos = {
        "status_short": ejecutar_git(["status", "--short"], raiz),
        "status_sb": ejecutar_git(["status", "-sb"], raiz),
        "diff_name_status": ejecutar_git(["diff", "--name-status"], raiz),
        "diff_stat": ejecutar_git(["diff", "--stat"], raiz),
        "diff_check": ejecutar_git(["diff", "--check"], raiz),
        "cached_name_status": ejecutar_git(["diff", "--cached", "--name-status"], raiz),
        "log_origin_main": ejecutar_git(["log", "--oneline", "origin/main..HEAD"], raiz),
    }

    for nombre, resultado in comandos.items():
        if not resultado["ok"] and nombre != "log_origin_main":
            errores.append(f"{nombre}: {resultado['stderr']}")

    clasificacion = parsear_status_short(comandos["status_short"]["stdout"])
    todos = clasificacion["todos"]

    excluidos = []
    for archivo in todos:
        excluir, motivo = es_excluido_por_defecto(archivo["ruta"], incluir_outputs)
        if excluir:
            excluidos.append({**archivo, "motivo": motivo})

    riesgos = []
    if clasificacion["staged"]:
        riesgos.append("Hay archivos en staging; revisar antes de preparar otro commit.")
    if comandos["diff_check"]["codigo_salida"] not in (0, None):
        riesgos.append("git diff --check reporto posibles problemas de whitespace.")
    if any(archivo["bloque"].startswith("PBIP") for archivo in todos) and any(
        archivo["bloque"] in {"tools", "Skills"} for archivo in todos
    ):
        riesgos.append("Hay cambios PBIP y tools/Skills simultaneos; considerar commits separados.")
    if excluidos:
        riesgos.append("Hay archivos excluidos por defecto que requieren autorizacion explicita para incluirse.")
    if not comandos["log_origin_main"]["ok"]:
        riesgos.append("No se pudo comparar contra origin/main; validar remoto o rama base.")

    sugerencia_commit = sugerir_commit(todos, scope)

    return {
        "proyecto": str(raiz),
        "rama": obtener_rama(comandos["status_sb"]["stdout"]),
        "sincronizacion_origin_main": {
            "comando": comandos["log_origin_main"]["comando"],
            "ok": comandos["log_origin_main"]["ok"],
            "commits_locales": comandos["log_origin_main"]["stdout"].splitlines()
            if comandos["log_origin_main"]["stdout"]
            else [],
            "error": comandos["log_origin_main"]["stderr"] or None,
        },
        "archivos_modificados": clasificacion["modificados"],
        "archivos_nuevos": clasificacion["nuevos"],
        "archivos_eliminados": clasificacion["eliminados"],
        "archivos_renombrados": clasificacion["renombrados"],
        "archivos_staged": clasificacion["staged"],
        "archivos_untracked": clasificacion["untracked"],
        "archivos_por_bloque": agrupar_por_bloque(todos),
        "archivos_excluidos_sugeridos": excluidos,
        "documentos_a_revisar": documentos_a_revisar(todos),
        "documentos_gobierno": DOCUMENTOS_GOBIERNO,
        "riesgos": riesgos,
        "mensaje_commit_sugerido": sugerencia_commit["mensaje"],
        "cuerpo_commit_sugerido": sugerencia_commit["cuerpo"],
        "comandos_staging_explicito_sugeridos": construir_staging_sugerido(todos, incluir_outputs),
        "advertencia": "No ejecutar staging, commit ni push sin autorizacion explicita del usuario. No usar git add .",
        "evidencia_git": comandos,
        "errores": errores,
    }


def crear_parser() -> argparse.ArgumentParser:
    """Define argumentos de linea de comandos."""
    parser = argparse.ArgumentParser(
        description="Genera evidencia JSON para preparar commits controlados."
    )
    parser.add_argument("ruta_proyecto", help="Ruta del repositorio a revisar.")
    parser.add_argument("--pretty", action="store_true", help="Imprime JSON indentado.")
    parser.add_argument(
        "--include-output-files",
        action="store_true",
        help="No excluir Outputs por defecto en las sugerencias.",
    )
    parser.add_argument("--scope", help="Alcance sugerido para Conventional Commit.")
    return parser


def main() -> int:
    """Punto de entrada CLI."""
    parser = crear_parser()
    argumentos = parser.parse_args()
    resultado = preparar_revision(
        Path(argumentos.ruta_proyecto),
        incluir_outputs=argumentos.include_output_files,
        scope=argumentos.scope,
    )
    print(json.dumps(resultado, ensure_ascii=False, indent=2 if argumentos.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
