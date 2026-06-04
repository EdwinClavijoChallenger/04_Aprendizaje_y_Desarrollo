# Auditoria de versiones del reporte

Fecha de auditoria: 2026-05-29

## Respaldo creado

Se creo un respaldo local del estado actual antes de continuar con nuevos cambios.

- Carpeta: `backups_codex/backup_20260529_120039_current_state`
- Contenido respaldado: `PBIP`, `Scripts` y `outputs`
- Archivos incluidos: 186
- Manifest: `backups_codex/backup_20260529_120039_current_state/backup_manifest.json`

## Hallazgo principal

La definicion del reporte fue modificada en bloque el 2026-05-29 a las 11:46:13 a. m.

Distribucion de archivos modificados dentro de `PBIP/Proyecto.Report`:

| Minuto | Archivos |
| --- | ---: |
| 2026-05-29 10:23 | 2 |
| 2026-05-29 11:42 | 3 |
| 2026-05-29 11:46 | 147 |

Esto indica que la definicion visual del reporte fue regenerada, incluyendo paginas, visuales y recursos del tema.

## Estado actual de paginas

| Pagina | Visuales | Ultima modificacion |
| --- | ---: | --- |
| 00 Inicio Corporativo | 37 | 2026-05-29 11:46:13 |
| 01 Resumen Ejecutivo Aprendizaje | 16 | 2026-05-29 11:46:13 |
| 02 Plan y Ejecucion | 17 | 2026-05-29 11:46:13 |
| 03 Cobertura y Participacion | 16 | 2026-05-29 11:46:13 |
| 04 Satisfaccion y Eficacia | 17 | 2026-05-29 11:46:13 |
| 05 Induccion y UC | 18 | 2026-05-29 11:46:13 |
| 06 Focos de Gestion | 17 | 2026-05-29 11:46:13 |

## Copias locales encontradas

No se encontro una copia local previa del proyecto de `04_Aprendizaje_y_Desarrollo` distinta al respaldo creado durante esta auditoria.

Se encontro otro `Proyecto.pbip` en:

- `03_Comunicaciones_Internas/PBIP/Proyecto.pbip`

Ese archivo parece corresponder a otro frente y no debe usarse como restauracion directa para Aprendizaje sin validacion previa.

## Recomendacion de recuperacion

Para no perder ajustes hechos directamente en Power BI, la recuperacion debe hacerse con control de version:

1. Mantener el respaldo actual como punto de retorno.
2. Evitar ejecutar nuevamente el script de regeneracion completa del reporte.
3. Recuperar desde historial de OneDrive/SharePoint una version de `PBIP/Proyecto.Report` anterior a las 11:46:13 a. m.
4. Comparar esa version recuperada contra el estado actual antes de reemplazar archivos.
5. Reaplicar solo cambios puntuales necesarios, preferiblemente sobre medidas o visuales especificos.

## Nota operativa

Mientras se hagan ajustes manuales en Power BI Desktop, cualquier modificacion automatizada sobre `PBIP/Proyecto.Report` debe hacerse solo despues de cerrar o guardar una version controlada del reporte.
