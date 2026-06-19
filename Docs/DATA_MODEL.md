# Modelo de datos

## Resumen

El modelo semantico esta construido en `PBIP/Proyecto.SemanticModel`. Mantiene una logica tipo estrella, con tablas de hechos para los procesos principales y dimensiones compartidas para analisis gerencial.

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
| `Fct_Seguimiento_PDI` | Seguimiento de Planes de Desarrollo Individual del frente Desarrollo. | Un PDI por colaborador y plan de desarrollo. |
| `Fct_EntrevistaRetiro_V1` | Fuente historica de la primera version de entrevista de retiro. | Una respuesta de entrevista de retiro. |
| `Fct_EntrevistaRetiro_V2` | Fuente historica de la segunda version de entrevista de retiro. | Una respuesta de entrevista de retiro. |
| `Fct_EntrevistaRetiro_Corporativa` | Fuente corporativa nueva para unificar el proceso de entrevista de retiro. | Una respuesta de entrevista de retiro. |
| `Fct_EntrevistaRetiro_Unificada` | Fact homologada para analisis agregado de entrevista de retiro en Bienestar y Clima. | Una entrevista de retiro homologada, con trazabilidad de fuente. |
| `Fct_SeguimientoBienestar` | Seguimiento mensual del plan de actividades de bienestar (planeacion original, planeacion de ejecucion y ejecucion real). Tabla calculada con cruce de actividades por los 12 meses del anio. | Una actividad de bienestar por mes. |

## Observaciones por fuente

- `Fct_PlanFormacion` contiene fecha, tema, tipo de formacion, area, publico objetivo, asistencia, horas, estado, modalidad, costo y entidad formadora. No contiene empresa, por lo que el cumplimiento del plan por empresa no es calculable directamente desde esta fuente.
- `Fct_AsistenciaFormacion` contiene registros reales de asistencia por participante y formacion. No contiene convocados ni area de forma directa; los analisis por tipo de cargo se soportan mediante la relacion con `Dim_ColaboradorHC`.
- `Fct_EncuestaFormacion` contiene respuestas de percepcion y calificaciones. Los campos personales como correo o nombre pueden venir anonimizados o vacios, por lo que las metricas deben enfocarse en respuestas, favorabilidad y percepcion agregada.
- Las tablas base de induccion se consolidan en `Fct_Induccion` para evitar analisis fragmentados por cohorte.
- `Fct_Seguimiento_PDI` es la fuente inicial del frente Desarrollo; movilidad, sucesion y cargos criticos quedan pendientes de fuentes adicionales.
- Las fuentes de entrevista de retiro tienen estructuras diferentes entre versiones. Para analisis gerencial se crea `Fct_EntrevistaRetiro_Unificada`, conservando la trazabilidad con `Fuente_Entrevista`.
- Los conteos historicos documentados en versiones anteriores deben tratarse como referencia de construccion y validarse nuevamente despues de cada refresh.

## Dimensiones

| Dimension | Uso principal |
|---|---|
| `Dim_Calendario` | Dimension principal de fechas para plan, asistencia, encuesta, induccion y PDI. |
| `Dim_Empresa` | Analisis por empresa en asistencia, encuesta, induccion y PDI. |
| `Dim_Area` | Analisis por area en plan, induccion y PDI. |
| `Dim_TemaFormacion` | Homologacion de temas entre plan, asistencia y encuesta. |
| `Dim_TipoFormacion` | Analisis por tipo de formacion desde el plan. |
| `Dim_Modalidad` | Analisis por modalidad de formacion. |
| `Dim_EntidadFormadora` | Analisis por entidad o facilitador de formacion. |
| `Dim_EstadoFormacion` | Estado del plan de formacion. |
| `Dim_EstadoInduccion` | Estado homologado de induccion. |
| `Dim_SegmentoUC` | Segmentacion analitica para Antes_UC, UC_2025 y UC_2026. |
| `Dim_ColaboradorHC` | Headcount mensual para atributos del colaborador, especialmente `Tipo_Cargo`. |
| `Dim_MotivoPDI` | Analisis de motivos de apertura de Planes de Desarrollo Individual. |
| `Dim_EstadoPDI` | Analisis de estados de Planes de Desarrollo Individual. |
| `Dim_FuenteEntrevistaRetiro` | Analisis por version u origen de entrevista de retiro. |
| `Dim_UnidadNegocioRetiro` | Analisis de entrevista de retiro por unidad de negocio homologada. |
| `Dim_TipoRetiro` | Analisis por tipo de retiro homologado. |
| `Dim_MotivoRetiro` | Analisis por motivo principal de retiro. |
| `Dim_CategoriaMotivoRetiro` | Agrupacion ejecutiva de motivos de retiro. |
| `Dim_ProcesoRetiro` | Analisis de procesos asociados a oportunidades de mejora. |
| `Dim_ActividadBienestar` | Catalogo de actividades del plan de bienestar. Clave compuesta `DIMENSION + COMPONENTES`. Calculada desde staging. |
| `Dim_DimensionBienestar` | Catalogo de dimensiones del plan de bienestar (agrupaciones de actividades). Calculada desde staging. |
| `Dim_Frente_Home` | Tabla auxiliar para controlar el frente activo del home corporativo. |
| `Dim_FechaActualizacion` | Tabla auxiliar de metadatos. Captura la datetime del ultimo refresh del modelo en zona horaria Bogota (UTC-5). Una sola fila. Usada por `HTML Inicio Corporativo Propuesta 1` para mostrar la fecha de actualizacion en el header del Home. |

