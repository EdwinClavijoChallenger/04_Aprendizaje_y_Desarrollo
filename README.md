# MVP Aprendizaje - Dashboard Corporativo de Desarrollo Organizacional

## Objetivo

Este repositorio contiene el proyecto Power BI `Proyecto.pbip`, correspondiente al MVP del bloque de Aprendizaje dentro del Dashboard Corporativo de Desarrollo Organizacional.

El objetivo del MVP es entregar una lectura gerencial, visual y accionable sobre la gestion de Aprendizaje y Desarrollo, integrando plan de formacion, cobertura, asistencia, satisfaccion, eficacia, onboarding, entrenamiento y focos de gestion.

## Alcance del MVP

El alcance actual cubre el frente de Aprendizaje. El reporte permite analizar:

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

Los frentes Desempeno, Desarrollo, Bienestar y Clima estan contemplados en la arquitectura corporativa, pero aun no hacen parte del MVP desarrollado.

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

El MVP de Aprendizaje se encuentra consolidado con siete paginas:

- `00 Inicio Corporativo`
- `01 Resumen Ejecutivo Aprendizaje`
- `02 Plan y Ejecucion`
- `03 Cobertura y Participacion`
- `04 Satisfaccion y Eficacia`
- `05 Induccion y Entrenamiento`
- `06 Focos de Gestion`

El modelo incluye dimensiones gerenciales, tabla de medidas `Medidas_AD`, fact consolidada de induccion y relacion entre `Fct_AsistenciaFormacion` y `Dim_ColaboradorHC` mediante `Colaborador_Key`.

## Bloques pendientes del Dashboard Corporativo

Los siguientes bloques estan previstos para fases posteriores:

- Desempeno
- Desarrollo
- Bienestar y Clima

Estos frentes deben integrarse respetando la arquitectura corporativa, la navegacion del reporte, la paleta visual LEMCO y los estandares tecnicos documentados en `Docs`.
