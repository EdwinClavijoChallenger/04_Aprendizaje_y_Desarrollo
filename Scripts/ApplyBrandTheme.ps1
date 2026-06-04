param()
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$reportDir = Join-Path $PSScriptRoot "..\PBIP\Proyecto.Report\definition"
$reportDir = (Resolve-Path $reportDir).Path

# Paleta LEMCO
$C_BLUE_MID  = "#1B487F"
$C_BLUE_DARK = "#1A3059"
$C_BLUE_DEEP = "#0B1C35"
$C_ORANGE    = "#F7931E"
$C_WHITE     = "#FFFFFF"
$C_LIGHT_BG  = "#F4F5F7"
$C_TXT_LIGHT = "#E8EDF2"
$C_GRID      = "#E0E4EB"

function sol($c) { [ordered]@{ solid = [ordered]@{ color = $c } } }
function lit($v) { [ordered]@{ expr  = [ordered]@{ Literal = [ordered]@{ Value = "$v" } } } }

function Write-JsonFile {
    param([string]$Path, $Object)
    $json = $Object | ConvertTo-Json -Depth 100
    [System.IO.File]::WriteAllText($Path, $json, (New-Object System.Text.UTF8Encoding($false)))
}

# Agrega o sobreescribe propiedad escalar en PSCustomObject
function SProp {
    param($obj, [string]$key, $value)
    $obj | Add-Member -NotePropertyName $key -NotePropertyValue $value -Force
}

# Agrega o sobreescribe propiedad ARRAY en PSCustomObject.
# El constraint [object[]] re-envuelve aunque el caller haya desbloqueado el array.
function AProp {
    param($obj, [string]$key, [object[]]$value)
    $obj | Add-Member -NotePropertyName $key -NotePropertyValue $value -Force
}

# Wrapper de propiedades: devuelve array de 1 elemento con {properties: $h}
function Wrap($h) {
    $entry = New-Object PSObject
    $entry | Add-Member -NotePropertyName "properties" -NotePropertyValue $h -Force
    return $entry   # AProp se encarga de envolver en array via [object[]]
}

# Crea objeto PSCustomObject para nuevas secciones
function NewObj { return New-Object PSObject }

# -------------------------------------------------------
# Selectores de color por serie (graficos comparativos)
# -------------------------------------------------------
function New-SeriesColor($entity, $measure, $hex) {
    $sel = New-Object PSObject
    $data = New-Object PSObject
    $data | Add-Member -NotePropertyName "expr" -NotePropertyValue (
        [ordered]@{
            Measure = [ordered]@{
                Expression = [ordered]@{ SourceRef = [ordered]@{ Entity = $entity } }
                Property   = $measure
            }
        }
    ) -Force
    $sel | Add-Member -NotePropertyName "data" -NotePropertyValue @($data) -Force
    $props = New-Object PSObject
    $props | Add-Member -NotePropertyName "fill" -NotePropertyValue (sol $hex) -Force
    $entry = New-Object PSObject
    $entry | Add-Member -NotePropertyName "selector"   -NotePropertyValue $sel   -Force
    $entry | Add-Member -NotePropertyName "properties" -NotePropertyValue $props -Force
    return $entry
}

$compareCharts = @{
    "c93d52c966276028463e" = @(
        (New-SeriesColor "Medidas_AD" "Plan Actividades Planificadas" $C_BLUE_DARK),
        (New-SeriesColor "Medidas_AD" "Plan Actividades Ejecutadas"   $C_ORANGE)
    )
    "6df4697436796309f0b0" = @(
        (New-SeriesColor "Medidas_AD" "Plan Actividades Ejecutadas"   $C_BLUE_DARK),
        (New-SeriesColor "Medidas_AD" "Asistencia Total Asistentes"   $C_ORANGE),
        (New-SeriesColor "Medidas_AD" "Encuesta Total Respuestas"     $C_BLUE_MID),
        (New-SeriesColor "Medidas_AD" "Induccion Total Colaboradores" "#4A7AB5")
    )
    "3330e1605c97b1ef841b" = @(
        (New-SeriesColor "Medidas_AD" "Plan Actividades Ejecutadas"   $C_BLUE_DARK),
        (New-SeriesColor "Medidas_AD" "Asistencia Total Asistentes"   $C_ORANGE),
        (New-SeriesColor "Medidas_AD" "Encuesta Total Respuestas"     $C_BLUE_MID),
        (New-SeriesColor "Medidas_AD" "Induccion Total Colaboradores" "#4A7AB5")
    )
}

