param(
    [switch]$DryRun
)
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Root      = Join-Path $PSScriptRoot ".."
$Root      = (Resolve-Path $Root).Path
$PagesDir  = Join-Path $Root "PBIP\Proyecto.Report\definition\pages"
$ThemePath = Join-Path $Root "PBIP\Proyecto.Report\StaticResources\SharedResources\BaseThemes\CY25SU11.json"
$OutFile   = Join-Path $Root "Outputs\ResetSummary.md"

# ----------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------
function Write-JsonFile($Path, $Obj) {
    [System.IO.File]::WriteAllText($Path, ($Obj | ConvertTo-Json -Depth 100), (New-Object System.Text.UTF8Encoding($false)))
}

function lit($v) { [ordered]@{ expr = [ordered]@{ Literal = [ordered]@{ Value = "$v" } } } }

function Remove-IfExists($Obj, $Key) {
    if ($null -ne $Obj -and $null -ne $Obj.PSObject -and $null -ne $Obj.PSObject.Properties[$Key]) {
        $Obj.PSObject.Properties.Remove($Key)
        return $true
    }
    return $false
}

# ----------------------------------------------------------------
# Rebuild visualContainerObjects â€” preserva texto del titulo
# ----------------------------------------------------------------
function Get-CleanVCO($Vco) {
    $titleText = "''"
    if ($null -ne $Vco -and $null -ne $Vco.title -and $Vco.title.Count -gt 0) {
        $tp = $Vco.title[0].properties
        if ($null -ne $tp.PSObject.Properties["text"]) {
            $titleText = $tp.text.expr.Literal.Value
        }
    }
    return [ordered]@{
        title = @([ordered]@{
            properties = [ordered]@{
                show = lit "true"
                text = lit $titleText
            }
        })
        visualHeader  = @([ordered]@{ properties = [ordered]@{ show = lit "true" } })
        visualTooltip = @([ordered]@{ properties = [ordered]@{ show = lit "true" } })
    }
}

# ----------------------------------------------------------------
# Rebuild visual.objects segun tipo â€” preserva configuracion funcional
# ----------------------------------------------------------------
function Get-CleanObjects($VType, $ExistingObj) {
    switch ($VType) {

        "slicer" {
            # Preservar modo de slicer (dropdown/list) y seleccion simple/multiple
            $result = [ordered]@{}
            if ($null -ne $ExistingObj) {
                foreach ($key in @("data","selection")) {
                    if ($null -ne $ExistingObj.PSObject.Properties[$key]) {
                        $result[$key] = $ExistingObj.$key
                    }
                }
            }
            return $result
        }

        { $_ -in @("barChart","lineChart","clusteredBarChart","columnChart",
                   "areaChart","stackedBarChart","stackedColumnChart",
                   "hundredPercentStackedBarChart","hundredPercentStackedColumnChart",
                   "lineClusteredColumnComboChart","lineStackedColumnComboChart",
                   "scatterChart","waterfall","funnel","ribbonChart") } {
            return [ordered]@{
                labels       = @([ordered]@{ properties = [ordered]@{ show = lit "true" } })
                categoryAxis = @([ordered]@{ properties = [ordered]@{ showAxisTitle = lit "false" } })
                valueAxis    = @([ordered]@{ properties = [ordered]@{ showAxisTitle = lit "false" } })
                legend       = @([ordered]@{ properties = [ordered]@{ showTitle = lit "false" } })
            }
        }

        { $_ -in @("pieChart","donutChart","treemap","gauge","kpiVisual",
                   "multiRowCard","map","filledMap","azureMap","shapeMap") } {
            return [ordered]@{
                legend = @([ordered]@{ properties = [ordered]@{ showTitle = lit "false" } })
            }
        }

        { $_ -in @("card","tableEx","pivotTable","cardNew") } {
            return $null   # Sin objects â€” Power BI aplica defaults del tema
        }

        "textbox" {
            # Preservar contenido de texto â€” solo resetear estilo visual
            if ($null -eq $ExistingObj -or $null -eq $ExistingObj.PSObject.Properties["general"]) {
                return $ExistingObj
            }
            $general = $ExistingObj.general
            if ($null -eq $general -or $general.Count -eq 0) { return $ExistingObj }
            $props = $general[0].properties
            if ($null -eq $props -or $null -eq $props.PSObject.Properties["paragraphs"]) { return $ExistingObj }

            foreach ($para in $props.paragraphs) {
                if ($null -ne $para.PSObject.Properties["textRuns"]) {
                    foreach ($run in $para.textRuns) {
                        if ($null -ne $run.PSObject.Properties["textStyle"]) {
                            $run.textStyle = [ordered]@{
                                fontSize   = "12pt"
                                color      = "#252423"
                                fontFamily = "Segoe UI"
                            }
                        }
                    }
                }
                if ($null -ne $para.PSObject.Properties["horizontalTextAlignment"]) {
                    $para.horizontalTextAlignment = "left"
                }
            }
            return $ExistingObj
        }

        "image" { return "SKIP" }   # No modificar imagenes

        default { return $ExistingObj }
    }
}

