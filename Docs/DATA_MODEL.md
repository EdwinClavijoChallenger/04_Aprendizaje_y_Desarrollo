# Modelo de datos

## Resumen

El modelo semantico del MVP de Aprendizaje esta construido en `PBIP/Proyecto.SemanticModel`. Mantiene una logica tipo estrella, con tablas de hechos para los procesos principales y dimensiones compartidas para analisis gerencial.

La tabla de medidas principal es `Medidas_AD`.

## Tablas de hechos

| Tabla | Descripcion | Granularidad |
|---|---|---|
| `Fct_PlanFormacion` | Planificacion y ejecucion de actividades de formacion. | Una actividad planificada o ejecutada. |
| `Fct_AsistenciaFormacion` | Registros de asistencia a procesos de formacion. | Un registro por participante y formacion. |
| `Fct_EncuestaFormacion` | Respuestas de encuesta de formacion. | Una respuesta de encuesta. |
| `Fct_InduccionColaborador_antes_de_UC_2025` | Fuente base de induccion antes de Universidad Challenger. | Un colaborador en seguimiento de induccion. |
| `Fct_InduccionColaborador_UC_2025` | Fuente base de induccion en transicion UC 2025. | Un colaborador en seguimiento de induccion. |
| `Fct_InduccionColaborador_UC_2026` | Fuente base de induccion UC 2026. | Un colaborador en seguimiento de induccion. |
| `Fct_Induccion` | Fact consolidada de induccion, onboarding y entrenamiento. | Un colaborador consolidado en seguimiento de induccion. |

## Dimensiones

| Dimension | Uso principal |
|---|---|
| `Dim_Calendario` | Dimension principal de fechas para plan, asistencia, encuesta e induccion. |
| `Dim_Empresa` | Analisis por empresa en asistencia, encuesta e induccion. |
| `Dim_Area` | Analisis por area en plan e induccion. |
| `Dim_TemaFormacion` | Homologacion de temas entre plan, asistencia y encuesta. |
| `Dim_TipoFormacion` | Analisis por tipo de formacion desde el plan. |
| `Dim_Modalidad` | Analisis por modalidad de formacion. |
| `Dim_EntidadFormadora` | Analisis por entidad o facilitador de formacion. |
| `Dim_EstadoFormacion` | Estado del plan de formacion. |
| `Dim_EstadoInduccion` | Estado homologado de induccion. |
| `Dim_SegmentoUC` | Segmentacion analitica para Antes_UC, UC_2025 y UC_2026. |
| `Dim_ColaboradorHC` | Headcount mensual para atributos del colaborador, especialmente `Tipo_Cargo`. |

## Relaciones principales

Las relaciones estan definidas en `PBIP/Proyecto.SemanticModel/definition/relationships.tmdl`.

Relaciones de calendario:

- `Fct_PlanFormacion[Fecha_Formacion]` -> `Dim_Calendario[Date]`
- `Fct_AsistenciaFormacion[Fecha_Asistencia]` -> `Dim_Calendario[Date]`
- `Fct_EncuestaFormacion[Fecha_Encuesta]` -> `Dim_Calendario[Date]`
- `Fct_Induccion[Fecha_Ingreso]` -> `Dim_Calendario[Date]`

Relaciones de negocio:

- `Fct_PlanFormacion[TemaFormacion_Key]` -> `Dim_TemaFormacion[TemaFormacion_Key]`
- `Fct_AsistenciaFormacion[TemaFormacion_Key]` -> `Dim_TemaFormacion[TemaFormacion_Key]`
- `Fct_EncuestaFormacion[TemaFormacion_Key]` -> `Dim_TemaFormacion[TemaFormacion_Key]`
- `Fct_AsistenciaFormacion[Empresa_Key]` -> `Dim_Empresa[Empresa_Key]`
- `Fct_EncuestaFormacion[Empresa_Key]` -> `Dim_Empresa[Empresa_Key]`
- `Fct_Induccion[Empresa_Key]` -> `Dim_Empresa[Empresa_Key]`
- `Fct_PlanFormacion[Area_Key]` -> `Dim_Area[Area_Key]`
- `Fct_Induccion[Area_Key]` -> `Dim_Area[Area_Key]`
- `Fct_PlanFormacion[TipoFormacion_Key]` -> `Dim_TipoFormacion[TipoFormacion_Key]`
- `Fct_PlanFormacion[Modalidad_Key]` -> `Dim_Modalidad[Modalidad_Key]`
- `Fct_PlanFormacion[EntidadFormadora_Key]` -> `Dim_EntidadFormadora[EntidadFormadora_Key]`
- `Fct_PlanFormacion[EstadoFormacion_Key]` -> `Dim_EstadoFormacion[EstadoFormacion_Key]`
- `Fct_Induccion[EstadoInduccion_Key]` -> `Dim_EstadoInduccion[EstadoInduccion_Key]`
- `Fct_Induccion[SegmentoUC_Key]` -> `Dim_SegmentoUC[SegmentoUC_Key]`

Relacion de headcount:

- `Fct_AsistenciaFormacion[Colaborador_Key]` -> `Dim_ColaboradorHC[Colaborador_Key]`

## Logica de `Dim_ColaboradorHC`

`Dim_ColaboradorHC` permite analizar atributos del colaborador por corte mensual, porque el tipo o nivel de cargo puede cambiar por movilidad interna.

La llave `Colaborador_Key` concatena:

```text
documento-yyyy-MM
```

