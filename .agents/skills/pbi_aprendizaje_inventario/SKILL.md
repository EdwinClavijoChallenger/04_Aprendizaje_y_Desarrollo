---
name: pbi-aprendizaje-inventario
description: Inspect the local Power BI PBIP project structure and generate a fast inventory using the PBIP structure tool. Use when the user asks for project inventory, repo map, initial review, or quick diagnostics.
---

# pbi-aprendizaje-inventario

## Proposito

Usar la herramienta local `tools/pbip/list_pbip_structure.py` para levantar un inventario rapido, estructurado y repetible del proyecto Power BI PBIP de Aprendizaje antes de explorar manualmente carpetas, paginas o archivos del modelo.

Esta skill reduce consumo de tokens porque la primera evidencia debe venir del JSON generado por la herramienta, no de una exploracion manual completa del arbol del proyecto.

## Cuando usarla

Usar esta skill cuando el usuario pida:

- inventario del proyecto Power BI PBIP;
- estructura del proyecto;
- revision inicial;
- diagnostico rapido;
- mapa de paginas, visuales, Docs u Outputs;
- contexto inicial para trabajar sobre el dashboard de Aprendizaje.

## Restricciones

- No modificar PBIP.
- No modificar Docs.
- No modificar Outputs.
- No hacer staging.
- No hacer commit.
- No hacer push.
- No usar internet.
- No ejecutar scripts de transformacion del reporte.
- No leer contenido completo de Outputs o Docs salvo que el usuario lo pida despues.

## Flujo obligatorio

Antes de explorar manualmente el proyecto, ejecutar:

```powershell
python tools/pbip/list_pbip_structure.py . --pretty
```

Despues:

1. Tomar la salida JSON como evidencia inicial.
2. Revisar primero los campos principales del JSON:
   - `archivos_pbip`
   - `rutas_clave`
   - `paginas_reporte`
   - `documentacion.archivos`
   - `outputs.archivos`
   - `errores`
3. Solo si el JSON muestra errores, rutas faltantes o inconsistencias, hacer inspecciones puntuales adicionales con comandos de solo lectura.
4. No modificar archivos del proyecto durante el diagnostico.

## Evidencia que debe resumirse

El resumen debe cubrir:

- archivos `.pbip` detectados;
- carpetas clave y si existen;
- total de paginas;
- paginas del reporte;
- cantidad de visuales por pagina;
- archivos disponibles en `Docs`;
- archivos disponibles en `Outputs`;
- errores de lectura, JSON invalido o rutas faltantes.

## Riesgos a identificar

Revisar y reportar, si aplica:

- paginas sin visuales;
- carpetas faltantes;
- archivos JSON invalidos reportados por la herramienta;
- diferencias o ausencias entre `PBIP`, `Proyecto.Report` y `Proyecto.SemanticModel`;
- exceso de archivos en `Outputs` que pueda dificultar orientacion;
- documentacion dispersa o demasiado amplia para una revision rapida.

## Formato de respuesta

Responder en este orden:

1. **Resumen ejecutivo**
   - Estado general del inventario.
   - Si el PBIP, Report y SemanticModel existen.
   - Conteos principales.

2. **Inventario tecnico**
   - Archivos `.pbip`.
   - Carpetas clave.
   - Paginas y visuales.
   - Docs.
   - Outputs.

3. **Hallazgos relevantes**
   - Observaciones concretas basadas en la salida JSON.
   - Incluir rutas relativas cuando aporten evidencia.

4. **Riesgos**
   - Riesgos detectados segun los criterios de esta skill.
   - Distinguir entre riesgo confirmado y punto por validar.

5. **Proximos pasos recomendados**
   - Proponer acciones de revision o diagnostico.
   - No proponer cambios directos sobre PBIP salvo que sean para una tarea futura y con autorizacion explicita.

## Ejemplo de uso

Usuario:

```text
Haz un inventario rapido del proyecto PBIP de Aprendizaje.
```

Respuesta esperada de Codex:

1. Ejecutar `python tools/pbip/list_pbip_structure.py . --pretty`.
2. Usar el JSON como evidencia.
3. Resumir inventario, hallazgos, riesgos y proximos pasos.
4. Confirmar que no modifico PBIP, Docs ni Outputs.