## Criterios de homologacion

- `Dim_Calendario` es la dimension principal de fechas y contiene columnas tecnicas como `Fecha`, `Anio`, `MesNumero`, `MesNombreCorto`, `AnioMes`, `AnioMesOrden` y `Trimestre`.
- `Dim_Empresa` normaliza variantes de empresa para facilitar comparativos entre asistencia, encuesta, induccion y PDI.
- `Dim_Area` integra areas del plan y dependencias de induccion/PDI cuando la fuente no usa exactamente la misma nomenclatura.
- `Dim_TemaFormacion` homologa temas o nombres de formacion entre plan, asistencia y encuesta mediante llaves tecnicas normalizadas.
- Las dimensiones de estado, modalidad, tipo de formacion, motivo PDI y segmento UC se mantienen separadas para evitar relaciones ambiguas y mejorar la lectura ejecutiva.
- Las dimensiones de entrevista de retiro se derivan de `Fct_EntrevistaRetiro_Unificada` para no alterar las fuentes originales y mantener un modelo escalable para versiones futuras.
- `Dim_Frente_Home` no se usa como dimension analitica relacionada con hechos. Soporta la seleccion del frente activo en `00 Inicio Corporativo` mediante el slicer tecnico oculto `sel_p1_frente` y los marcadores del home.

## Relaciones principales

Las relaciones estan definidas en `PBIP/Proyecto.SemanticModel/definition/relationships.tmdl`.

El modelo prioriza relaciones de una direccion desde dimensiones hacia hechos, manteniendo una logica tipo estrella y evitando relaciones ambiguas o duplicadas. Las relaciones automaticas locales de fecha deben evitarse o desactivarse cuando generen tablas locales innecesarias.

Relaciones de calendario:

- `Fct_PlanFormacion[Fecha_Formacion]` -> `Dim_Calendario[Date]`
- `Fct_AsistenciaFormacion[Fecha_Asistencia]` -> `Dim_Calendario[Date]`
- `Fct_EncuestaFormacion[Fecha_Encuesta]` -> `Dim_Calendario[Date]`
- `Fct_Induccion[Fecha_Ingreso]` -> `Dim_Calendario[Date]`
- `Fct_Seguimiento_PDI[Fecha_Inicio]` -> `Dim_Calendario[Date]`
- `Fct_EntrevistaRetiro_Unificada[Fecha_Entrevista]` -> `Dim_Calendario[Date]`
- `Fct_SeguimientoBienestar[FechaPeriodo]` -> `Dim_Calendario[Date]`

Relaciones de negocio:

