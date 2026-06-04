# Dashboard Corporativo de Desarrollo Organizacional

## Objetivo

Este repositorio contiene el proyecto Power BI `Proyecto.pbip`, correspondiente al Dashboard Corporativo de Desarrollo Organizacional.

El objetivo es entregar una lectura gerencial, visual y accionable sobre los frentes de Desarrollo Organizacional, integrando indicadores de Aprendizaje y, desde esta fase, el seguimiento inicial de Planes de Desarrollo Individual del frente Desarrollo.

## Alcance del MVP

El alcance consolidado cubre el frente de Aprendizaje. El reporte permite analizar:

- avance del plan de formacion;
- horas de formacion;
- cobertura frente al publico objetivo;
- asistencia y participacion;
- satisfaccion y favorabilidad;
- eficacia de la formacion;
- onboarding e induccion;
- entrenamiento inicial al cargo;
- comparativos mensuales y anuales;
- indicadores ejecutivos para priorizacion gerencial.

El frente Desarrollo inicia su estructuracion con la tabla `Fct_Seguimiento_PDI`, orientada al seguimiento gerencial de Planes de Desarrollo Individual. Los frentes Desempeno y Bienestar y Clima continuan contemplados para fases posteriores.

## Estructura general

- `.gitignore`: reglas de exclusion para datos, backups, salidas temporales y archivos locales de Power BI.
- `Assets`: recursos visuales aprobados para el reporte.
- `Data`: archivos base de datos. Esta carpeta no se versiona por defecto.
- `Docs`: documentacion oficial del proyecto.
- `Outputs`: respuestas, borradores o entregables generados por herramientas de IA. No se versiona por defecto.
- `PBIP`: proyecto Power BI en formato PBIP.
- `Scripts`: scripts de soporte para ajustes del reporte, modelo o formato.
- `backups_codex`: respaldos locales generados durante intervenciones asistidas. No se versiona.

## Como abrir el proyecto

1. Abrir Power BI Desktop.
2. Seleccionar `Archivo > Abrir`.
3. Abrir `PBIP/Proyecto.pbip`.
4. Esperar la carga del reporte y del modelo semantico.
5. Guardar cambios desde Power BI Desktop cuando se modifiquen visuales, modelo o medidas.

Cuando tambien se realicen cambios desde VS Code, se recomienda revisar `git status` antes y despues de abrir Power BI Desktop, porque Power BI puede actualizar archivos JSON o TMDL al guardar.

## Estado actual del desarrollo

El frente Aprendizaje se encuentra consolidado con siete paginas:

- `00 Inicio Corporativo`
- `A01 Resumen Ejecutivo Aprendizaje`
- `A02 Plan y Ejecucion`
- `A03 Cobertura y Participacion`
- `A04 Satisfaccion y Eficacia`
- `A05 Induccion y Entrenamiento`
- `A06 Focos de Gestion`

El frente Desarrollo inicia con cuatro paginas:

- `D01 Resumen Ejecutivo Desarrollo`
- `D02 Estado y Avance PDI`
- `D03 Motivos y Seguimiento`
- `D04 Focos de Gestion Desarrollo`

El modelo incluye dimensiones gerenciales, tabla de medidas `Medidas_AD`, fact consolidada de induccion, relacion entre `Fct_AsistenciaFormacion` y `Dim_ColaboradorHC`, y estructura inicial para `Fct_Seguimiento_PDI`.

## Bloques pendientes del Dashboard Corporativo

Los siguientes bloques estan previstos para fases posteriores:

- Desempeno
- Bienestar y Clima

Estos frentes deben integrarse respetando la arquitectura corporativa, la navegacion del reporte, la paleta visual LEMCO y los estandares tecnicos documentados en `Docs`.