En `Fct_AsistenciaFormacion`, la columna calculada `Colaborador_Key` se crea a partir de:

- `Numero de documento del participante`;
- anio y mes de `Hora de inicio`;
- formato `yyyy-MM`.

Ejemplo:

```text
1022937645-2026-02
```

Esta relacion permite analizar asistencia por `Tipo_Cargo` y validar cobertura del headcount disponible.

## Logica de `Fct_Induccion`

`Fct_Induccion` consolida las tres fuentes de induccion:

- antes de UC 2025;
- UC 2025;
- UC 2026.

La fecha de lanzamiento de Universidad Challenger es `2025-07-04`. La segmentacion queda:

- `Antes_UC`: ingresos antes de `2025-07-04`;
- `UC_2025`: ingresos desde `2025-07-04` hasta cierre de 2025;
- `UC_2026`: ingresos en 2026.

La fact consolidada tambien incorpora:

- estado de induccion;
- horas de induccion;
- minutos de entrenamiento;
- archivo entregado al area de Archivo;
- estado del colaborador;
- tiempo de finalizacion en dias;
- estado de entrenamiento.

## Medidas DAX clave

### Plan de formacion

- `Plan Actividades Planificadas`
- `Plan Actividades Ejecutadas`
- `Plan Porcentaje Ejecucion`
- `% Cobertura`
- `Plan Cobertura Asistencia`
- `Plan Horas Formacion`
- `Plan Total Horas Formacion`
- `Plan Eficacia Promedio`

`Plan Horas Formacion` y `Plan Total Horas Formacion` usan la columna `Fct_PlanFormacion[TOTAL DE HORAS DE FORMACION]`.

### Asistencia

- `Asistencia Total Registros`
- `Asistencia Total Asistentes`
- `Asistencia Participantes Unicos`
- `Asistencia Total Convocados`
- `Asistencia Porcentaje Asistencia`
- `Asistencia Porcentaje Ausentismo`
- `Asistencia Promedio Por Formacion`

### Encuesta de formacion

- `Encuesta Total Respuestas`
- `Encuesta Tasa Respuesta`
- `Encuesta Calificacion Promedio`
- `Encuesta Calificacion Satisfaccion Formacion`
- `Encuesta Favorabilidad`
- `Encuesta NPS Equivalente`

`Encuesta Favorabilidad` es el resultado principal de satisfaccion. Calcula el porcentaje de respuestas con calificacion mayor o igual a 4 sobre el total de respuestas.

`Encuesta Calificacion Satisfaccion Formacion` es el promedio de la calificacion de satisfaccion.

### Induccion, onboarding y entrenamiento

- `Induccion Total Colaboradores`
- `Induccion Aprobados`
- `Induccion Porcentaje Cumplimiento`
- `Induccion Onboarding`
- `Induccion Onboarding Realizados`
- `Induccion Onboarding Participantes`
- `Induccion Porcentaje Entrenamiento`
- `Induccion Entrenamiento Realizados`
- `Induccion Entrenamiento Base`
- `Induccion Entrenamiento Neto Realizados`
- `Induccion Porcentaje Entrenamiento Neto`
- `Induccion Tiempo Promedio Finalizacion Dias`

`Induccion Porcentaje Cumplimiento` es el porcentaje bruto de cumplimiento:

```text
Induccion Aprobados / Induccion Total Colaboradores
```

`Induccion Onboarding` es el porcentaje neto de onboarding:

```text
Onboarding realizados / Participantes
```

Donde los realizados corresponden a registros aprobados y los participantes excluyen `RENUNCIA`.

`Induccion Porcentaje Entrenamiento` calcula:

```text
registros con Entrenamiento = "SI" / registros con Entrenamiento = "SI", "PENDIENTE" o blanco
```

`Induccion Porcentaje Entrenamiento Neto` calcula el cumplimiento neto de entrenamiento tomando como referencia la informacion entregada al area de Archivo:

```text
registros con Archivo = 50 / Induccion Entrenamiento Base
```

Este indicador se usa como tarjeta en `00 Inicio Corporativo` y se agrega como indicador adicional en `05 Induccion y Entrenamiento`. La medida bruta `Induccion Porcentaje Entrenamiento` se mantiene para lectura operativa del avance reportado por el campo `Entrenamiento`.

### Headcount y tipo de cargo

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

Estas medidas soportan el analisis de asistencia por `Tipo_Cargo` desde `Dim_ColaboradorHC`.

### KPI gerencial

`KPI Indice Aprendizaje` promedia los principales indicadores del bloque, excluyendo valores en blanco:

- `Plan Porcentaje Ejecucion`;
- `Plan Cobertura Asistencia`;
- `Encuesta Favorabilidad`;
- `Induccion Porcentaje Cumplimiento`.

## Observaciones importantes

- `Fct_PlanFormacion` es la fuente principal para horas de formacion, cobertura, eficacia, tipo de formacion y estado del plan.
- `Fct_AsistenciaFormacion` permite analizar asistencia real y se conecta con `Dim_ColaboradorHC` para lectura por tipo de cargo.
- `Fct_EncuestaFormacion` soporta satisfaccion, favorabilidad y percepcion de calidad.
- `Fct_Induccion` es la fuente gerencial consolidada para onboarding, entrenamiento y segmentacion UC.
- `Dim_ColaboradorHC` debe mantenerse actualizada por corte mensual para que el analisis de tipo de cargo sea confiable.