- `Fct_PlanFormacion[TemaFormacion_Key]` -> `Dim_TemaFormacion[TemaFormacion_Key]`
- `Fct_AsistenciaFormacion[TemaFormacion_Key]` -> `Dim_TemaFormacion[TemaFormacion_Key]`
- `Fct_EncuestaFormacion[TemaFormacion_Key]` -> `Dim_TemaFormacion[TemaFormacion_Key]`
- `Fct_AsistenciaFormacion[Empresa_Key]` -> `Dim_Empresa[Empresa_Key]`
- `Fct_EncuestaFormacion[Empresa_Key]` -> `Dim_Empresa[Empresa_Key]`
- `Fct_Induccion[Empresa_Key]` -> `Dim_Empresa[Empresa_Key]`
- `Fct_Seguimiento_PDI[Empresa_Key]` -> `Dim_Empresa[Empresa_Key]`
- `Fct_PlanFormacion[Area_Key]` -> `Dim_Area[Area_Key]`
- `Fct_Induccion[Area_Key]` -> `Dim_Area[Area_Key]`
- `Fct_Seguimiento_PDI[Area_Key]` -> `Dim_Area[Area_Key]`
- `Fct_PlanFormacion[TipoFormacion_Key]` -> `Dim_TipoFormacion[TipoFormacion_Key]`
- `Fct_PlanFormacion[Modalidad_Key]` -> `Dim_Modalidad[Modalidad_Key]`
- `Fct_PlanFormacion[EntidadFormadora_Key]` -> `Dim_EntidadFormadora[EntidadFormadora_Key]`
- `Fct_PlanFormacion[EstadoFormacion_Key]` -> `Dim_EstadoFormacion[EstadoFormacion_Key]`
- `Fct_Induccion[EstadoInduccion_Key]` -> `Dim_EstadoInduccion[EstadoInduccion_Key]`
- `Fct_Induccion[SegmentoUC_Key]` -> `Dim_SegmentoUC[SegmentoUC_Key]`
- `Fct_Seguimiento_PDI[MotivoPDI_Key]` -> `Dim_MotivoPDI[MotivoPDI_Key]`
- `Fct_Seguimiento_PDI[EstadoPDI_Key]` -> `Dim_EstadoPDI[EstadoPDI_Key]`
- `Fct_EntrevistaRetiro_Unificada[FuenteEntrevista_Key]` -> `Dim_FuenteEntrevistaRetiro[FuenteEntrevista_Key]`
- `Fct_EntrevistaRetiro_Unificada[UnidadNegocio_Key]` -> `Dim_UnidadNegocioRetiro[UnidadNegocio_Key]`
- `Fct_EntrevistaRetiro_Unificada[TipoRetiro_Key]` -> `Dim_TipoRetiro[TipoRetiro_Key]`
- `Fct_EntrevistaRetiro_Unificada[MotivoRetiro_Key]` -> `Dim_MotivoRetiro[MotivoRetiro_Key]`
- `Fct_EntrevistaRetiro_Unificada[CategoriaMotivo_Key]` -> `Dim_CategoriaMotivoRetiro[CategoriaMotivo_Key]`
- `Fct_EntrevistaRetiro_Unificada[ProcesoRetiro_Key]` -> `Dim_ProcesoRetiro[ProcesoRetiro_Key]`
- `Fct_SeguimientoBienestar[DimensionBienestar_Key]` -> `Dim_DimensionBienestar[DimensionBienestar_Key]`
- `Fct_SeguimientoBienestar[ActividadBienestar_Key]` -> `Dim_ActividadBienestar[ActividadBienestar_Key]`

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

## Logica de `Fct_Seguimiento_PDI`

`Fct_Seguimiento_PDI` soporta el frente Desarrollo y consolida el seguimiento de Planes de Desarrollo Individual.

Durante la normalizacion se aplican nombres tecnicos sin tildes ni caracteres especiales:

- `Nombre_Empresa`
- `Identificacion_Colaborador`
- `Area`
- `Cargo`
- `Jefe_Inmediato`
- `Motivo_PDI`
- `Fecha_Inicio`
- `Fecha_Fin`
- `Acompanamiento_1`
- `Acompanamiento_2`
- `Acompanamiento_3`
- `Avance_PDI`
- `Estado_PDI`

Tambien se crean llaves auxiliares:

- `Empresa_Key`
- `Area_Key`
- `MotivoPDI_Key`
- `EstadoPDI_Key`
- `PDI_Key`

La fecha activa de analisis es `Fecha_Inicio`. Para vencimientos y proximos vencimientos se usa `Fecha_Fin` directamente dentro de las medidas, evitando una segunda relacion activa con calendario.

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

Se excluyen filas tecnicamente vacias sin colaborador o sin fecha de ingreso. Tambien pueden existir documentos repetidos entre cohortes, por lo que deben diferenciarse las medidas de registros de induccion y las medidas de colaboradores unicos.

## Logica de `Fct_SeguimientoBienestar`

`Fct_SeguimientoBienestar` es la fuente principal del frente Plan de Bienestar. Es una tabla calculada que construye una cuadricula actividad × mes para cada anio en seguimiento.

Las fuentes de entrada son `Stg_Bienestar_Planeacion` (plan original aprobado) y `Stg_Bienestar_Ejecucion` (reprogramacion y ejecucion real). Ambas staging tienen la misma estructura: `DIMENSION`, `COMPONENTES`, `Planeado` (X = planeado), `Ejecutado` (OK = ejecutado), `OBSERVACION`.

