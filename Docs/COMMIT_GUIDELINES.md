# Guia de commits

## Convencion

El repositorio usa Conventional Commits.

Formato:

```text
tipo(alcance): descripcion breve en espanol
```

## Tipos permitidos

- `feat`: nueva funcionalidad, medida, pagina, visual o capacidad del modelo.
- `fix`: correccion de errores, calculos, codificacion, visuales rotos o relaciones.
- `chore`: tareas de mantenimiento sin cambio funcional directo.
- `refactor`: reorganizacion interna sin cambiar el comportamiento esperado.
- `docs`: documentacion oficial del proyecto.
- `style`: ajustes visuales, formato o presentacion sin cambio de logica.

## Alcances sugeridos

- `model`
- `dax`
- `visuals`
- `theme`
- `data`
- `docs`
- `config`
- `pbip`

Tambien se puede usar un alcance funcional cuando aporte claridad, por ejemplo `aprendizaje`.

## Ejemplos

```text
feat(dax): agrega indicadores de entrenamiento
```

```text
fix(visuals): corrige tarjeta de onboarding en inicio corporativo
```

```text
docs(docs): documenta arquitectura del MVP de aprendizaje
```

```text
style(theme): aplica paleta corporativa LEMCO
```

## Regla obligatoria antes de commit

Antes de ejecutar cualquier commit, se debe mostrar al usuario:

- archivos modificados;
- archivos nuevos;
- archivos excluidos;
- documentos que deberian actualizarse o confirmacion de que no aplica actualizar documentacion;
- resumen breve de cambios;
- mensaje de commit propuesto;
- cuerpo del commit propuesto;
- criterio de inclusion y exclusion, especialmente para `Outputs`.

El commit solo debe ejecutarse despues de autorizacion explicita.

## Regla de documentacion obligatoria

Cada vez que se realice un cambio funcional, visual, de modelo, medidas DAX, estructura de carpetas, fuentes de datos o configuracion del proyecto, se debe revisar si la documentacion oficial debe actualizarse.

Antes de finalizar la tarea, validar si aplica actualizar:

- `README.md`
- `Docs/PROJECT_CONTEXT.md`
- `Docs/AI_INSTRUCTIONS.md`
- `Docs/COMMIT_GUIDELINES.md`
- `Docs/FOLDER_STRUCTURE.md`
- `Docs/BRAND_GUIDELINES.md`
- `Docs/DATA_MODEL.md`

Si el cambio impacta modelo de datos, medidas, relaciones, visualizaciones, estructura del proyecto o reglas de trabajo, se debe proponer la actualizacion documental correspondiente antes de hacer commit.

## Regla sobre Outputs

La carpeta `Outputs` puede contener respuestas, borradores, pruebas o entregables generados por IA. No debe incluirse automaticamente en commits.

Solo se puede versionar un archivo de `Outputs` si el usuario confirma que hace parte formal de:

- trazabilidad tecnica;
- documentacion funcional oficial;
- mantenimiento del proyecto;
- entregable aprobado del repositorio.

En caso contrario, debe mantenerse fuera del commit.
