# Rediseno dashboard Aprendizaje

## Objetivo del rediseno
Se reorganizo el reporte para que el frente Aprendizaje funcione como parte del Dashboard Corporativo de Desarrollo Organizacional. El nuevo flujo prioriza lectura ejecutiva, comparacion, filtros visibles, indicadores accionables y consistencia visual con la identidad LEMCO.

El diagnostico base fue el archivo `resumen_paginas_dashboard.md`, donde se identificaron brechas de paleta, filtros, horas de formacion, eficacia y variaciones entre periodos.

## Paginas finales

### 00 Inicio Corporativo
Pantalla de entrada al proyecto piloto organizada en cuatro bloques visuales:

- Aprendizaje: parte superior izquierda.
- Desempeno: parte superior derecha.
- Desarrollo: parte inferior izquierda.
- Bienestar y Clima: parte inferior derecha.

Aprendizaje queda marcado como frente activo. Los demas frentes quedan como proximas fases, preparados para integrarse cuando se carguen sus fuentes.

Incluye indicadores del bloque Aprendizaje: horas de formacion, cobertura, satisfaccion, eficacia, tipo de formacion, nivel de cargo como pendiente por fuente Headcount, onboarding e indicador de entrenamiento.

La portada tambien incorpora filtros generales en una franja superior compacta: anio, mes, empresa, area, tipo de formacion, modalidad y segmento UC.

### 01 Resumen Ejecutivo Aprendizaje
Pagina de lectura rapida para comite gerencial. Consolida indice aprendizaje, ejecucion del plan, horas de formacion, satisfaccion y cumplimiento de induccion.

Incluye tendencia mensual, cumplimiento por segmento UC, variaciones ejecutivas por mes y mix de ejecucion por tipo de formacion.

### 02 Plan y Ejecucion
Pagina de control del avance del plan. Refuerza actividades planificadas, ejecutadas, pendientes, horas, total horas y eficacia promedio.

Incluye plan vs ejecucion mensual, cumplimiento por area, ejecucion por tipo, estado del plan y variaciones MoM/YoY.

### 03 Cobertura y Participacion
Reemplaza la lectura anterior de asistencia por una vista de cobertura. Integra convocados del plan, asistentes, participantes unicos, cobertura, brecha de asistencia y variacion mensual.

Incluye participacion mensual, asistencia por empresa, asistencia por formacion y resumen ejecutivo por empresa.

### 04 Satisfaccion y Eficacia
Fortalece la lectura de calidad de la formacion. Integra encuestas, tasa de respuesta, satisfaccion, favorabilidad, eficacia del plan y variacion mensual de satisfaccion.

Incluye tendencia de satisfaccion, favorabilidad por empresa, satisfaccion por formacion, eficacia por tipo y detalle compacto de calidad.

### 05 Induccion y UC
Pagina enfocada en el impacto de Universidad Challenger. Mantiene la segmentacion Antes UC, UC 2025 y UC 2026.

Incluye total de colaboradores, cumplimiento, dias promedio, cumplimiento por segmento, variaciones UC 2025 vs Antes UC y UC 2026 vs UC 2025, tendencia mensual y comparativo por empresa.

### 06 Focos de Gestion
Pagina orientada a decision. Sustituye los hallazgos textuales que generaban errores por alertas numericas, rankings y tableros compactos.

Incluye alertas de bajo cumplimiento, indice aprendizaje, pendientes del plan, variaciones mensuales, rankings por area/empresa y tableros de decision por area y empresa.

## Filtros visibles incorporados
Se incorporaron 36 segmentadores visibles distribuidos por pagina:

- Anio
- Mes
- Empresa
- Area
- Tipo formacion
- Modalidad
- Estado del plan
- Estado de induccion
- Segmento UC
- Formacion

La franja superior de filtros mantiene una logica consistente y evita recargar el centro analitico de cada pagina.

Posteriormente se agregaron 7 filtros generales a la pagina `00 Inicio Corporativo`, para un total de 43 segmentadores en el reporte. En todos los segmentadores se desactivo el encabezado de segmentacion para mantener una presentacion mas limpia.

## Indicadores destacados
- Horas de formacion
- Total horas de formacion
- Eficacia promedio
- Cobertura de asistencia
- Satisfaccion principal medida como favorabilidad de encuestas
- Calificacion promedio de satisfaccion de la formacion
- Favorabilidad
- Cumplimiento de induccion
- Onboarding desde induccion
- Horas de entrenamiento desde induccion
- Nivel de cargo pendiente por fuente Headcount
- Indice aprendizaje
- Actividades pendientes
- Alertas de plan e induccion

## Comparativos agregados
Se agregaron medidas para lectura comparativa:

- Variacion de actividades ejecutadas MoM y YoY
- Variacion porcentual de actividades ejecutadas MoM y YoY
- Variacion de asistentes MoM y YoY
- Variacion porcentual de asistentes MoM y YoY
- Variacion de favorabilidad MoM y YoY como lectura principal de satisfaccion
- Variacion de colaboradores en induccion MoM
- Variacion de cumplimiento de induccion MoM
- Variacion UC 2025 vs Antes UC
- Variacion UC 2026 vs UC 2025

Nota: los comparativos YoY dependen de disponibilidad historica. En los datos actuales, induccion tiene lectura 2025-2026; plan, asistencia y encuestas se concentran principalmente en 2026.

## Criterios visuales aplicados
- Paleta LEMCO aplicada en tema: azul corporativo, azul profundo y naranja de acento.
- Colores principales usados: `#1B487F`, `#1A3059`, `#000032`, `#0B1C35` y `#F7931E`.
- Uso de tarjetas KPI arriba, analisis principal al centro y detalle accionable en la parte inferior.
- Mayor presencia de barras horizontales, tendencias y tablas compactas.
- Eliminacion de visuales textuales inestables que generaban errores de campos.
- Portada corporativa con frente activo y placeholders para frentes futuros.

## Decisiones de arquitectura
- Se mantiene la logica estrella existente del modelo.
- Se usa `Dim_Calendario` como eje de periodo.
- Se amplio el calendario hasta el 31 de diciembre de 2026 para cubrir todo el plan futuro.
- No se eliminaron medidas utiles.
- El rediseño se implemento desde `Scripts/ApplyExecutiveDashboard.ps1` para que la capa de reporte sea reproducible.
- Los JSON del reporte se escriben como UTF-8 sin BOM para evitar el error de apertura en Power BI Desktop.

## Validaciones realizadas
- PBIP abierto correctamente en Power BI Desktop.
- 127 archivos JSON del reporte parsean correctamente.
- 0 archivos JSON con BOM.
- 7 paginas finales generadas.
- 36 segmentadores visibles generados.
- Medidas de horas, total horas, eficacia y variaciones consultadas contra el modelo local sin error.