# -------------------------------------------------------
# Funciones de estilo
# -------------------------------------------------------

function Add-TitleStyle($vco, $fontColor, $fontSize) {
    if ($null -eq $vco.title -or $vco.title.Count -eq 0) { return }
    $tp = $vco.title[0].properties
    SProp $tp "fontColor"  (sol $fontColor)
    SProp $tp "fontFamily" "Outfit"
    SProp $tp "fontSize"   $fontSize
    SProp $tp "bold"       $true
}

function Style-Card($json) {
    $vco = $json.visual.visualContainerObjects
    Add-TitleStyle $vco $C_ORANGE 10

    $bgProps = NewObj
    SProp $bgProps "show"         (lit "true")
    SProp $bgProps "color"    (sol $C_BLUE_MID)
    SProp $bgProps "transparency" 0
    AProp $vco "background" (Wrap $bgProps)

    $bdProps = NewObj
    SProp $bdProps "show"   (lit "true")
    SProp $bdProps "color"  (sol $C_ORANGE)
    SProp $bdProps "radius" 8
    AProp $vco "border" (Wrap $bdProps)

    if ($null -eq $json.visual.PSObject.Properties["objects"]) {
        SProp $json.visual "objects" (NewObj)
    }
    $obj = $json.visual.objects

    $lblProps = NewObj
    SProp $lblProps "color"      (sol $C_WHITE)
    SProp $lblProps "fontFamily" "Outfit"
    SProp $lblProps "fontSize"   22
    SProp $lblProps "bold"       $true
    AProp $obj "labels" (Wrap $lblProps)

    $catProps = NewObj
    SProp $catProps "show"       $true
    SProp $catProps "color"      (sol $C_TXT_LIGHT)
    SProp $catProps "fontFamily" "Outfit"
    SProp $catProps "fontSize"   10
    AProp $obj "categoryLabel" (Wrap $catProps)
}

function Style-Slicer($json) {
    $vco = $json.visual.visualContainerObjects
    Add-TitleStyle $vco $C_BLUE_DARK 10

    $bgProps = NewObj
    SProp $bgProps "show"         (lit "true")
    SProp $bgProps "color"    (sol $C_WHITE)
    SProp $bgProps "transparency" 0
    AProp $vco "background" (Wrap $bgProps)

    $bdProps = NewObj
    SProp $bdProps "show"   (lit "true")
    SProp $bdProps "color"  (sol $C_BLUE_MID)
    SProp $bdProps "radius" 4
    AProp $vco "border" (Wrap $bdProps)

    $obj = $json.visual.objects

    $genProps = NewObj
    SProp $genProps "outlineColor"  (sol $C_BLUE_MID)
    SProp $genProps "outlineWeight" 1
    AProp $obj "general" (Wrap $genProps)

    $hdrProps = NewObj
    SProp $hdrProps "show"       $true
    SProp $hdrProps "fontColor"  (sol $C_BLUE_DARK)
    SProp $hdrProps "background" (sol $C_LIGHT_BG)
    SProp $hdrProps "fontFamily" "Outfit"
    SProp $hdrProps "textSize"   10
    SProp $hdrProps "bold"       $true
    AProp $obj "header" (Wrap $hdrProps)

    $itmProps = NewObj
    SProp $itmProps "fontColor"  (sol $C_BLUE_DEEP)
    SProp $itmProps "fontFamily" "Outfit"
    SProp $itmProps "textSize"   10
    AProp $obj "items" (Wrap $itmProps)
}

function Style-Chart($json, $seriesColors) {
    $vco = $json.visual.visualContainerObjects
    Add-TitleStyle $vco $C_BLUE_DARK 11

    $bgProps = NewObj
    SProp $bgProps "show"         (lit "true")
    SProp $bgProps "color"    (sol $C_WHITE)
    SProp $bgProps "transparency" 0
    AProp $vco "background" (Wrap $bgProps)

    $obj = $json.visual.objects

    if ($seriesColors -and $seriesColors.Count -gt 0) {
        AProp $obj "dataPoint" $seriesColors
    } else {
        $dpProps = NewObj
        SProp $dpProps "defaultColor" (sol $C_BLUE_MID)
        AProp $obj "dataPoint" (Wrap $dpProps)
    }

    $caProps = NewObj
    SProp $caProps "showAxisTitle" (lit "false")
    SProp $caProps "labelColor"    (sol $C_BLUE_DEEP)
    SProp $caProps "fontFamily"    "Outfit"
    AProp $obj "categoryAxis" (Wrap $caProps)

    $vaProps = NewObj
    SProp $vaProps "showAxisTitle" (lit "false")
    SProp $vaProps "labelColor"    (sol $C_BLUE_DEEP)
    SProp $vaProps "fontFamily"    "Outfit"
    AProp $obj "valueAxis" (Wrap $vaProps)
}

