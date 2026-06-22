# AGENTS.md

This file provides guidance to Codex and Claude Code when working in this repository.

## Descripción del proyecto

Dashboard Power BI en formato PBIP para analítica de desarrollo organizacional (Grupo LEMCO). Cuatro bloques estratégicos: **Aprendizaje** (MVP completo), **Desarrollo** (PDI iniciado), **Bienestar y Clima** (entrevistas de retiro y plan de bienestar iniciados) y **Desempeño** (en construcción con páginas `DS01` a `DS06`). El público objetivo es gerencial — priorizar legibilidad ejecutiva sobre completitud descriptiva.

El archivo principal actual es `PBIP/Proyecto4.pbip`. Se abre desde Power BI Desktop con Archivo > Abrir > Proyecto4.pbip.

## Carpetas no versionadas

`Data/`, `backups_codex/` y `Outputs/` están excluidas de git. `Outputs/` es para borradores generados por IA y nunca es fuente oficial salvo aprobación explícita.

## Trabajo sobre el PBIP

**Antes de cualquier edición:** ejecutar `git status` para revisar el estado actual. Si Power BI Desktop está abierto, asumir que el usuario puede tener cambios manuales sin guardar — no sobrescribirlos.

**Codificación de archivos:** los archivos JSON y TMDL deben estar en UTF-8 sin BOM. Tras editar un TMDL manualmente, verificar artefactos de doble codificación (`Ã©`, `Ã³`, `Â¿`) que aparecen cuando se usó un editor Latin-1.

**Estructura de medidas TMDL:** `displayFolder` y `lineageTag` deben estar a 2 tabs (nivel de propiedad). A 3 tabs o más quedan dentro del cuerpo DAX y Power BI Desktop falla al parsear la medida.

**Archivos JSON de páginas:** validar que el JSON parsee correctamente después de cada edición manual.

**Alcance de los cambios:** preferir ediciones puntuales sobre regeneración masiva. Nunca reconstruir páginas, resetear el reporte ni reaplicar branding completo sin autorización explícita del usuario.

## Convención de nombres de páginas

| Prefijo | Frente |
|---|---|
| `00` | Inicio Corporativo (home corporativo, punto de entrada) |
| `A##` | Aprendizaje |
| `D##` | Desarrollo |
| `BC##` | Bienestar y Clima |
| `DS##` | Desempeño |

Cada página nueva debe incorporarse al menú de navegación, al home corporativo o a un acceso secundario documentado. No dejar páginas sin ruta de acceso clara para el usuario final.

## Reglas de nomenclatura para artefactos técnicos

Sin tildes, eñes ni caracteres especiales en nombres de tablas, columnas, medidas, scripts o archivos técnicos. Usar nombres ASCII planos (por ejemplo, `Plan Porcentaje Ejecucion`, no `Plan % Ejecución`).

Prefijos de medidas por dominio: `Plan *`, `Asistencia *`, `Encuesta *`, `Induccion *`, `HC *`, `PDI *`, `EntrevistaRetiro *`, `Bienestar *`, `Desempeno *`, `Competencias *`, `NineBox *`, `KPI *`.

Las medidas HTML shell siguen el patrón `HTML Shell {CodigoFrente} {TituloPagina}`. Las medidas del home corporativo usan `HTML Inicio Corporativo Propuesta {N}`. Todas las medidas HTML deben estar en la carpeta de display `11 HTML Content` del modelo semántico.

## Arquitectura del modelo de datos

12 tablas de hechos (prefijo `Fct_`), 18+ dimensiones (prefijo `Dim_`) y tablas de preparación intermedias (prefijo `Stg_`). Decisiones de diseño clave:

- **Dim_ColaboradorHC**: snapshot mensual con clave `documento-yyyy-MM` para habilitar análisis por tipo de cargo por período.
- **Fct_Induccion**: tres fuentes de cohortes consolidadas (antes de 2025-07-04, UC 2025, UC 2026) con un discriminador `SegmentoUC`.
- **Fct_EntrevistaRetiro_Unificada**: tres versiones de fuente homologadas en un único hecho con trazabilidad de origen.
- **Fct_Seguimiento_PDI**: `Fecha_Inicio` es la relación activa con el calendario; `Fecha_Fin` se usa solo dentro de medidas para alertas de vencimiento.
- **Frente Desempeño**: usa `Fct_Desempeno_2025`, `Fct_Competencias_2025`, `Fct_Desempeno_Evaluadores_2025`, `Fct_Desempeno_2024`, `Fct_Poblacion_Indicadores_2025` y `Dim_ColaboradorDesempeno`. Sus medidas se organizan en `Medidas_AD` mediante `displayFolder`.

## Lineamientos de marca (valores críticos)

| Elemento | Valor |
|---|---|
| Azul principal | `#003A70` |
| Encabezado oscuro | `#0B1C35` o `#1B487F` |
| Naranja acento | `#F7931E` — usar para estado activo, alertas y comparativos; nunca dominante |
| Fondo | blanco o `#F7F9FC` |
| Tamaño fuente título tarjeta | 12 |
| Tamaño fuente valor tarjeta | 16 |

Referencia visual vigente: página `00 Inicio Corporativo - Propuesta 1`. El esqueleto HTML shell usa: canvas 1280×720, encabezado `#0B1C35` de 100 px, supra en `#F7931E`, franja de filtros a `top:112px` alto 76 px, grid de 6 slots a `left:238px top:121px`, contenedor principal a `top:198px` alto 468 px y barra inferior a `top:674px` alto 40 px.

La navegación usa visuales `actionButton` con acción `PageNavigation`. Estado activo: naranja `#F7931E`. Botones de navegación hacia otro frente: fondo azul corporativo con texto blanco.

## Gobierno de scripts

| Script | Estado |
|---|---|
| `ApplyCardFontSizes.ps1` | **Vigente con cautela** — solo ajustes finos de fuentes en tarjetas |
| `DisableCategoryLabel.ps1` | **Vigente con cautela** — solo desactivar etiquetas de categoría en tarjetas |
| `ApplyBrandTheme.ps1` | Legacy / no operativo |
| `ApplyLemcoVisualStyle.ps1` | Legacy / solo referencia técnica |
| `ResetToDefault.ps1` | Legacy / solo recuperación con autorización expresa |
| `ApplyExecutiveDashboard.ps1` | **Deprecated** — puede sobrescribir páginas; no usar |
| `ReplaceHomeNivelCargoWithTipoCargo.ps1` | **Deprecated** — ajuste ya superado |

Antes de ejecutar cualquier script: verificar `git status`, identificar archivos afectados, confirmar que Power BI Desktop está cerrado y obtener autorización expresa del usuario. Todo script nuevo debe documentar objetivo, alcance, archivos afectados y modo seguro o de simulación si aplica.

## Commits

Formato Conventional Commits en español: `tipo(alcance): descripcion`

Tipos: `feat`, `fix`, `chore`, `refactor`, `docs`, `style`

Alcances: `model`, `dax`, `visuals`, `theme`, `data`, `docs`, `config`, `pbip` (o un alcance funcional como `aprendizaje`)

**Antes de proponer cualquier commit**, presentar: archivos modificados, archivos nuevos, archivos excluidos, documentos que deben actualizarse (o confirmación de que no aplica), resumen de cambios, mensaje de commit propuesto, cuerpo propuesto y criterio de inclusión/exclusión para `Outputs/`. Ejecutar el commit solo tras aprobación explícita del usuario.

## Regla de actualización documental

Después de cualquier cambio funcional, visual, de modelo, DAX, fuente de datos o configuración, verificar si estos documentos deben actualizarse antes de cerrar la tarea: `README.md`, `Docs/PROJECT_CONTEXT.md`, `Docs/AI_INSTRUCTIONS.md`, `Docs/COMMIT_GUIDELINES.md`, `Docs/FOLDER_STRUCTURE.md`, `Docs/BRAND_GUIDELINES.md`, `Docs/DATA_MODEL.md`. Proponer la actualización — no aplicarla sin autorización.
