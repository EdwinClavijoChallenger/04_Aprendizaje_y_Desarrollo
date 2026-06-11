# Gobierno de scripts del proyecto

Este documento define el criterio de uso, clasificacion y restricciones para los scripts del proyecto PBIP.

## Principio general

El PBIP actual debe preservarse. No se deben ejecutar scripts que reconstruyan paginas, reseteen el reporte, regeneren visuales o reapliquen branding masivo sin autorizacion expresa del usuario.

El estandar visual vigente se basa en:

- la pagina `00 Inicio Corporativo - Propuesta 1`, aprobada como referencia visual;
- el tema JSON del reporte;
- ajustes puntuales realizados sobre paginas existentes.

## Clasificacion de scripts

| Script | Estado | Uso permitido |
|---|---|---|
| `ApplyExecutiveDashboard.ps1` | No operativo / deprecated | No usar. Puede reconstruir paginas y sobrescribir avances actuales. |
| `ResetToDefault.ps1` | Legacy / recuperacion controlada | Solo historico o recuperacion excepcional con autorizacion expresa. |
| `ReplaceHomeNivelCargoWithTipoCargo.ps1` | Deprecated | No usar. Ajuste puntual ya superado. |
| `ApplyBrandTheme.ps1` | Legacy / no operativo | No usar como herramienta de branding masivo. |
| `ApplyLemcoVisualStyle.ps1` | Legacy con referencia tecnica | No usar operativamente sin refactor y autorizacion. |
| `ApplyCardFontSizes.ps1` | Utilitario vigente con cautela | Solo ajustes finos de tarjetas. |
| `DisableCategoryLabel.ps1` | Utilitario vigente con cautela | Solo desactivacion de etiquetas de categoria en tarjetas. |

## Reglas antes de ejecutar scripts

Antes de ejecutar cualquier script se debe:

- revisar `git status`;
- identificar archivos que podria modificar;
- validar si Power BI Desktop esta abierto;
- confirmar que no afecta paginas completas, navegacion ni estructura;
- explicar el impacto esperado;
- solicitar autorizacion expresa del usuario.

## Scripts no operativos

Los scripts clasificados como deprecated, legacy o no operativos no deben ejecutarse como parte del flujo normal de desarrollo.

Si se requiere recuperar logica de alguno de ellos, primero debe revisarse manualmente su contenido y proponerse una estrategia puntual, sin ejecutar el script completo.

## Scripts utilitarios vigentes

Solo se consideran vigentes los scripts que realicen ajustes acotados y seguros, sin competir con el tema JSON ni con la plantilla visual aprobada.

Cualquier nuevo script debe documentar:

- objetivo;
- alcance;
- archivos afectados;
- si modifica modelo, reporte, tema o visuales;
- instrucciones de ejecucion;
- modo seguro o de simulacion, si aplica.

## Criterio de preservacion

La prioridad es proteger el avance funcional y visual del PBIP actual.

No se deben usar scripts para rehacer el home, regenerar paginas, resetear configuraciones, reaplicar estructuras completas o reemplazar decisiones visuales ya aprobadas.

Cuando exista una necesidad de ajuste, debe preferirse:

1. analisis del estado actual;
2. propuesta puntual;
3. validacion del impacto;
4. autorizacion del usuario;
5. cambio acotado y verificable.