function Style-Table($json) {
    $vco = $json.visual.visualContainerObjects
    Add-TitleStyle $vco $C_BLUE_DARK 11

    $bgProps = NewObj
    SProp $bgProps "show"         (lit "true")
    SProp $bgProps "color"    (sol $C_WHITE)
    SProp $bgProps "transparency" 0
    AProp $vco "background" (Wrap $bgProps)

    $bdProps = NewObj
    SProp $bdProps "show"   (lit "true")
    SProp $bdProps "color"  (sol $C_BLUE_MID)
    SProp $bdProps "radius" 4
    AProp $vco "border" (Wrap $bdProps)

    if ($null -eq $json.visual.PSObject.Properties["objects"]) {
        SProp $json.visual "objects" (NewObj)
    }
    $obj = $json.visual.objects

    $chProps = NewObj
    SProp $chProps "fontColor"  (sol $C_WHITE)
    SProp $chProps "backColor"  (sol $C_BLUE_DARK)
    SProp $chProps "fontFamily" "Outfit"
    SProp $chProps "bold"       $true
    AProp $obj "columnHeaders" (Wrap $chProps)

    $vProps = NewObj
    SProp $vProps "fontColor"  (sol $C_BLUE_DEEP)
    SProp $vProps "fontFamily" "Outfit"
    AProp $obj "values" (Wrap $vProps)

    $grProps = NewObj
    SProp $grProps "gridColor"     (sol $C_GRID)
    SProp $grProps "outlineColor"  (sol $C_BLUE_MID)
    SProp $grProps "outlineWeight" 1
    AProp $obj "grid" (Wrap $grProps)

    $totProps = NewObj
    SProp $totProps "fontColor"  (sol $C_BLUE_MID)
    SProp $totProps "fontFamily" "Outfit"
    SProp $totProps "bold"       $true
    AProp $obj "total" (Wrap $totProps)
}

# -------------------------------------------------------
# Procesar visual.json
# -------------------------------------------------------
$visualFiles = Get-ChildItem -Path "$reportDir\pages" -Filter "visual.json" -Recurse
$counts = [ordered]@{ card = 0; slicer = 0; chart = 0; table = 0; textbox = 0; other = 0 }

foreach ($file in $visualFiles) {
    $json = Get-Content $file.FullName -Raw | ConvertFrom-Json
    $vt   = $json.visual.visualType
    $vid  = $json.name

    switch ($vt) {
        "card" {
            Style-Card $json
            $counts["card"]++
        }
        "slicer" {
            Style-Slicer $json
            $counts["slicer"]++
        }
        { $_ -in @("barChart","lineChart") } {
            $series = $null
            if ($compareCharts.ContainsKey($vid)) { $series = $compareCharts[$vid] }
            Style-Chart $json $series
            $counts["chart"]++
        }
        "tableEx" {
            Style-Table $json
            $counts["table"]++
        }
        "textbox" { $counts["textbox"]++ }
        default   { $counts["other"]++ }
    }

    Write-JsonFile $file.FullName $json
}

# page.json: el schema 2.0.0 NO admite 'background' como propiedad raiz.
# El fondo de pagina se controla desde el tema del reporte, no desde page.json.
$pageFiles = Get-ChildItem -Path "$reportDir\pages" -Filter "page.json" -Recurse

# -------------------------------------------------------
# Resultado
# -------------------------------------------------------
Write-Host ""
Write-Host "====== LEMCO Brand Theme aplicado ======"
$counts.GetEnumerator() | ForEach-Object {
    Write-Host ("  {0,-10} {1}" -f $_.Key, $_.Value)
}
Write-Host ("  {0,-10} {1}" -f "TOTAL visuals", ($visualFiles | Measure-Object).Count)
Write-Host ("  {0,-10} {1}" -f "Paginas",       ($pageFiles   | Measure-Object).Count)
Write-Host "========================================"
Write-Host ""
Write-Host "Para ver los cambios: cierra y vuelve a abrir el .pbip"
Write-Host "  o usa Archivo > Cerrar y volver a abrir en Power BI Desktop"