# ----------------------------------------------------------------
# Mapa de nombres de pagina
# ----------------------------------------------------------------
$PageNames = @{
    "ad1e0000000000000000" = "00 Inicio Corporativo"
    "ad1e0100000000000001" = "01 Resumen Ejecutivo Aprendizaje"
    "ad1e0200000000000002" = "02 Plan y Ejecucion"
    "ad1e0300000000000003" = "03 Cobertura y Participacion"
    "ad1e0400000000000004" = "04 Satisfaccion y Eficacia"
    "ad1e0500000000000005" = "05 Induccion y UC"
    "ad1e0600000000000006" = "06 Focos de Gestion"
}

# ----------------------------------------------------------------
# Tracking
# ----------------------------------------------------------------
$Summary = [ordered]@{
    Pages         = [System.Collections.Generic.List[object]]::new()
    TotalVisuals  = 0
    TotalReset    = 0
    TotalSkipped  = 0
    ManualActions = [System.Collections.Generic.List[string]]::new()
    Warnings      = [System.Collections.Generic.List[string]]::new()
}
$TypeCounts = @{}

# ----------------------------------------------------------------
# FASE 1: Reset visual.json
# ----------------------------------------------------------------
$pageDirs = Get-ChildItem $PagesDir -Directory | Sort-Object Name

foreach ($pageDir in $pageDirs) {
    $pName = if ($PageNames.ContainsKey($pageDir.Name)) { $PageNames[$pageDir.Name] } else { $pageDir.Name }
    $visualsDir = Join-Path $pageDir.FullName "visuals"
    if (-not (Test-Path $visualsDir)) { continue }

    $visualFiles = Get-ChildItem $visualsDir -Filter "visual.json" -Recurse

    $pageEntry = [ordered]@{
        Name      = $pName
        Visuals   = [System.Collections.Generic.List[object]]::new()
        Reset     = 0
        Skipped   = 0
    }

    foreach ($file in $visualFiles) {
        $json = Get-Content $file.FullName -Raw | ConvertFrom-Json
        $vt   = $json.visual.visualType
        $Summary.TotalVisuals++

        if (-not $TypeCounts.ContainsKey($vt)) { $TypeCounts[$vt] = 0 }
        $TypeCounts[$vt]++

        $entry = [ordered]@{ Type = $vt; Changes = [System.Collections.Generic.List[string]]::new() }

        # Imagenes: solo registrar, no tocar
        if ($vt -eq "image") {
            $entry.Changes.Add("OMITIDO â€” imagen decorativa (accion manual si necesario)")
            $pageEntry.Skipped++
            $Summary.TotalSkipped++
            $pageEntry.Visuals.Add($entry)
            continue
        }

        # Reset visualContainerObjects
        $originalVco = $json.visual.visualContainerObjects
        $json.visual | Add-Member -NotePropertyName "visualContainerObjects" -NotePropertyValue (Get-CleanVCO $originalVco) -Force
        $entry.Changes.Add("visualContainerObjects: background, border, sombra y formato de titulo eliminados")

        # Reset visual.objects
        $existingObjProp = $json.visual.PSObject.Properties["objects"]
        $existingObj = if ($null -ne $existingObjProp) { $existingObjProp.Value } else { $null }
        $newObj = Get-CleanObjects $vt $existingObj

        if ($newObj -eq "SKIP") {
            $entry.Changes.Add("objects: OMITIDO por tipo")
        } elseif ($null -eq $newObj) {
            if ($null -ne $existingObjProp) {
                $json.visual.PSObject.Properties.Remove("objects")
                $entry.Changes.Add("objects: seccion eliminada (no requerida para $vt)")
            }
        } else {
            $json.visual | Add-Member -NotePropertyName "objects" -NotePropertyValue $newObj -Force
            $entry.Changes.Add("objects: restablecido a defaults funcionales de $vt")
        }

        if (-not $DryRun) { Write-JsonFile $file.FullName $json }

        $pageEntry.Reset++
        $Summary.TotalReset++
        $pageEntry.Visuals.Add($entry)
    }

    $Summary.Pages.Add($pageEntry)
}

# ----------------------------------------------------------------
# FASE 2: Reset page.json (fondos de pagina)
# ----------------------------------------------------------------
$pageJsonFiles = Get-ChildItem $PagesDir -Filter "page.json" -Recurse
$pagesResetBg = 0
foreach ($file in $pageJsonFiles) {
    $j = Get-Content $file.FullName -Raw | ConvertFrom-Json
    $changed = $false
    foreach ($prop in @("background","wallpaper")) {
        if (Remove-IfExists $j $prop) { $changed = $true }
    }
    if ($changed) {
        if (-not $DryRun) { Write-JsonFile $file.FullName $j }
        $pagesResetBg++
    }
}

