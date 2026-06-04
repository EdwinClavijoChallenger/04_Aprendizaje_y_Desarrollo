# Instrucciones para IA en este proyecto

Este documento define reglas obligatorias para cualquier IA o asistente que trabaje sobre el proyecto PBIP.

## Reglas generales

- Analizar el estado actual del proyecto antes de modificar archivos.
- Explicar el impacto esperado antes de realizar cambios relevantes.
- No crear archivos fuera de carpetas existentes o aprobadas.
- No sobrescribir cambios manuales del usuario.
- No revertir archivos sin autorizacion explicita.
- No ejecutar commits sin autorizacion previa del usuario.
- Respetar la estructura del repositorio.
- Mantener buenas practicas de desarrollo de software.
- Usar nombres tecnicos sin tildes, enes ni caracteres especiales cuando se trate de medidas, columnas, tablas, scripts o archivos tecnicos.
- Aplicar los lineamientos del Manual Marca Grupo LEMCO cuando se modifiquen visuales, temas o estilos.

## Trabajo sobre PBIP

- El archivo principal es `PBIP/Proyecto.pbip`.
- Antes de editar JSON o TMDL, revisar `git status`.
- Si Power BI Desktop esta abierto, asumir que el usuario puede estar realizando cambios manuales.
- No regenerar paginas, visuales o medidas sin validar primero el estado actual.
- Evitar cambios masivos si una correccion puntual es suficiente.
- Validar que los JSON queden en UTF-8 sin BOM.
- Validar que los JSON parseen correctamente despues de ediciones manuales.

## Documentacion

- La documentacion oficial debe guardarse en `Docs`.
- El `README.md` raiz se permite como documento de entrada del repositorio.
- La carpeta `Outputs` se reserva para respuestas, borradores o entregables generados por IA y no debe versionarse automaticamente.
- No usar `Outputs` como fuente oficial salvo aprobacion explicita.
- Cada cambio funcional, visual, de modelo, medidas DAX, estructura de carpetas, fuentes de datos o configuracion debe disparar una revision documental.
- Antes de finalizar una tarea, validar si aplica actualizar `README.md`, `Docs/PROJECT_CONTEXT.md`, `Docs/AI_INSTRUCTIONS.md`, `Docs/COMMIT_GUIDELINES.md`, `Docs/FOLDER_STRUCTURE.md`, `Docs/BRAND_GUIDELINES.md` o `Docs/DATA_MODEL.md`.
- Si el cambio impacta modelo, medidas, relaciones, visualizaciones, estructura del proyecto o reglas de trabajo, proponer la actualizacion documental correspondiente antes de cerrar.
- No actualizar documentacion sin autorizacion previa cuando el usuario haya pedido validar primero el impacto documental.

## Versionamiento

Antes de proponer un commit, mostrar:

- archivos modificados;
- archivos nuevos;
- archivos excluidos;
- documentos que deberian actualizarse o confirmacion de que no aplica actualizar documentacion;
- criterio aplicado para incluir o excluir;
- resumen de cambios;
- mensaje de commit propuesto;
- cuerpo del commit propuesto.

El commit solo puede ejecutarse despues de aprobacion explicita del usuario.

## Cuidado con cambios del usuario

Si aparecen cambios que no fueron hechos por la IA:

- no revertirlos;
- no sobrescribirlos;
- revisarlos si afectan la tarea;
- trabajar con ellos cuando sea posible;
- pedir confirmacion solo si impiden completar el trabajo de forma segura.
