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
- Mantener nomenclatura de paginas por frente: `A` para Aprendizaje, `D` para Desarrollo, `BC` para Bienestar y Clima y `00` para Inicio Corporativo, salvo instruccion explicita distinta.
- Cada vez que se agregue una pagina nueva, revisar si debe incorporarse al menu de navegacion, al home corporativo o a un acceso secundario. No dejar paginas nuevas sin acceso claro para el usuario final.
- No cambiar nombres internos de paginas ni su orden sin informar primero el impacto y recibir autorizacion cuando el cambio afecte navegacion o experiencia de usuario.
- Validar que los archivos TMDL queden en UTF-8 sin BOM. Si un TMDL fue editado fuera de PBI Desktop con una herramienta que use Latin-1, puede generar doble codificacion (patron visible: `Ã©`, `Ã³`, `Â¿` en lugar de caracteres correctos). Corregir con reemplazo directo en el archivo antes de abrir en PBI Desktop.
- En medidas TMDL, las propiedades `displayFolder` y `lineageTag` deben estar a 2 tabs (nivel de propiedad de medida). Si quedan a 3 tabs o mas quedan dentro del cuerpo DAX y PBI Desktop genera error de parse al abrir la medida.
- Las medidas HTML de tipo shell deben seguir la nomenclatura `HTML Shell {CodigoFrente} {TituloPagina}`. Las medidas de inicio corporativo usan `HTML Inicio Corporativo Propuesta {N}`. Todas las medidas HTML deben estar en la carpeta de display `11 HTML Content` del modelo semantico.
- El esqueleto estandar de medidas HTML Shell tiene: canvas 1280x720, fondo `#F7F9FC`, encabezado oscuro `#0B1C35` de 100px, supra `DASHBOARD CORPORATIVO - GRUPO LEMCO` en naranja `#F7931E`, barra de filtros a `top:112px` alto `76px`, grid de 6 slots a `left:238px top:121px`, contenedor principal a `top:198px` alto `468px` y barra inferior a `top:674px` alto `40px`.

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

## Scripts y proteccion del PBIP actual

- El PBIP actual debe preservarse. No se deben reconstruir paginas, resetear el reporte, regenerar visuales ni reaplicar estructuras completas sin autorizacion expresa del usuario.
- El estandar visual vigente del reporte esta gobernado por la pagina `00 Inicio Corporativo - Propuesta 1` aprobada y por el tema JSON del reporte.
- No se deben ejecutar scripts que dupliquen, contradigan o sobrescriban el branding definido por el tema JSON o por el formato visual ya aprobado.
- Los cambios sobre paginas existentes deben ser puntuales, controlados y previamente explicados.
- Antes de ejecutar cualquier script, validar `git status`, alcance esperado, archivos afectados y si Power BI Desktop esta abierto.
- No ejecutar scripts de reconstruccion, reset o branding masivo sin autorizacion explicita del usuario.
- Los scripts solo pueden considerarse vigentes si hacen ajustes finos, seguros y acotados, como formato de tarjetas o desactivacion de etiquetas, sin tocar navegacion, estructura ni paginas completas.

### Clasificacion operativa de scripts

- `Scripts/ApplyExecutiveDashboard.ps1`: no operativo / deprecated. No debe usarse porque puede reconstruir paginas y sobrescribir avances actuales del PBIP.
- `Scripts/ResetToDefault.ps1`: legacy / solo historico o recuperacion controlada. No debe ejecutarse sobre el reporte actual sin autorizacion expresa.
- `Scripts/ReplaceHomeNivelCargoWithTipoCargo.ps1`: deprecated. Fue un ajuste puntual ya superado.
- `Scripts/ApplyBrandTheme.ps1`: legacy / no operativo. El branding debe gobernarse desde el tema JSON y la plantilla visual aprobada.
- `Scripts/ApplyLemcoVisualStyle.ps1`: legacy con posible referencia tecnica. No debe usarse como herramienta operativa de branding masivo.
- `Scripts/ApplyCardFontSizes.ps1`: utilitario vigente con cautela, solo para ajustes finos de tarjetas.
- `Scripts/DisableCategoryLabel.ps1`: utilitario vigente con cautela, solo para desactivar etiquetas de categoria en tarjetas.

Si existe duda sobre el impacto de un script, no ejecutarlo. Primero documentar el alcance, proponer el uso y pedir autorizacion.
