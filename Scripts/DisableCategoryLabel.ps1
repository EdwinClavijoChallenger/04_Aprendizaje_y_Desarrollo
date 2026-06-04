param()
$ErrorActionPreference = "Stop"

$root     = Join-Path $PSScriptRoot ".."
$root     = (Resolve-Path $root).Path
$pagesDir = Join-Path $root "PBIP\Proyecto.Report\definition\pages"
$outDir   = Join-Path $root "Outputs"
$outFile  = Join-Path $outDir "desactivar_etiqueta_categoria_tarjetas.md"

function Write-JsonFile($Path, $Obj) {
    [System.IO.File]::WriteAllText($Path, ($Obj | ConvertTo-Json -Depth 100), (New-Object System.Text.UTF8Encoding($false)))
}
function lit($v) { [ordered]@{ expr = [ordered]@{ Literal = [ordered]@{ Value = "$v" } } } }

$pageMap = [ordered]@{
    "ad1e0000000000000000" = "00 Inicio Corporativo"
    "ad1e0100000000000001" = "01 Resumen Ejecutivo Aprendizaje"
    "ad1e0200000000000002" = "02 Plan y Ejecucion"
    "ad1e0300000000000003" = "03 Cobertura y Participacion"
    "ad1e0400000000000004" = "04 Satisfaccion y Eficacia"
    "ad1e0500000000000005" = "05 Induccion y Entrenamiento"
    "ad1e0600000000000006" = "06 Focos de Gestion"
}

$resultPages    = [System.Collections.Generic.List[object]]::new()
$totalCards     = 0
$totalAjustadas = 0
$totalYaOk      = 0

foreach ($pageDir in (Get-ChildItem $pagesDir -Directory | Sort-Object Name)) {
    $pageName   = if ($pageMap[$pageDir.Name]) { $pageMap[$pageDir.Name] } else { $pageDir.Name }
    $visualsDir = Join-Path $pageDir.FullName "visuals"
    if (-not (Test-Path $visualsDir)) { continue }

    $pCards = 0; $pAjust = 0; $pOk = 0

    foreach ($file in (Get-ChildItem $visualsDir -Filter "visual.json" -Recurse)) {
        $json = Get-Content $file.FullName -Raw | ConvertFrom-Json
        if ($json.visual.visualType -ne "card") { continue }

        $pCards++; $totalCards++

        $show = $null
        $op = $json.visual.PSObject.Properties["objects"]
        if ($null -ne $op) {
            $cl = $op.Value.PSObject.Properties["categoryLabel"]
            if ($null -ne $cl) { $show = $cl.Value[0].properties.show.expr.Literal.Value }
        }

        if ($show -eq "false") {
            $pOk++; $totalYaOk++
        } else {
            $e  = New-Object PSObject
            $p2 = New-Object PSObject
            $p2 | Add-Member -NotePropertyName "show" -NotePropertyValue (lit "false") -Force
            $e  | Add-Member -NotePropertyName "properties" -NotePropertyValue $p2 -Force

            if ($null -eq $json.visual.PSObject.Properties["objects"]) {
                $json.visual | Add-Member -NotePropertyName "objects" -NotePropertyValue (New-Object PSObject) -Force
            }
            $json.visual.objects | Add-Member -NotePropertyName "categoryLabel" -NotePropertyValue ([object[]]@($e)) -Force
            Write-JsonFile $file.FullName $json
            $pAjust++; $totalAjustadas++
        }
    }

    if ($pCards -gt 0) {
        $resultPages.Add([ordered]@{ Page=$pageName; Cards=$pCards; Ajustadas=$pAjust; YaOk=$pOk })
    }
}

$verOk = 0; $verFail = 0
foreach ($f in (Get-ChildItem $pagesDir -Filter "visual.json" -Recurse)) {
    $j = Get-Content $f.FullName -Raw | ConvertFrom-Json
    if ($j.visual.visualType -ne "card") { continue }
    if ($j.visual.objects.categoryLabel[0].properties.show.expr.Literal.Value -eq "false") { $verOk++ } else { $verFail++ }
}

Write-Host ""
Write-Host "===== Etiqueta de Categoria deshabilitada ====="
foreach ($rp in $resultPages) {
    Write-Host ("  {0,-35}  cards:{1,2}  nuevas:{2,2}  ya ok:{3,2}" -f $rp.Page, $rp.Cards, $rp.Ajustadas, $rp.YaOk)
}
Write-Host ""
Write-Host ("  Total : {0}  |  Ajustadas: {1}  |  Ya ok: {2}" -f $totalCards, $totalAjustadas, $totalYaOk)
Write-Host "  Verificacion disco: $verOk OK / $verFail pendientes"
Write-Host "==============================================="

if (-not ([System.IO.Directory]::Exists($outDir))) {
    [System.IO.Directory]::CreateDirectory($outDir) | Out-Null
}

$now    = Get-Date -Format "yyyy-MM-dd HH:mm"
$estado = if ($verFail -eq 0) { "COMPLETADO" } else { "REVISION REQUERIDA" }

$md = "# Desactivar Etiqueta de Categoria en Tarjetas`n"
$md += "**Proyecto:** Aprendizaje y Desarrollo`n"
$md += "**Fecha:** $now`n"
$md += "**Estado:** $estado`n`n---`n`n"
$md += "## Resumen`n"
$md += "| Indicador | Valor |`n|---|---|`n"
$md += "| Total tarjetas procesadas | $totalCards |`n"
$md += "| Ajustadas en esta ejecucion | $totalAjustadas |`n"
$md += "| Ya correctas (sin cambio) | $totalYaOk |`n"
$md += "| Verificacion en disco | $verOk / $($verOk + $verFail) |`n`n"
$md += "---`n`n## Detalle por pagina`n"
$md += "| Pagina | Tarjetas | Ajustadas | Ya correctas |`n|---|---|---|---|`n"
foreach ($rp in $resultPages) {
    $md += "| $($rp.Page) | $($rp.Cards) | $($rp.Ajustadas) | $($rp.YaOk) |`n"
}
$md += "`n---`n`n## Confirmacion`n"
$md += "La opcion **Etiqueta de Categoria** quedo **deshabilitada** en las **$totalCards tarjetas** "
$md += "distribuidas en **$($resultPages.Count) paginas** del proyecto.`n`n"
$md += "Propiedad aplicada en cada tarjeta:`n"
$md += '```json' + "`n"
$md += '"categoryLabel": [{"properties": {"show": {"expr": {"Literal": {"Value": "false"}}}}}]' + "`n"
$md += '```' + "`n`n"
$md += "## Paginas impactadas`n"
foreach ($rp in $resultPages) {
    $md += "- **$($rp.Page)** ($($rp.Cards) tarjetas)`n"
}
$md += "`n---`n_Generado automaticamente - Proyecto Aprendizaje y Desarrollo_"

[System.IO.File]::WriteAllText($outFile, $md, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ""
Write-Host "Resumen guardado: $outFile"