La clave de actividad se construye como:

```text
UPPER(TRIM(DIMENSION)) & "|" & UPPER(TRIM(COMPONENTES))
```

Los estados calculados son:

- `EstadoProgramacion`: compara planeacion original vs planeacion de ejecucion. Valores: `Sin diferencia`, `Retirado de ejecucion`, `Agregado en ejecucion`, `Sin programacion`.
- `EstadoAlCorte`: combina el estado de programacion con el punto de corte real (ultimo mes con ejecucion). Valores: `Ejecutado`, `Ejecutado no planeado`, `Retirado de ejecucion`, `Pendiente en curso`, `Pendiente vencido`, `Pendiente futuro`, `No programado`.

El periodo de corte (`_PeriodoCorte`) se calcula como el mayor `FechaPeriodo` donde `EjecutadoReal = 1`, y sirve para clasificar los pendientes.

La granularidad es una fila por actividad y por mes del anio en seguimiento. Las actividades sin dimension o componente valido se excluyen del resultado.

## Logica de `Fct_EntrevistaRetiro_Unificada`

`Fct_EntrevistaRetiro_Unificada` consolida tres versiones de entrevista de retiro:

- `Fct_EntrevistaRetiro_V1`;
- `Fct_EntrevistaRetiro_V2`;
- `Fct_EntrevistaRetiro_Corporativa`.

La tabla unificada conserva trazabilidad con:

- `FuenteEntrevista_Key`;
- `Fuente_Entrevista`.

Los campos personales como nombre, correo, cedula, documento y jefe inmediato no se llevan a la tabla unificada ni a la pagina gerencial, para evitar exposicion innecesaria de datos sensibles.

La regla principal de validez es:

```text
Autorizacion tratamiento de datos inicia por "Acepta"
y no contiene "No acepta"
```

Los registros se clasifican con:

- `RegistroValido`: `Valido` o `No valido`;
- `RegistroValido_Flag`: 1 o 0.

Las diferencias entre versiones se homologan en campos tecnicos:

- `UnidadNegocio_Homologada`;
- `TipoRetiro_Homologado`;
- `MotivoRetiro_Homologado`;
- `CategoriaPrincipalMotivo`;
- `SubcategoriaMotivo`;
- `CausaPrevenible`;
- `ProcesoRelacionado`;
- `RequierePlanAccion`.

En `Fct_EntrevistaRetiro_V2` no se identifico un campo explicito de unidad de negocio. Para la integracion inicial se asigna `CHALLENGER` como valor por defecto, dado el uso principal informado para esa version.

La categorizacion de motivos se realiza mediante reglas de palabras clave orientadas a lectura ejecutiva. Esta clasificacion debe validarse con Gestion Humana cuando se formalice el frente Bienestar y Clima.

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

### Desarrollo PDI

- `PDI Total`
- `PDI Colaboradores Unicos`
- `PDI Motivos Distintos`
- `PDI Jefes Con PDI`
- `PDI Cargos Con PDI`
- `PDI Avance Promedio`
- `PDI Activos`
- `PDI Finalizados`
- `PDI Pendientes`
- `PDI Porcentaje Activos`
- `PDI Porcentaje Por Estado`
- `PDI Porcentaje Por Motivo`
- `PDI Acompanamientos Programados`
- `PDI Acompanamientos Ejecutados`
- `PDI Cumplimiento Acompanamientos`
- `PDI Motivo Principal`
- `PDI Estado Principal`

`PDI Avance Promedio` normaliza el avance cuando la fuente viene en escala 0-100, para devolver siempre un porcentaje interpretable.

`PDI Motivo Principal` y `PDI Estado Principal` devuelven el motivo y el estado mas frecuente calculados sobre `PDI Total` (todos los registros, sin filtrar por estado activo). `PDI Estado Principal` itera sobre `Dim_EstadoPDI[Estado_PDI]` para garantizar valores en uppercase normalizado y excluir blancos. Ambas medidas alimentan `HTML Inicio Corporativo Propuesta 1`. No hubo cambios en relaciones, Power Query ni visual.json.

### Desarrollo alertas

- `PDI Avance Cero`
- `PDI Bajo Avance`
- `PDI Vencidos`
- `PDI Proximos A Vencer`
- `PDI Alertas Criticas`
- `PDI Ranking Area Total`
- `PDI Ranking Jefe Bajo Avance`

