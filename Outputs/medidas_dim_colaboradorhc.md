# Medidas y validacion de Dim_ColaboradorHC

## Resumen ejecutivo

Se valido que `Dim_ColaboradorHC` esta relacionada con `Fct_AsistenciaFormacion` mediante la llave tecnica `Colaborador_Key`.

La relacion existe en el modelo como:

- Desde: `Fct_AsistenciaFormacion[Colaborador_Key]`
- Hacia: `Dim_ColaboradorHC[Colaborador_Key]`
- Relacion: `AD_ColaboradorHC_Asistencia`

La visual de `Tipo de Cargo` en la pagina `00 Inicio Corporativo` estaba usando un recuento implicito generado por Power BI sobre `Dim_ColaboradorHC[Tipo_Cargo]`. Se reemplazo por una medida explicita para mejorar trazabilidad y mantenimiento.

## Diagnostico de datos

Con los archivos locales guardados en `Data` se obtuvo:

- `Dim_ColaboradorHC`: 7.456 registros.
- Llaves HC no vacias: 7.456.
- Llaves HC distintas: 7.456.
- Llaves HC duplicadas: 0.
- `Fct_AsistenciaFormacion`: 575 registros.
- Llaves de asistencia generadas: 575.
- Llaves de asistencia distintas: 324.
- Coincidencias exactas contra HC: 117.
- Porcentaje de cruce exacto contra HC: 20,35%.

Detalle por mes de asistencia:

| Mes | Registros asistencia | Cruces HC | Porcentaje de cruce |
| --- | ---: | ---: | ---: |
| 2026-02 | 65 | 63 | 96,9% |
| 2026-03 | 31 | 31 | 100,0% |
| 2026-04 | 23 | 23 | 100,0% |
| 2026-05 | 456 | 0 | 0,0% |

La baja cobertura total se explica porque el archivo `Dim_ColaboradorHC.xlsx` disponible contiene cortes de febrero, marzo y abril de 2026, mientras que la asistencia tiene un volumen importante en mayo de 2026.

## Distribucion HC por Tipo_Cargo

| Tipo_Cargo | Registros HC | Participacion |
| --- | ---: | ---: |
| Operativo | 4.853 | 65,1% |
| Administrativo | 1.628 | 21,8% |
| Tactico | 841 | 11,3% |
| Estrategico | 134 | 1,8% |

## Medidas creadas

Carpeta de medidas: `08 Headcount HC`.

- `HC Total Colaborador Mes`
- `HC Total Colaboradores Unicos`
- `HC Recuento Tipo Cargo`
- `HC Porcentaje Tipo Cargo`
- `HC Tipos Cargo`
- `Asistencia Registros HC Match`
- `Asistencia Colaborador Mes HC Match`
- `Asistencia Distribucion Tipo Cargo %`
- `Asistencia Registros Sin HC Match`
- `Asistencia Porcentaje HC Match`

## Ajuste en visual

En la pagina `00 Inicio Corporativo`, la visual `Tipo de Cargo` ahora usa:

- Eje/categoria: `Dim_ColaboradorHC[Tipo_Cargo]`
- Valor: `[HC Porcentaje Tipo Cargo]`

Esto conserva el analisis que estaba funcionando visualmente, pero reemplaza el recuento implicito de Power BI por una medida explicita del modelo.

## Recomendacion

Para analisis gerencial del bloque corporativo, usar `[HC Porcentaje Tipo Cargo]` cuando se quiera mostrar la composicion del headcount por cargo.

Para analisis de asistencia clasificada por cargo, usar las medidas de cruce `Asistencia ... HC Match`, teniendo presente que el resultado hoy queda limitado por la falta del corte HC de mayo 2026.
