# Contexto del proyecto

## Dashboard Corporativo de Desarrollo Organizacional

El proyecto hace parte del piloto del Dashboard Corporativo de Desarrollo Organizacional. La vision del dashboard es consolidar informacion gerencial de los principales frentes de Gestion Humana relacionados con desarrollo organizacional.

La arquitectura contempla cuatro bloques:

- Aprendizaje
- Desempeno
- Desarrollo
- Bienestar y Clima

## Bloques en desarrollo

El bloque con mayor avance es Aprendizaje. Este MVP permite hacer seguimiento a la gestion de formacion, cobertura, asistencia, satisfaccion, eficacia, onboarding, entrenamiento inicial al cargo y hallazgos de gestion.

El bloque Desarrollo inicia su construccion con el seguimiento de Planes de Desarrollo Individual mediante `Fct_Seguimiento_PDI`. Esta fase permite analizar motivos de apertura, estados, avance, acompanamientos, vencimientos y focos de gestion por empresa, area, cargo y jefe inmediato.

El bloque Bienestar y Clima inicia su construccion con el analisis de entrevistas de retiro. La arquitectura del home corporativo representa cuatro componentes del frente:

- Entrevista de Retiro;
- Planes de trabajo de Clima Laboral;
- eNPS de actividades de Bienestar;
- Cumplimiento del Plan de Bienestar.

La fase actual permite revisar motivos de salida, tipos de retiro, unidades de negocio con mayor concentracion, tendencias mensuales, causas potencialmente prevenibles y procesos asociados a oportunidades de mejora. Los componentes de clima, eNPS y plan de bienestar quedan visibles como roadmap funcional hasta incorporar sus fuentes.

## Proximos bloques

Los frentes o componentes pendientes son:

- Desempeno
- Planes de trabajo de Clima Laboral
- eNPS de actividades de Bienestar
- Cumplimiento del Plan de Bienestar

La pagina `00 Inicio Corporativo` funciona como entrada corporativa. Actualmente muestra Aprendizaje como frente consolidado, Desarrollo como frente iniciado con PDI y Bienestar y Clima como frente iniciado con Entrevista de Retiro, manteniendo placeholders para componentes futuros como movilidad, sucesion, cargos criticos, clima laboral, eNPS y cumplimiento del plan de bienestar.

El panel del frente Desarrollo en el Home muestra: motivo PDI principal (medida `PDI Motivo Principal`), estado predominante con barra de avance (medidas `PDI Estado Principal` y `PDI Avance Promedio`), placeholders para Movilidad, Sucesion y Cargos criticos, y KPIs de alertas criticas e indice de desarrollo. Todo el panel es renderizado por `HTML Inicio Corporativo Propuesta 1`.

La navegacion debe mantener una ruta clara desde el inicio corporativo hacia los frentes funcionales. Cuando se agreguen nuevas paginas, se debe validar si pertenecen a Aprendizaje, Desarrollo u otro frente futuro, y si requieren acceso desde el menu principal o desde una navegacion secundaria.

## Publico objetivo

El publico principal es gerencial. Por esta razon, el reporte prioriza:

- lectura rapida;
- indicadores ejecutivos;
- comparativos;
- brechas;
- tendencias;
- focos de gestion;
- decisiones accionables.

## Enfoque analitico

El dashboard no debe limitarse a describir datos. Debe ayudar a responder:

- que tan bien se esta ejecutando el plan;
- que cobertura real tiene la formacion;
- que tan satisfechos estan los participantes;
- que tan eficaz es la formacion;
- como avanza el onboarding;
- como se comporta el entrenamiento inicial;
- que estado y avance tienen los Planes de Desarrollo Individual;
- donde hay PDI vencidos, sin avance o con bajo acompanamiento;
- cuales son los principales motivos de salida;
- que unidades de negocio concentran mas entrevistas de retiro;
- que causas de salida pueden prevenirse con acciones de Gestion Humana;
- donde existen brechas por empresa, area, tipo de formacion o periodo.

La narrativa del reporte debe mantener orden gerencial: contexto, resumen, avance, cobertura, calidad, induccion, entrenamiento, desarrollo individual, entrevista de retiro y focos de decision.
