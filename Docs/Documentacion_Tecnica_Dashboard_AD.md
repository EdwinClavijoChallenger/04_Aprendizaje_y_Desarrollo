# Dashboard Aprendizaje y Desarrollo - Documentacion tecnica

> Nota de estado documental: este documento queda conservado como historico. Su contenido vigente fue migrado y reorganizado en la nueva estructura de `Docs`, principalmente en `PROJECT_CONTEXT.md`, `DATA_MODEL.md`, `BRAND_GUIDELINES.md`, `FOLDER_STRUCTURE.md` y `AI_INSTRUCTIONS.md`. Antes de usarlo como fuente actual, validar contra esos documentos.

Fecha de construccion: 2026-05-28

## Alcance

Se construyo un modelo gerencial para Aprendizaje y Desarrollo sobre el proyecto `PBIP/Proyecto4.pbip`, tomando como fuente de verdad el modelo abierto en Power BI Desktop.

El dashboard cubre:

- planificacion y ejecucion de formacion,
- asistencia a procesos de formacion,
- percepcion y calidad de la formacion,
- seguimiento de induccion,
- comparativo antes y despues del lanzamiento de Universidad Challenger,
- seguimiento de Planes de Desarrollo Individual,
- hallazgos y focos de gestion.

## Tablas fact utilizadas

| Tabla | Registros revisados | Granularidad | Observaciones |
|---|---:|---|---|
| `Fct_PlanFormacion` | 274 | Una actividad planificada de formacion | Contiene fecha, tema, tipo, area, publico objetivo, asistencia, horas, estado, modalidad, costo y entidad formadora. No contiene empresa. |
| `Fct_AsistenciaFormacion` | 575 | Un registro de asistencia por participante/formacion | Contiene empresa y formacion seleccionada. No contiene convocados ni area. |
| `Fct_EncuestaFormacion` | 428 | Una respuesta de encuesta | Contiene empresa, tema/percepcion y calificaciones. Los campos de correo/nombre estan mayormente anonimizados o vacios. |
| `Fct_InduccionColaborador_antes_de_UC_2025` | 504 | Un colaborador en seguimiento de induccion | Cohorte antes de Universidad Challenger. |
| `Fct_InduccionColaborador_UC_2025` | 433 | Un colaborador en seguimiento de induccion | Cohorte de transicion UC 2025. Se detectaron 26 registros con ingreso previo al 2025-07-04. |
| `Fct_InduccionColaborador_UC_2026` | 437 | Un colaborador en seguimiento de induccion | Cohorte UC 2026. `Fecha Certificado` viene como texto y se convierte para el analisis. |
| `Fct_Seguimiento_PDI` | Pendiente validar en refresh | Un PDI por colaborador y plan | Fuente inicial del frente Desarrollo. Contiene motivo, estado, avance, fechas y acompanamientos. |

## Dimensiones creadas

| Dimension | Uso |
|---|---|
| `Dim_Calendario` | Dimension principal de fechas. Se desactivo Auto Date/Time y se agregaron columnas tecnicas `Fecha`, `Anio`, `MesNumero`, `MesNombreCorto`, `AnioMes`, `AnioMesOrden`, `Trimestre`. |
| `Dim_Empresa` | Homologa empresas desde asistencia, encuesta e induccion. Normaliza variantes como `CHALLENGER S.A.S` / `CHALLENGER SAS`. |
| `Dim_Area` | Integra areas del plan y dependencias de induccion. |
| `Dim_TemaFormacion` | Homologa temas/formaciones entre plan, asistencia y encuesta con llave tecnica normalizada. |
| `Dim_TipoFormacion` | Tipo de formacion del plan. |
| `Dim_Modalidad` | Modalidad del plan. |
| `Dim_EntidadFormadora` | Entidad o facilitador externo del plan. |
| `Dim_EstadoFormacion` | Estado de ejecucion del plan. |
| `Dim_EstadoInduccion` | Estado homologado de induccion: `APROBO`, `NO_APROBO`, `RETIRADO`, `RENUNCIA`, `SIN_ESTADO`. |
| `Dim_SegmentoUC` | Segmentacion analitica UC: `Antes_UC`, `UC_2025`, `UC_2026`. |
| `Dim_MotivoPDI` | Motivo de apertura del Plan de Desarrollo Individual. |
| `Dim_EstadoPDI` | Estado del Plan de Desarrollo Individual. |

## Fact gerencial creada

`Fct_Induccion` consolida las tres tablas de induccion en una sola tabla de analisis, con:

- `Cohorte_Fuente`,
- `SegmentoUC_Key`,
- `Colaborador_Key`,
- `Empresa_Key`,
- `Area_Key`,
- `Fecha_Ingreso`,
- `Fecha_Certificado`,
- `EstadoInduccion_Key`,
- horas y minutos de induccion/entrenamiento,
- `Tiempo_Finalizacion_Dias`.

La segmentacion UC usa como fecha de lanzamiento `2025-07-04`:

- ingresos antes de `2025-07-04` => `Antes_UC`,
- ingresos desde `2025-07-04` hasta cierre 2025 => `UC_2025`,
- ingresos 2026 => `UC_2026`.

