# Instrucciones permanentes para GitHub Copilot

Propósito: proporcionar instrucciones claras y persistentes para asistentes (Copilot) que trabajen en este repositorio PBIP de Power BI. Estas reglas complementan la documentación del proyecto ubicada en `Docs/` (PROJECT_CONTEXT.md, AI_INSTRUCTIONS.md, DATA_MODEL.md, BRAND_GUIDELINES.md, COMMIT_GUIDELINES.md, FOLDER_STRUCTURE.md).

Reglas generales (obligatorias):

1. Idioma: trabajar siempre en español (Colombia).
2. Contexto: mantener el contexto del Dashboard Corporativo de Gestión Humana / Desarrollo Organizacional en todas las propuestas y análisis.
3. Estructura de archivos: respetar la estructura PBIP del repositorio. No crear archivos fuera de las carpetas definidas (`PBIP/`, `Docs/`, `Scripts/`, `Outputs/`, `Assets/`, etc.) sin aprobación explícita.
4. Registro de trabajo: documentar cada análisis, propuesta o ajuste en la carpeta `Outputs/` con un archivo que describa los cambios propuestos y los motivos.
5. Economía de tokens y flujo de trabajo: antes de hacer cambios, analizar el contexto, proponer pasos accionables y pedir aprobación; evitar cambios masivos o regeneraciones completas sin autorización explícita del responsable del repositorio.
6. Control de versiones: nunca ejecutar commits, `git push` ni acciones que modifiquen el repositorio remoto sin autorización explícita del responsable del repositorio.
7. Lineamientos visuales: respetar los lineamientos de marca LEMCO / Challenger (ver `Docs/BRAND_GUIDELINES.md`) en cualquier cambio relacionado con temas, colores o estilos.
8. Validaciones obligatorias: validar modelo semántico, medidas DAX, relaciones y páginas antes de modificar; documentar resultados de la validación en `Outputs/` y proponer cambios puntuales.
9. Nombre del PBIP: mantener el nombre actual del proyecto PBIP si ya fue definido para publicación; cualquier cambio de nombre debe ser aprobado y documentado.
10. Pausa y reporte: al finalizar cualquier sesión de cambios, detenerse y resumir exactamente qué archivo(s) se creó/actualizó y dónde quedó la documentación (archivo en `Outputs/`).

Reglas de seguridad y privacidad:

- No exponer datos personales sensibles en `Outputs/` ni en visuales públicos. Si se requiere mostrar ejemplos con datos, usar muestras anonimizadas o datos sintéticos.
- Respetar las políticas de la organización sobre datos personales y confidencialidad; ante duda, detener el trabajo y solicitar orientación del propietario del proyecto.

Buenas prácticas operativas:

- Antes de proponer una modificación estructural, generar un plan con pasos numerados y estimación mínima de riesgo y consecuencias. Guardar el plan en `Outputs/`.
- Priorizar cambios pequeños y revertibles; preferir parches que documenten la razón y las medidas DAX afectadas.
- Siempre referenciar las páginas de `Docs/` relevantes en la documentación de `Outputs/` (usar enlaces a los archivos del repositorio).

Notas técnicas específicas para Copilot/Asistentes:

- No ejecutar ni sugerir scripts que modifiquen el archivo PBIP directamente sin una tarea aprobada; los cambios a `PBIP/Proyecto.SemanticModel` y `PBIP/Proyecto.Report` deben ser revisados y aprobados.
- Antes de editar medidas DAX, comprobar si la medida existe en `PBIP/Proyecto.SemanticModel/definition/tables/Medidas_AD.tmdl` y documentar la versión anterior en `Outputs/`.
- Validar dependencias de medida (referencias a otras medidas) y posibles impactos en visuales antes de aplicar cambios.

Referencias importantes:

- `Docs/PROJECT_CONTEXT.md`
- `Docs/AI_INSTRUCTIONS.md`
- `Docs/DATA_MODEL.md`
- `Docs/BRAND_GUIDELINES.md`
- `Docs/COMMIT_GUIDELINES.md`
- `Docs/FOLDER_STRUCTURE.md`

Versión y mantenimiento:

- Fecha de creación/actualización: 2026-06-23
- Autor: GitHub Copilot (instrucciones del repositorio)
- Para actualizar estas instrucciones, abrir un PR con justificación y enlace al `Outputs/` correspondiente donde se documentó la necesidad.
