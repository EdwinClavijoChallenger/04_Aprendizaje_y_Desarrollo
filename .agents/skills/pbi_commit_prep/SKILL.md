---
name: pbi-commit-prep
description: Prepare a controlled commit review for the local Power BI PBIP project using git evidence and commit governance rules. Use when the user asks to review changes, prepare a commit, or separate commit scope.
---

# pbi-commit-prep

## Proposito

Preparar commits controlados del proyecto Power BI PBIP usando evidencia JSON generada por `tools/governance/prepare_commit_review.py` y las reglas de `Docs/COMMIT_GUIDELINES.md`.

## Cuando usarla

Usar esta skill cuando el usuario pida:

- preparar commit;
- revisar ultimos cambios;
- cerrar bloque de trabajo;
- proponer commit;
- validar archivos antes de versionar;
- separar cambios PBIP, documentacion, tools o skills.

## Flujo obligatorio

1. Ejecutar primero:

```powershell
python tools/governance/prepare_commit_review.py . --pretty
```

2. Usar el JSON como evidencia principal.
3. Revisar `Docs/COMMIT_GUIDELINES.md` antes de proponer mensaje o cuerpo de commit.
4. No hacer staging, commit ni push sin autorizacion explicita del usuario.
5. Si el usuario autoriza staging, usar rutas explicitas con `git add -- archivo1 archivo2`.

## Formato de respuesta

Responder con:

- archivos modificados;
- archivos incluidos;
- archivos excluidos;
- documentacion que aplica revisar;
- resumen del cambio;
- mensaje de commit propuesto;
- cuerpo del commit propuesto;
- comandos de staging explicito;
- confirmacion de que no se hizo staging, commit ni push.

## Reglas

- No usar `git add .`.
- Excluir `Outputs/` salvo autorizacion explicita.
- Excluir `.codex/` y `contracts/` salvo instruccion explicita.
- Incluir `contracts/` unicamente en commits explicitos de gobierno de contratos.
- Hacer commits separados por bloque funcional.
- No mezclar PBIP con `tools/` o `.agents/skills/` salvo que sea parte del mismo cambio autorizado.
- Pedir autorizacion antes de ejecutar cualquier commit.
- No modificar PBIP durante la preparacion del commit.
- No modificar Docs existentes salvo autorizacion del usuario.
- No eliminar archivos.
- No usar internet.

## Criterios de inclusion

Incluir solo archivos que pertenezcan al alcance aprobado por el usuario. Si hay cambios locales no relacionados, mencionarlos como excluidos y dejarlos intactos.

## Criterios de documentacion

Revisar documentacion aplicable segun el JSON:

- cambios en `PBIP/Proyecto.SemanticModel`: revisar `Docs/DATA_MODEL.md`;
- cambios visuales en `PBIP/Proyecto.Report/visuals`: revisar `Docs/BRAND_GUIDELINES.md` o `Docs/PROJECT_CONTEXT.md`;
- cambios en `tools/` o `.agents/skills/`: revisar `Docs/FOLDER_STRUCTURE.md` y `Docs/AI_INSTRUCTIONS.md`;
- cambios en reglas de commit: revisar `Docs/COMMIT_GUIDELINES.md`.

## Ejemplo

Usuario:

```text
Prepara un commit controlado para la nueva tool de diagnostico.
```

Codex debe:

1. Ejecutar `python tools/governance/prepare_commit_review.py . --pretty`.
2. Revisar `Docs/COMMIT_GUIDELINES.md`.
3. Proponer archivos incluidos y excluidos.
4. Proponer mensaje y cuerpo de commit.
5. Esperar autorizacion explicita antes de staging o commit.