Se excluyen filas tecnicamente vacias sin colaborador o sin fecha de ingreso. La fact consolidada queda con 1.348 registros validos.

## Relaciones

Se eliminaron relaciones de tablas locales automaticas de fecha y se crearon relaciones de una direccion desde facts hacia dimensiones:

- `Fct_PlanFormacion[Fecha_Formacion]` -> `Dim_Calendario[Date]`
- `Fct_AsistenciaFormacion[Fecha_Asistencia]` -> `Dim_Calendario[Date]`
- `Fct_EncuestaFormacion[Fecha_Encuesta]` -> `Dim_Calendario[Date]`
- `Fct_Induccion[Fecha_Ingreso]` -> `Dim_Calendario[Date]`
- tema hacia plan/asistencia/encuesta,
- empresa hacia asistencia/encuesta/induccion,
- area hacia plan/induccion,
- tipo, modalidad, entidad y estado hacia plan,
- estado y segmento UC hacia induccion.
- fecha de inicio, empresa, area, motivo y estado hacia `Fct_Seguimiento_PDI`.

## Medidas principales

Las medidas quedaron en `Medidas_AD`, organizadas por carpetas:

- `00 KPIs Gerenciales`
- `01 Plan Formacion`
- `02 Asistencia`
- `03 Encuesta Formacion`
- `04 Induccion UC`
- `05 Rankings y Alertas`
- `06 Hallazgos`
- `09 Desarrollo PDI`
- `10 Desarrollo Alertas`

Indicadores clave creados:

- `Plan Actividades Planificadas`, `Plan Actividades Ejecutadas`, `Plan Porcentaje Ejecucion`, `Plan Brecha Actividades`, `Plan Publico Objetivo`, `Plan Cobertura Asistencia`, `Plan Costo`.
- `Asistencia Total Convocados`, `Asistencia Total Asistentes`, `Asistencia Porcentaje Asistencia`, `Asistencia Porcentaje Ausentismo`, `Asistencia Participantes Unicos`.
- `Encuesta Total Respuestas`, `Encuesta Tasa Respuesta`, `Encuesta Calificacion Promedio`, `Encuesta Satisfaccion General`, `Encuesta Favorabilidad`, `Encuesta NPS Equivalente`.
- `Induccion Total Colaboradores`, `Induccion Aprobados`, `Induccion Porcentaje Cumplimiento`, `Induccion Tiempo Promedio Finalizacion Dias`, `Induccion Cumplimiento Antes UC`, `Induccion Cumplimiento UC 2025`, `Induccion Cumplimiento UC 2026`.
- `KPI Indice Aprendizaje`, rankings y alertas de bajo cumplimiento.
- `PDI Total`, `PDI Activos`, `PDI Finalizados`, `PDI Avance Promedio`, `PDI Cumplimiento Acompanamientos`, `PDI Vencidos`, `PDI Proximos A Vencer`, `PDI Alertas Criticas`, `KPI Indice Desarrollo`.

## Paginas construidas

1. `00 Inicio Corporativo`
2. `A01 Resumen Ejecutivo Aprendizaje`
3. `A02 Plan y Ejecucion`
4. `A03 Cobertura y Participacion`
5. `A04 Satisfaccion y Eficacia`
6. `A05 Induccion y Entrenamiento`
7. `A06 Focos de Gestion`
8. `D01 Resumen Ejecutivo Desarrollo`
9. `D02 Estado y Avance PDI`
10. `D03 Motivos y Seguimiento`
11. `D04 Focos de Gestion Desarrollo`

Se priorizaron tarjetas KPI, barras horizontales, lineas de tendencia y tablas resumen solo donde aportan lectura ejecutiva.

## Criterios visuales

Se actualizo el tema base del reporte con lineamientos de Grupo LEMCO:

- color base comparativo: `#003A70`,
- color de contraste: `#F7931E`,
- fondo limpio blanco/gris claro,
- tipografia ejecutiva con preferencia por `Outfit` y respaldo `Segoe UI`,
- foco en lectura rapida, jerarquia visual y sobriedad gerencial.
- nomenclatura de paginas por frente: `A` para Aprendizaje y `D` para Desarrollo.

## Restricciones y decisiones

- No se creo `Dim_CentroCosto` porque el centro/codigo aparece embebido en `DEPENDENCIA` de induccion y no existe como campo estructurado independiente.
- No se creo `Dim_Proceso` porque no hay un campo comun y consistente de proceso entre las facts.
- El cumplimiento por empresa del plan no es calculable directamente porque `Fct_PlanFormacion` no trae empresa. Los analisis por empresa aplican a asistencia, encuesta e induccion.
- La tasa de respuesta de encuesta se calcula contra registros de asistencia disponibles; debe interpretarse como tasa operacional sobre asistencia registrada, no como tasa oficial de convocados.
- Hay duplicados de documento entre cohortes de induccion. Por eso existen medidas de registros de induccion y de colaboradores unicos.

## Reproducibilidad

El script `Scripts/ApplyExecutiveDashboard.ps1` reconstruye el modelo y/o el reporte:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\Scripts\ApplyExecutiveDashboard.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\Scripts\ApplyExecutiveDashboard.ps1" -ReportOnly
```
