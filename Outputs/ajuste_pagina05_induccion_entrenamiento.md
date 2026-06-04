# Ajuste pagina 05 Induccion y Entrenamiento

## Cambio aplicado

La pagina `05 Induccion y UC` fue renombrada a:

`05 Inducción y Entrenamiento`

El objetivo del cambio es reflejar que el analisis incluye el entrenamiento inicial al cargo de los colaboradores, no solo el componente UC.

## Tarjetas KPI incorporadas

En la fila superior de indicadores se reorganizaron las tarjetas para incluir las dos medidas solicitadas:

- `Induccion Porcentaje Cumplimiento`: se muestra como `Cumplimiento bruto`.
- `Induccion Onboarding`: se muestra como `Onboarding neto`.

La fila KPI de la pagina queda estructurada asi:

1. `Colaboradores`
2. `Cumplimiento bruto`
3. `Onboarding neto`
4. `Dias promedio`
5. `Antes UC`
6. `UC 2025`
7. `UC 2026`

## Logica de negocio

- `Cumplimiento bruto`: mide aprobados sobre total de colaboradores en induccion.
- `Onboarding neto`: mide onboarding realizados sobre participantes, excluyendo renuncias del denominador.

## Archivos ajustados

- `PBIP/Proyecto.Report/definition/pages/ad1e0500000000000005/page.json`
- `PBIP/Proyecto.Report/definition/pages/ad1e0500000000000005/visuals`
- `Scripts/ApplyExecutiveDashboard.ps1`
- `Scripts/ResetToDefault.ps1`
- `Scripts/DisableCategoryLabel.ps1`
