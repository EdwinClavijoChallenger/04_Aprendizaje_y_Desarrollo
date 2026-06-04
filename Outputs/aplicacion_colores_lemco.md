# Aplicacion de colores LEMCO

Fecha: 2026-05-29

## Objetivo

Reforzar la aplicacion visible de la identidad visual LEMCO en todas las paginas del reporte, manteniendo el estado actual del PBIP y evitando una regeneracion completa de paginas.

## Respaldo previo

Antes del ajuste se creo un checkpoint local:

- `backups_codex/backup_20260529_162114_before_lemco_colors`

## Cambios aplicados

Se aplico un ajuste puntual sobre el reporte actual:

- Tema actualizado: `PBIP/Proyecto.Report/StaticResources/SharedResources/BaseThemes/CY25SU11.json`
- Script de aplicacion creado: `Scripts/ApplyLemcoVisualStyle.ps1`
- Paginas ajustadas: 6
- Visuales ajustados: 101

## Paginas impactadas

| Pagina | Ajuste |
| --- | --- |
| 01 Resumen Ejecutivo Aprendizaje | Titulos, tarjetas, graficos, tablas y segmentadores con estilo LEMCO |
| 02 Plan y Ejecucion | Titulos, tarjetas, graficos, tablas y segmentadores con estilo LEMCO |
| 03 Cobertura y Participacion | Titulos, tarjetas, graficos, tablas y segmentadores con estilo LEMCO |
| 04 Satisfaccion y Eficacia | Titulos, tarjetas, graficos, tablas y segmentadores con estilo LEMCO |
| 05 Induccion y UC | Titulos, tarjetas, graficos, tablas y segmentadores con estilo LEMCO |
| 06 Focos de Gestion | Titulos, tarjetas, graficos, tablas y segmentadores con estilo LEMCO |

La pagina `00 Inicio Corporativo` ya tenia colores LEMCO explicitos y se mantuvo sin reestilizar masivamente.

## Criterios visuales aplicados

- Azul base LEMCO `#1B487F` para titulos de visuales y color principal de graficos.
- Naranja LEMCO `#F7931E` conservado como color de contraste dentro del tema.
- Azul profundo `#1A3059` para ejes, leyendas y texto secundario.
- Tinta corporativa `#0B1C35` para valores y etiquetas.
- Bordes suaves `#E6EEF5` para dar estructura sin saturar.
- Fondo blanco `#FFFFFF` para mantener lectura ejecutiva limpia.

## Validaciones

- Archivos JSON validados: 150
- Errores de parseo JSON: 0
- Archivos JSON con BOM: 0
- Propiedades invalidas detectadas en `visualContainerObjects`: 0

## Resultado de color por pagina

| Pagina | Ocurrencias de color LEMCO explicitas |
| --- | ---: |
| 00 Inicio Corporativo | 21 |
| 01 Resumen Ejecutivo Aprendizaje | 90 |
| 02 Plan y Ejecucion | 100 |
| 03 Cobertura y Participacion | 90 |
| 04 Satisfaccion y Eficacia | 100 |
| 05 Induccion y UC | 100 |
| 06 Focos de Gestion | 98 |

## Nota operativa

Este ajuste no reconstruye paginas ni elimina visuales. Se aplico sobre los archivos existentes del reporte para proteger cambios manuales realizados en Power BI Desktop.
