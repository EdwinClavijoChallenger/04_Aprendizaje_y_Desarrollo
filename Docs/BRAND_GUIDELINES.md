# Lineamientos de marca para el dashboard

Este documento resume la aplicacion del Manual Marca Grupo LEMCO al dashboard Power BI.

## Principios visuales

- Mantener una estetica sobria, corporativa y ejecutiva.
- Priorizar claridad, comparacion y accionabilidad.
- Evitar visuales recargados o decorativos sin valor analitico.
- Mantener consistencia entre paginas.
- Usar jerarquia visual clara: encabezado, KPIs, analisis principal y detalle.
- Reducir la carga cognitiva del usuario y orientar la toma de decisiones a partir de los datos.
- Mantener titulos comprensibles para usuarios tecnicos y no tecnicos.

## Colores

- Fondo preferido: blanco o gris muy claro.
- Color principal: azul corporativo.
- Color base recomendado para comparativos: `#003A70`.
- Color de contraste: naranja `#F7931E`.
- Usar el naranja como acento para destacar variaciones, alertas o elementos activos, no como color dominante.
- Evitar paletas genericas que no reflejen identidad LEMCO.

## Tipografia y tamanos

- Mantener fuentes limpias y ejecutivas.
- Usar tamanos consistentes en todo el reporte.
- Para tarjetas/globos:
  - titulo: 12;
  - valor principal: 16;
  - etiquetas de categoria desactivadas cuando aplique.

## Segmentadores

- Los segmentadores deben ser visibles, utiles y consistentes.
- Desactivar `Encabezado de segmentacion` cuando aplique para mantener limpieza visual.
- Priorizar filtros por anio, mes, empresa, area, tipo de formacion, modalidad, estado y segmento UC.

## Navegacion

- La pagina `00 Inicio Corporativo` debe funcionar como entrada principal del dashboard corporativo.
- Las paginas del frente Aprendizaje deben mantener prefijo `A` y las paginas del frente Desarrollo deben mantener prefijo `D`, salvo decision aprobada.
- El menu de navegacion debe agrupar las paginas por frente funcional para que usuarios no tecnicos puedan recorrer el reporte sin depender solo de las pestanas inferiores de Power BI.
- La navegacion debe ser simple, visible, consistente y con estados activo/inactivo claros.
- El azul corporativo debe usarse como base del menu y el naranja `#F7931E` como acento para pagina activa, frente activo o accion principal.
- Cada vez que se agregue una nueva pagina al reporte, se debe revisar si debe incorporarse al menu de navegacion, al home corporativo o a un acceso secundario. No deben quedar paginas nuevas sin ruta clara de acceso para el usuario final.
- Si una pagina es de trabajo, prueba o mantenimiento y no debe exponerse al usuario final, debe documentarse o mantenerse oculta segun corresponda.

### Implementacion actual

- El reporte usa un menu inferior compacto para no competir con la franja superior de filtros.
- `00 Inicio Corporativo` incluye accesos por bloque: Inicio, Aprendizaje, Desarrollo, Desempeno y Bienestar y Clima. Los bloques sin desarrollo activo deben verse como placeholders deshabilitados.
- Las paginas del frente Aprendizaje incluyen acceso a Inicio, paginas principales del frente y entrada al frente Desarrollo.
- Las paginas del frente Desarrollo incluyen acceso a Inicio, entrada al frente Aprendizaje y paginas principales del frente Desarrollo.
- El estado activo usa naranja `#F7931E`; los accesos inactivos usan fondo blanco con azul corporativo; los placeholders usan gris neutro.
- Los accesos hacia otro frente dentro de un menu de frente deben diferenciarse con relleno azul corporativo y texto blanco, manteniendo el mismo tamano, tipografia y comportamiento de navegacion.
- La navegacion se implementa con visuales de tipo `actionButton` y accion `PageNavigation`.

## Composicion

- Filtros y contexto general en la parte superior.
- KPIs principales visibles al inicio de la pagina.
- Visualizaciones analiticas en la zona central.
- Detalle operativo o tablas de seguimiento en zonas secundarias.
- Encabezado claro por pagina.
- Alineacion uniforme y uso medido del espacio en blanco.
- Evitar exceso de tablas y graficos redundantes.

## Patrones de lectura

- Para paginas con mayor carga analitica, priorizar una composicion tipo patron F, ubicando los elementos mas relevantes en la parte superior y lateral izquierda del lienzo.
- Para paginas ejecutivas, de resumen o introduccion, se puede usar una composicion tipo patron Z, guiando al usuario desde el contexto inicial hasta una conclusion o foco de accion.
- Mantener ubicacion consistente de filtros, estilo de tarjetas, titulos y nomenclatura entre paginas.

## Accesibilidad

- Mantener contraste suficiente entre texto, fondo y elementos graficos.
- Usar color de forma moderada y con intencion analitica.
- Evitar depender exclusivamente del color para comunicar estados, alertas o prioridades.
- Mantener textos legibles y titulos autoexplicativos.
- Priorizar navegacion simple y consistente entre frentes.

## Barras y rankings

- Usar barras limpias, con poco ruido visual y sin elementos decorativos.
- Priorizar el azul corporativo como color base de las barras.
- Usar naranja `#F7931E` como color de contraste para destacar categorias clave, segundos lugares, alertas o comparativos relevantes.
- Mantener etiquetas de datos visibles y legibles, preferiblemente con contraste alto sobre la barra.
- Evitar paletas multicolor cuando no exista una razon analitica clara.
- Mantener ejes, cuadriculas y bordes discretos para reforzar una lectura ejecutiva.

## Aplicacion en el MVP

Los frentes del dashboard deben mantener identidad visual consistente con:

- `00 Inicio Corporativo`;
- paginas del frente Aprendizaje con prefijo `A`;
- paginas del frente Desarrollo con prefijo `D`;
- paginas de analisis por plan, cobertura, satisfaccion, induccion, PDI y focos;
- indicadores clave de cada frente.

La experiencia debe sentirse como un dashboard corporativo integrado, no como paginas sueltas.