# ----------------------------------------------------------------
# FASE 3: Reset tema CY25SU11.json (eliminar overrides LEMCO)
# ----------------------------------------------------------------
$themeReset = $false
if (Test-Path $ThemePath) {
    $theme = Get-Content $ThemePath -Raw | ConvertFrom-Json
    $themeProps = @("dataColors","foreground","foregroundNeutralSecondary","foregroundNeutralTertiary",
                    "background","backgroundLight","backgroundNeutral","tableAccent",
                    "good","neutral","bad","maximum","center","minimum","null")
    foreach ($p in $themeProps) { Remove-IfExists $theme $p | Out-Null }
    if ($null -ne $theme.PSObject.Properties["textClasses"]) {
        foreach ($cls in @("callout","title","header","label")) {
            if ($null -ne $theme.textClasses.PSObject.Properties[$cls]) {
                $theme.textClasses.$cls = [ordered]@{ fontFace = "Segoe UI"; color = "#252423" }
            }
        }
    }
    if (-not $DryRun) { Write-JsonFile $ThemePath $theme }
    $themeReset = $true
}

# ----------------------------------------------------------------
# FASE 4: Acciones manuales documentadas
# ----------------------------------------------------------------
$Summary.ManualActions.Add("TEMA: En PBI Desktop: Vista -> Temas -> Predeterminado (tema nativo)")
$Summary.ManualActions.Add("FILTROS: Verificar panel de filtros â€” el estilo del panel se configura solo desde PBI Desktop UI")
$Summary.ManualActions.Add("IMAGENES: $($Summary.TotalSkipped) imagen(es) detectada(s) â€” verificar manualmente si tienen fondo personalizado")
$Summary.ManualActions.Add("FORMATO CONDICIONAL: Si habia formato condicional de color, debe removerse manualmente por visual")

# ----------------------------------------------------------------
# FASE 5: Reporte de resultados
# ----------------------------------------------------------------
$mode = if ($DryRun) { "SIMULACION (sin escritura)" } else { "PRODUCCION" }
$now  = Get-Date -Format "yyyy-MM-dd HH:mm"

$rpt = @"
# Reset Visual â€” Proyecto Aprendizaje y Desarrollo
**Fecha:** $now
**Modo:** $mode

---

## Resumen ejecutivo
| Indicador | Valor |
|---|---|
| Paginas procesadas | $($Summary.Pages.Count) |
| Fondos de pagina eliminados | $pagesResetBg |
| Visuals procesados | $($Summary.TotalVisuals) |
| Visuals restablecidos | $($Summary.TotalReset) |
| Visuals omitidos (imagenes) | $($Summary.TotalSkipped) |
| Tema base reseteado | $(if ($themeReset) { "Si" } else { "No (archivo no encontrado)" }) |

---

## Distribucion por tipo de visual
"@

foreach ($kvp in ($TypeCounts.GetEnumerator() | Sort-Object Key)) {
    $rpt += "`n| $($kvp.Key) | $($kvp.Value) |"
}

$rpt += "`n`n---`n`n## Detalle por pagina`n"

foreach ($page in $Summary.Pages) {
    $rpt += "`n### $($page.Name)`n"
    $rpt += "- Visuals restablecidos: **$($page.Reset)**"
    if ($page.Skipped -gt 0) { $rpt += " | Omitidos: **$($page.Skipped)**" }
    $rpt += "`n"
    $typesSummary = $page.Visuals | Group-Object Type | Sort-Object Name | ForEach-Object { "$($_.Name) ($($_.Count))" }
    $rpt += "- Tipos: $($typesSummary -join ', ')`n"
}

$rpt += "`n---`n`n## Acciones manuales requeridas`n"
foreach ($action in $Summary.ManualActions) { $rpt += "`n- [ ] $action" }

$rpt += "`n`n---`n`n## Lo que NO fue modificado (intocable)`n"
$rpt += @"

- Modelo de datos (tablas, columnas, tipos)
- Medidas DAX y columnas calculadas
- Relaciones entre tablas
- Consultas Power Query (M)
- Nombres de paginas
- Posicion y tamano de visuals
- Tipo de visualizacion
- Texto de titulos de visuals
- Configuracion de campos en slicers (modo y seleccion simple/multiple preservados)
- Filtros funcionales aplicados a paginas o visuals
"@

Write-Host $rpt

if (-not $DryRun) {
    New-Item -ItemType Directory -Force -Path (Split-Path $OutFile) | Out-Null
    [System.IO.File]::WriteAllText($OutFile, $rpt, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host ""
    Write-Host "Resumen guardado en: $OutFile"
    Write-Host ""
    Write-Host "Siguiente paso: abre Proyecto.pbip en Power BI Desktop"
    Write-Host "  y aplica: Vista -> Temas -> Predeterminado"
}
