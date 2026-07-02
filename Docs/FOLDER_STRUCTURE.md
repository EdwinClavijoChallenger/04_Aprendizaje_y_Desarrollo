# Estructura de carpetas

## Raiz del repositorio

La raiz debe mantenerse limpia. Solo deben existir archivos de configuracion o entrada general, como:

- `README.md`
- `.gitignore`

No se deben crear archivos sueltos en la raiz sin justificacion.

## `PBIP`

Contiene el proyecto Power BI en formato PBIP.

- `Proyecto.pbip`: archivo principal para abrir en Power BI Desktop.
- `Proyecto.Report`: definicion del reporte, paginas y visuales.
- `Proyecto.SemanticModel`: modelo semantico, tablas, relaciones y medidas.

Esta carpeta hace parte formal del proyecto y debe versionarse.

## `Docs`

Contiene la documentacion oficial del proyecto.

Usar esta carpeta para:

- contexto del proyecto;
- instrucciones de trabajo;
- reglas de commits;
- documentacion de modelo;
- lineamientos de marca;
- estructura del repositorio;
- notas metodologicas aprobadas.

El archivo `Manual Marca Grupo LEMCO.pdf` es una referencia de marca y esta excluido del versionamiento por su peso.

## `Data`

Contiene archivos base de datos o insumos locales. Esta carpeta no se versiona por defecto porque puede contener informacion sensible o pesada.

Los archivos de datos solo deben versionarse si existe autorizacion explicita y si no contienen informacion sensible.

## `Scripts`

Contiene scripts de soporte historicos o utilitarios puntuales para el PBIP.

La prioridad del proyecto es preservar el PBIP actual. Por tanto, esta carpeta no debe entenderse como una fuente para reconstruir paginas, resetear el reporte o reaplicar branding masivo.

Uso permitido:

- validaciones puntuales;
- ajustes finos de formato;
- soporte controlado sobre tarjetas o propiedades visuales especificas;
- utilidades aprobadas previamente por el usuario.

Uso no permitido sin autorizacion expresa:

- reconstruir paginas completas;
- eliminar o regenerar visuales;
- resetear el reporte;
- reaplicar branding masivo;
- reemplazar la estructura visual aprobada;
- modificar navegacion o estructura del PBIP.

El estandar visual vigente esta definido por la pagina `00 Inicio Corporativo - Propuesta 1` y por el tema JSON del reporte.

La clasificacion detallada de scripts debe mantenerse en `Docs/SCRIPTS_GOVERNANCE.md`.

## `tools`

Contiene herramientas locales de apoyo tecnico y diagnostico. Su uso debe ser de solo lectura por defecto salvo autorizacion explicita, y no debe modificar el PBIP ni reemplazar validaciones en Power BI Desktop.

Organizacion vigente:

- `tools/pbip/`: herramientas relacionadas con estructura PBIP, paginas, modelo, inventarios o diagnosticos tecnicos.
- `tools/governance/`: herramientas de control documental, revision Git, precommit y gobierno del repositorio.

Tools activas actuales:

- `tools/pbip/list_pbip_structure.py`
- `tools/governance/prepare_commit_review.py`

## `.agents`

Contiene assets compartidos del repositorio para asistentes de IA.

Ubicacion oficial de skills del proyecto:

- `.agents/skills/`

Reglas:

- cada skill debe vivir en carpeta propia;
- cada skill debe incluir `SKILL.md` como archivo obligatorio;
- puede incluir carpetas opcionales como `references/`, `scripts/`, `assets/` y `agents/openai.yaml`;
- ninguna skill debe ejecutar commit, push, borrado de archivos o cambios criticos sin autorizacion explicita del usuario.

Skills activas actuales:

- `.agents/skills/powerbi_signals/SKILL.md`
- `.agents/skills/pbi_aprendizaje_inventario/SKILL.md`
- `.agents/skills/pbi_commit_prep/SKILL.md`

## `.codex`

Contiene configuracion o contexto local del entorno Codex.

Regla vigente:

- `.codex/skills/` queda reservada para pruebas locales, overrides o experimentacion del usuario;
- no debe usarse como ubicacion oficial de skills compartidas del repositorio.

## `Skills`

La carpeta `Skills/` fue una estructura legacy del repositorio.

Estado actual:

- ya no es la ubicacion oficial de skills;
- no debe recrearse para nuevas automatizaciones;
- si aparece en historial, backups o referencias antiguas, debe tratarse como legado.

## `Assets`

Contiene recursos visuales aprobados.

Usar esta carpeta para:

- logos;
- iconos;
- imagenes;
- temas visuales;
- recursos corporativos autorizados.

## `Outputs`

Contiene archivos generados por IA, borradores, respuestas, pruebas o entregables temporales.

Esta carpeta no debe versionarse automaticamente. Si un archivo generado alli se convierte en documentacion oficial, debe moverse a `Docs` o ser aprobado explicitamente antes de incluirse en Git.

## `backups_codex`

Contiene respaldos locales generados durante intervenciones asistidas.

No debe versionarse.

## `.claude`

Carpeta de configuracion o contexto local de herramientas de IA. No debe usarse como documentacion oficial del proyecto.
