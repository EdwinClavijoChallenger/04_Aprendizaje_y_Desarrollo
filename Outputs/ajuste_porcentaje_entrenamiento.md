# Ajuste porcentaje de entrenamiento

## Cambio aplicado

Se agrego el indicador `Induccion Porcentaje Entrenamiento` para medir el porcentaje de entrenamiento inicial al cargo.

La logica aplicada es:

`registros con Entrenamiento = "SI" / registros con Entrenamiento = "SI", "PENDIENTE" o vacio`

## Modelo

La tabla consolidada `Fct_Induccion` ahora expone la columna:

- `Entrenamiento`

Esta columna proviene de la columna fuente `Entrenamiento ` de las tablas:

- `Fct_InduccionColaborador_antes_de_UC_2025`
- `Fct_InduccionColaborador_UC_2025`
- `Fct_InduccionColaborador_UC_2026`

## Medidas creadas

Carpeta: `04 Induccion UC`.

- `Induccion Entrenamiento Realizados`
- `Induccion Entrenamiento Base`
- `Induccion Porcentaje Entrenamiento`

## Visuales ajustados

### 00 Inicio Corporativo

La tarjeta `Entrenamiento h` fue reemplazada por `Entrenamiento %` y ahora usa:

- `Induccion Porcentaje Entrenamiento`

### 05 Induccion y Entrenamiento

Se agrego la tarjeta:

- `Entrenamiento %`

La fila superior de KPIs queda alineada con:

- `Onboarding %`
- `Entrenamiento %`
- `Onboarding neto`

Tambien se ajustaron visuales de analisis para comparar onboarding y entrenamiento:

- `Onboarding y entrenamiento por segmento`
- `Onboarding y entrenamiento mensual`
- `Onboarding y entrenamiento por empresa`
- `Comparativo induccion y entrenamiento`

## Validacion con datos fuente

Con el archivo local de seguimiento de induccion:

- Numerador `SI`: 875 registros.
- Denominador `SI`, `PENDIENTE` o vacio: 1.220 registros.
- Resultado esperado global: 71,72%.

Valores como `NO`, `NO APLICA`, `5` y `RENUNCIA` no hacen parte del denominador, de acuerdo con la regla solicitada.
