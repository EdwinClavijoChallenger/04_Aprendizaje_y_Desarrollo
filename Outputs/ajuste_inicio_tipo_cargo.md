# Ajuste pagina 00 Inicio Corporativo - Tipo_Cargo

Fecha: 2026-06-04

## Objetivo

Reemplazar la tarjeta titulada `Nivel cargo` en el frente de `Aprendizaje` de la pagina `00 Inicio Corporativo` por una visualizacion basada en el campo `Dim_ColaboradorHC[Tipo_Cargo]`.

## Cambio aplicado

Se reemplazo el visual:

- Visual anterior: tarjeta `Nivel cargo`
- Visual nuevo: grafico de barras horizontal `Tipo de Cargo`
- Categoria: `Dim_ColaboradorHC[Tipo_Cargo]`
- Valor: recuento implicito generado desde `Dim_ColaboradorHC[Tipo_Cargo]`

El recuento del propio campo `Tipo_Cargo` permite mostrar la distribucion de colaboradores por tipo de cargo sin depender de la medida `Asistencia Participantes Unicos`, ya que esa medida no reflejaba correctamente la distribucion esperada en este visual.

## Ubicacion

- Pagina: `00 Inicio Corporativo`
- Frente: `Aprendizaje`
- VisualId: `c9f72e5627b7182e11f6`

## Validaciones

- Archivos JSON revisados: 151
- Errores JSON: 0
- Archivos JSON con BOM: 0
- Visual actualizado:
  - Tipo: `barChart`
  - Titulo: `Tipo de Cargo`
  - Campo categoria: `Dim_ColaboradorHC[Tipo_Cargo]`
  - Valor: recuento implicito de `Dim_ColaboradorHC[Tipo_Cargo]`

## Respaldo previo

- `backups_codex/backup_20260604_081653_before_home_tipo_cargo_visual`