`PDI Alertas Criticas` identifica planes con avance cero, bajo avance o vencidos, y se usa en la pagina `D04 Focos de Gestion Desarrollo`.

### Entrevista de retiro

- `EntrevistaRetiro Total`
- `EntrevistaRetiro Total Validas`
- `EntrevistaRetiro Total No Validas`
- `EntrevistaRetiro Porcentaje Validas`
- `EntrevistaRetiro Total Voluntarios`
- `EntrevistaRetiro Total Involuntarios`
- `EntrevistaRetiro Porcentaje Voluntarios`
- `EntrevistaRetiro Porcentaje Involuntarios`
- `EntrevistaRetiro Total Fuentes`
- `EntrevistaRetiro Motivo Principal`
- `EntrevistaRetiro Total Motivos Distintos`
- `EntrevistaRetiro Participacion Motivo`
- `EntrevistaRetiro Participacion UnidadNegocio`
- `EntrevistaRetiro UnidadNegocio Top`
- `EntrevistaRetiro Causas Prevenibles`
- `EntrevistaRetiro Porcentaje Causas Prevenibles`
- `EntrevistaRetiro Variacion Mensual`
- `EntrevistaRetiro Variacion Mensual Porcentaje`
- `EntrevistaRetiro Registros Requieren Plan`

Las medidas gerenciales usan registros validos como base principal, aplicando `RegistroValido_Flag = 1`.

### KPI gerencial

`KPI Indice Aprendizaje` promedia los principales indicadores del bloque, excluyendo valores en blanco:

- `Plan Porcentaje Ejecucion`;
- `Plan Cobertura Asistencia`;
- `Encuesta Favorabilidad`;
- `Induccion Porcentaje Cumplimiento`.

`KPI Indice Desarrollo` promedia indicadores base del frente Desarrollo:

- `PDI Avance Promedio`;
- `PDI Cumplimiento Acompanamientos`;
- proporcion de PDI no vencidos.

## Observaciones importantes

- `Fct_PlanFormacion` es la fuente principal para horas de formacion, cobertura, eficacia, tipo de formacion y estado del plan.
- `Fct_AsistenciaFormacion` permite analizar asistencia real y se conecta con `Dim_ColaboradorHC` para lectura por tipo de cargo.
- `Fct_EncuestaFormacion` soporta satisfaccion, favorabilidad y percepcion de calidad.
- `Fct_Induccion` es la fuente gerencial consolidada para onboarding, entrenamiento y segmentacion UC.
- `Fct_EntrevistaRetiro_Unificada` es la fuente gerencial del modulo de entrevista de retiro en Bienestar y Clima, para motivos de salida, tendencias y oportunidades de mejora.
- `Fct_SeguimientoBienestar` es la fuente del modulo de plan de bienestar. Su estructura actividad x mes permite lectura mensual de cumplimiento, diferencias de programacion y alertas de pendientes vencidos.
- `Dim_ColaboradorHC` debe mantenerse actualizada por corte mensual para que el analisis de tipo de cargo sea confiable.
- `Fct_Seguimiento_PDI` es la fuente inicial del frente Desarrollo; los componentes de movilidad, sucesion y cargos criticos quedan como pendientes de fuente.

## Limitaciones y decisiones de modelado

- No se creo `Dim_CentroCosto` porque el centro o codigo aparece embebido en campos como `DEPENDENCIA` y no existe como campo estructurado independiente en todas las fuentes.
- No se creo `Dim_Proceso` porque no hay un campo comun y consistente de proceso entre las tablas de hechos.
- Los analisis por empresa del plan de formacion no deben interpretarse como calculos directos de `Fct_PlanFormacion`, ya que esta tabla no trae empresa.
- La tasa de respuesta de encuesta se calcula contra registros de asistencia disponibles; debe interpretarse como una tasa operacional sobre asistencia registrada, no como tasa oficial de convocados.
- En induccion pueden existir duplicados de documento entre cohortes; por eso el modelo mantiene medidas diferenciadas para registros y colaboradores unicos.
- La fecha activa de PDI es `Fecha_Inicio`. Las alertas por vencimiento usan `Fecha_Fin` dentro de las medidas para evitar una segunda relacion activa con calendario.
- La entrevista de retiro se analiza de forma agregada. Los textos abiertos deben tratarse con cautela por posible sensibilidad y no deben exponerse en visuales de detalle sin revision previa.
- La clasificacion de `CategoriaPrincipalMotivo` y `ProcesoRelacionado` es una primera homologacion tecnica basada en palabras clave; requiere validacion funcional antes de usarse como taxonomia oficial.
