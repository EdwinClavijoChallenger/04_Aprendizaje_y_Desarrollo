---
name: powerbi-signals
description: Review the local Power BI PBIP project, detect actionable findings, and generate validated daily signals JSON and execution logs. Use when the user asks to review the project, detect PBIP findings, or generate People Analytics signals.
---

# Power BI Signals

## Proposito

Convertir revisiones del proyecto local `04_Aprendizaje_y_Desarrollo` en senales estructuradas para seguimiento diario. La skill orienta a Codex para revisar el PBIP, identificar maximo 5 hallazgos accionables, normalizarlos bajo contrato JSON y dejar evidencia operativa sin modificar archivos funcionales del reporte.

## Cuando usarla

Usar esta skill cuando el usuario pida revisar el proyecto, buscar hallazgos del PBIP, generar senales de seguimiento, registrar senales diarias o aplicar una logica repetible de control sobre Power BI / People Analytics.

No usar internet. La fuente debe ser el proyecto local.

## Entradas esperadas

- Raiz del repo: `04_Aprendizaje_y_Desarrollo`.
- Fecha de ejecucion: usar la fecha local del entorno en formato `YYYY-MM-DD`.
- Contrato esperado: `contracts/senales_powerbi.schema.json`.
- Salida diaria: `data/senales/YYYY-MM-DD_senales_powerbi.json`.
- Registro de ejecucion: `Outputs/registro_senales_YYYY-MM-DD.md`.

## Pasos del flujo

1. Ejecutar `git status --short` antes de revisar o escribir cualquier archivo.
2. Revisar solo fuentes locales del proyecto:
   - `Docs/`
   - `Outputs/`
   - `PBIP/Proyecto.Report`
   - `PBIP/Proyecto.SemanticModel`
   - `PBIP/Proyecto.Report/definition/pages/pages.json`
   - paginas del reporte
   - visuales
   - navegacion
   - medidas DAX/TMDL
   - modelo semantico
3. Identificar maximo 5 hallazgos accionables. Priorizar riesgos de publicacion, consistencia ejecutiva, navegacion, modelo, medidas, filtros, visuales, nomenclatura y mantenibilidad.
4. Exigir evidencia concreta para cada hallazgo. La evidencia debe mencionar archivo, ruta, pagina, visual, medida o salida de comando.
5. Convertir cada hallazgo en una senal con los campos del contrato.
6. Crear `contracts/senales_powerbi.schema.json` con version `1.0.0` si no existe. Si existe, reutilizarlo sin romper compatibilidad.
7. Guardar el JSON diario en `data/senales/YYYY-MM-DD_senales_powerbi.json`. Si ya existe, no sobrescribir sin confirmar alcance; leerlo y evitar duplicados.
8. Validar que el JSON sea parseable y cumpla el contrato.
9. Documentar la ejecucion en `Outputs/registro_senales_YYYY-MM-DD.md`.
10. Mostrar al usuario rutas, cantidad de senales, validaciones, descartes/incompletas y `git status` final.

## Contrato de datos

El archivo `contracts/senales_powerbi.schema.json` debe usar `contract_version` igual a `1.0.0`.

Objeto raiz:

- `contract_version`: string, constante `1.0.0`.
- `proyecto`: string.
- `fecha`: string en formato `YYYY-MM-DD`.
- `senales`: arreglo de senales.

Cada senal debe incluir:

- `id`: identificador unico estable.
- `fecha`: fecha de generacion en formato `YYYY-MM-DD`.
- `proyecto`: nombre del proyecto.
- `frente`: frente funcional, por ejemplo `Aprendizaje`, `Desarrollo`, `Bienestar y Clima`, `Desempeno`, `Modelo`, `Reporte`, `General` o `null`.
- `fuente`: origen del hallazgo.
- `evidencia`: evidencia verificable dentro del repo.
- `impacto`: `alto`, `medio`, `bajo` o `null`.
- `accion`: recomendacion concreta y ejecutable.
- `estado`: `nuevo`, `en_revision`, `priorizado`, `descartado`, `ejecutado` o `null`.
- `archivos_relacionados`: arreglo de rutas relacionadas; usar `[]` si no aplica.

Si falta informacion no critica, usar `null` o `[]` segun corresponda. No inventar evidencia.

## Rutas de salida

- Contrato: `contracts/senales_powerbi.schema.json`.
- JSON diario: `data/senales/YYYY-MM-DD_senales_powerbi.json`.
- Registro: `Outputs/registro_senales_YYYY-MM-DD.md`.

## Reglas de validacion

- Confirmar que el JSON parsea correctamente.
- Confirmar que existen `contract_version`, `proyecto`, `fecha` y `senales`.
- Confirmar que cada senal contiene todos los campos requeridos.
- Confirmar que `impacto` usa solo `alto`, `medio`, `bajo` o `null`.
- Confirmar que `estado` usa solo `nuevo`, `en_revision`, `priorizado`, `descartado`, `ejecutado` o `null`.
- Confirmar que `archivos_relacionados` es un arreglo.
- Confirmar que no hay campos adicionales no definidos por el contrato.
- Evitar duplicados por `id` y por evidencia sustancialmente igual.
- Registrar senales descartadas o incompletas en el Markdown de ejecucion.

## Restricciones

- No buscar en internet.
- No modificar archivos funcionales del PBIP.
- No ejecutar scripts de transformacion del reporte.
- No regenerar paginas, modelo ni visuales.
- No editar `README.md`, `Docs/` u otros documentos funcionales salvo pedido explicito.
- No hacer commit.
- No hacer push.
- Respetar cambios locales existentes; asumir que pueden ser del usuario.
- Mantener nombres tecnicos nuevos en ASCII plano.

## Ejemplo de uso

Usuario:

```text
Revisa el proyecto 04_Aprendizaje_y_Desarrollo y genera las senales diarias del PBIP.
```

Codex debe:

1. Usar esta skill.
2. Ejecutar `git status --short`.
3. Revisar las fuentes locales indicadas.
4. Seleccionar maximo 5 hallazgos accionables.
5. Crear o reutilizar `contracts/senales_powerbi.schema.json`.
6. Guardar `data/senales/YYYY-MM-DD_senales_powerbi.json`.
7. Validar el JSON contra el contrato.
8. Documentar `Outputs/registro_senales_YYYY-MM-DD.md`.
9. Informar rutas, conteos, validaciones y estado final del repo.
