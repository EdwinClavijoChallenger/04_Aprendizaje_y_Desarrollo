param(
    [string]$ReportPath = (Join-Path $PSScriptRoot '..\PBIP\Proyecto.Report')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$Colors = [ordered]@{
    BlueBase = '#1B487F'
    Orange = '#F7931E'
    BlueDeep = '#1A3059'
    Ink = '#0B1C35'
    Navy = '#000032'
    BlueSoft = '#4D6F8F'
    Gray = '#7A7F85'
    Red = '#D64550'
    Green = '#2F8F83'
    GraySoft = '#9AA6B2'
    Background = '#FFFFFF'
    Surface = '#F4F7FA'
    Border = '#E6EEF5'
}

function ConvertTo-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][object]$Value,
        [int]$Depth = 80
    )

    $json = $Value | ConvertTo-Json -Depth $Depth
    [System.IO.File]::WriteAllText($Path, $json, $Utf8NoBom)
}

function New-Literal {
    param([Parameter(Mandatory = $true)][string]$Value)
    [pscustomobject]@{
        expr = [pscustomobject]@{
            Literal = [pscustomobject]@{
                Value = $Value
            }
        }
    }
}

function New-SolidColor {
    param([Parameter(Mandatory = $true)][string]$Color)
    [pscustomobject]@{
        solid = [pscustomobject]@{
            color = $Color
        }
    }
}

function Ensure-Property {
    param(
        [Parameter(Mandatory = $true)][object]$Object,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][object]$DefaultValue
    )

    if ($null -eq $Object.PSObject.Properties[$Name]) {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $DefaultValue
    }

    return $Object.$Name
}

function Set-Property {
    param(
        [Parameter(Mandatory = $true)][object]$Object,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][object]$Value
    )

    if ($null -eq $Object.PSObject.Properties[$Name]) {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
    else {
        $Object.$Name = $Value
    }
}

function New-FormattingEntry {
    [pscustomobject]@{
        properties = [pscustomobject]@{}
    }
}

function Ensure-FormattingEntry {
    param(
        [Parameter(Mandatory = $true)][object]$ObjectContainer,
        [Parameter(Mandatory = $true)][string]$ObjectName
    )

    if ($null -eq $ObjectContainer.PSObject.Properties[$ObjectName] -or $null -eq $ObjectContainer.$ObjectName) {
        Set-Property -Object $ObjectContainer -Name $ObjectName -Value @((New-FormattingEntry))
    }

    if ($ObjectContainer.$ObjectName.Count -eq 0) {
        $ObjectContainer.$ObjectName = @((New-FormattingEntry))
    }

    if ($null -eq $ObjectContainer.$ObjectName[0].PSObject.Properties['properties']) {
        $ObjectContainer.$ObjectName[0] | Add-Member -NotePropertyName 'properties' -NotePropertyValue ([pscustomobject]@{})
    }

    return $ObjectContainer.$ObjectName[0]
}

function Set-ContainerTitleStyle {
    param(
        [Parameter(Mandatory = $true)][object]$Visual,
        [string]$Color = $Colors.BlueBase,
        [string]$Background = $null,
        [string]$FontSize = '10D'
    )

    $container = Ensure-Property -Object $Visual.visual -Name 'visualContainerObjects' -DefaultValue ([pscustomobject]@{})
    $entry = Ensure-FormattingEntry -ObjectContainer $container -ObjectName 'title'
    $props = $entry.properties

    Set-Property -Object $props -Name 'show' -Value (New-Literal 'true')
    Set-Property -Object $props -Name 'fontColor' -Value (New-SolidColor $Color)
    Set-Property -Object $props -Name 'fontSize' -Value (New-Literal $FontSize)
    Set-Property -Object $props -Name 'bold' -Value (New-Literal 'true')
    Set-Property -Object $props -Name 'fontFamily' -Value (New-Literal "'Segoe UI Semibold'")

    if ($Background) {
        Set-Property -Object $props -Name 'background' -Value (New-SolidColor $Background)
    }
}

function Set-ContainerFrameStyle {
    param(
        [Parameter(Mandatory = $true)][object]$Visual,
        [bool]$IncludeBorder = $true
    )

    $container = Ensure-Property -Object $Visual.visual -Name 'visualContainerObjects' -DefaultValue ([pscustomobject]@{})

    $backgroundEntry = Ensure-FormattingEntry -ObjectContainer $container -ObjectName 'background'
    Set-Property -Object $backgroundEntry.properties -Name 'show' -Value (New-Literal 'true')
    Set-Property -Object $backgroundEntry.properties -Name 'color' -Value (New-SolidColor $Colors.Background)
    Set-Property -Object $backgroundEntry.properties -Name 'transparency' -Value (New-Literal '0D')

    if ($IncludeBorder) {
        $borderEntry = Ensure-FormattingEntry -ObjectContainer $container -ObjectName 'border'
        Set-Property -Object $borderEntry.properties -Name 'show' -Value (New-Literal 'true')
        Set-Property -Object $borderEntry.properties -Name 'color' -Value (New-SolidColor $Colors.Border)
        Set-Property -Object $borderEntry.properties -Name 'radius' -Value (New-Literal '4D')
        Set-Property -Object $borderEntry.properties -Name 'width' -Value (New-Literal '1D')
    }
}

function Set-ChartStyle {
    param([Parameter(Mandatory = $true)][object]$Visual)

    $objects = Ensure-Property -Object $Visual.visual -Name 'objects' -DefaultValue ([pscustomobject]@{})

    $labels = Ensure-FormattingEntry -ObjectContainer $objects -ObjectName 'labels'
    Set-Property -Object $labels.properties -Name 'show' -Value (New-Literal 'true')
    Set-Property -Object $labels.properties -Name 'color' -Value (New-SolidColor $Colors.Ink)
    Set-Property -Object $labels.properties -Name 'fontSize' -Value (New-Literal '8D')

    $legend = Ensure-FormattingEntry -ObjectContainer $objects -ObjectName 'legend'
    Set-Property -Object $legend.properties -Name 'showTitle' -Value (New-Literal 'false')
    Set-Property -Object $legend.properties -Name 'labelColor' -Value (New-SolidColor $Colors.BlueDeep)
    Set-Property -Object $legend.properties -Name 'fontSize' -Value (New-Literal '8D')

    foreach ($axisName in @('categoryAxis', 'valueAxis')) {
        $axis = Ensure-FormattingEntry -ObjectContainer $objects -ObjectName $axisName
        Set-Property -Object $axis.properties -Name 'showAxisTitle' -Value (New-Literal 'false')
        Set-Property -Object $axis.properties -Name 'labelColor' -Value (New-SolidColor $Colors.BlueDeep)
        Set-Property -Object $axis.properties -Name 'gridlineColor' -Value (New-SolidColor $Colors.Border)
        Set-Property -Object $axis.properties -Name 'fontSize' -Value (New-Literal '8D')
    }

    if ($Visual.visual.visualType -match 'barChart|columnChart') {
        $dataPoint = Ensure-FormattingEntry -ObjectContainer $objects -ObjectName 'dataPoint'
        Set-Property -Object $dataPoint.properties -Name 'defaultColor' -Value (New-SolidColor $Colors.BlueBase)
    }
}

function Set-CardStyle {
    param([Parameter(Mandatory = $true)][object]$Visual)

    $objects = Ensure-Property -Object $Visual.visual -Name 'objects' -DefaultValue ([pscustomobject]@{})

    $categoryLabels = Ensure-FormattingEntry -ObjectContainer $objects -ObjectName 'categoryLabels'
    Set-Property -Object $categoryLabels.properties -Name 'show' -Value (New-Literal 'false')

    $labels = Ensure-FormattingEntry -ObjectContainer $objects -ObjectName 'labels'
    Set-Property -Object $labels.properties -Name 'color' -Value (New-SolidColor $Colors.Ink)
    Set-Property -Object $labels.properties -Name 'fontSize' -Value (New-Literal '16D')
}

function Set-SlicerStyle {
    param([Parameter(Mandatory = $true)][object]$Visual)

    $objects = Ensure-Property -Object $Visual.visual -Name 'objects' -DefaultValue ([pscustomobject]@{})

    foreach ($objectName in @('header', 'slicerHeader')) {
        $entry = Ensure-FormattingEntry -ObjectContainer $objects -ObjectName $objectName
        Set-Property -Object $entry.properties -Name 'show' -Value (New-Literal 'false')
    }

    $items = Ensure-FormattingEntry -ObjectContainer $objects -ObjectName 'items'
    Set-Property -Object $items.properties -Name 'fontColor' -Value (New-SolidColor $Colors.Ink)
    Set-Property -Object $items.properties -Name 'fontSize' -Value (New-Literal '8D')
}

function Set-TableStyle {
    param([Parameter(Mandatory = $true)][object]$Visual)

    $objects = Ensure-Property -Object $Visual.visual -Name 'objects' -DefaultValue ([pscustomobject]@{})
    $headers = Ensure-FormattingEntry -ObjectContainer $objects -ObjectName 'columnHeaders'
    Set-Property -Object $headers.properties -Name 'fontColor' -Value (New-SolidColor $Colors.Background)
    Set-Property -Object $headers.properties -Name 'backColor' -Value (New-SolidColor $Colors.BlueBase)
    Set-Property -Object $headers.properties -Name 'fontSize' -Value (New-Literal '8D')
    Set-Property -Object $headers.properties -Name 'bold' -Value (New-Literal 'true')

    $values = Ensure-FormattingEntry -ObjectContainer $objects -ObjectName 'values'
    Set-Property -Object $values.properties -Name 'fontColor' -Value (New-SolidColor $Colors.Ink)
    Set-Property -Object $values.properties -Name 'fontSize' -Value (New-Literal '8D')
}

function Update-Theme {
    param([Parameter(Mandatory = $true)][string]$ThemePath)

    $theme = Get-Content -LiteralPath $ThemePath -Raw | ConvertFrom-Json
    $theme.dataColors = @(
        $Colors.BlueBase,
        $Colors.Orange,
        $Colors.BlueDeep,
        $Colors.Ink,
        $Colors.Navy,
        $Colors.BlueSoft,
        $Colors.Gray,
        $Colors.Red,
        $Colors.Green,
        $Colors.GraySoft
    )

    Set-Property -Object $theme -Name 'background' -Value $Colors.Background
    Set-Property -Object $theme -Name 'foreground' -Value $Colors.Ink
    Set-Property -Object $theme -Name 'foregroundNeutralSecondary' -Value $Colors.BlueDeep
    Set-Property -Object $theme -Name 'foregroundNeutralTertiary' -Value $Colors.BlueSoft
    Set-Property -Object $theme -Name 'backgroundLight' -Value $Colors.Surface
    Set-Property -Object $theme -Name 'backgroundNeutral' -Value $Colors.Border
    Set-Property -Object $theme -Name 'tableAccent' -Value $Colors.Orange

    $visualStyles = Ensure-Property -Object $theme -Name 'visualStyles' -DefaultValue ([pscustomobject]@{})
    $allVisuals = Ensure-Property -Object $visualStyles -Name '*' -DefaultValue ([pscustomobject]@{})
    $allInstances = Ensure-Property -Object $allVisuals -Name '*' -DefaultValue ([pscustomobject]@{})

    foreach ($objectName in @('title', 'legend', 'categoryAxis', 'valueAxis', 'labels', 'background', 'border')) {
        if ($null -eq $allInstances.PSObject.Properties[$objectName] -or $allInstances.$objectName.Count -eq 0) {
            Set-Property -Object $allInstances -Name $objectName -Value @([pscustomobject]@{})
        }
    }

    Set-Property -Object $allInstances.title[0] -Name 'fontColor' -Value (New-SolidColor $Colors.BlueBase)
    Set-Property -Object $allInstances.title[0] -Name 'fontFamily' -Value "'Segoe UI Semibold'"
    Set-Property -Object $allInstances.title[0] -Name 'fontSize' -Value 10
    Set-Property -Object $allInstances.title[0] -Name 'bold' -Value $true

    Set-Property -Object $allInstances.legend[0] -Name 'labelColor' -Value (New-SolidColor $Colors.BlueDeep)
    Set-Property -Object $allInstances.legend[0] -Name 'fontSize' -Value 8

    foreach ($axisName in @('categoryAxis', 'valueAxis')) {
        Set-Property -Object $allInstances.$axisName[0] -Name 'labelColor' -Value (New-SolidColor $Colors.BlueDeep)
        Set-Property -Object $allInstances.$axisName[0] -Name 'gridlineColor' -Value (New-SolidColor $Colors.Border)
        Set-Property -Object $allInstances.$axisName[0] -Name 'fontSize' -Value 8
    }

    Set-Property -Object $allInstances.labels[0] -Name 'color' -Value (New-SolidColor $Colors.Ink)
    Set-Property -Object $allInstances.labels[0] -Name 'fontSize' -Value 8
    Set-Property -Object $allInstances.background[0] -Name 'show' -Value $true
    Set-Property -Object $allInstances.background[0] -Name 'color' -Value (New-SolidColor $Colors.Background)
    Set-Property -Object $allInstances.background[0] -Name 'transparency' -Value 0
    Set-Property -Object $allInstances.border[0] -Name 'show' -Value $true
    Set-Property -Object $allInstances.border[0] -Name 'color' -Value (New-SolidColor $Colors.Border)
    Set-Property -Object $allInstances.border[0] -Name 'radius' -Value 4
    Set-Property -Object $allInstances.border[0] -Name 'width' -Value 1

    ConvertTo-JsonFile -Path $ThemePath -Value $theme -Depth 100
}

$themePath = Join-Path $ReportPath 'StaticResources\SharedResources\BaseThemes\CY25SU11.json'
if (-not (Test-Path -LiteralPath $themePath)) {
    throw "No se encontro el tema: $themePath"
}

Update-Theme -ThemePath $themePath

$pagesRoot = Join-Path $ReportPath 'definition\pages'
$pageDirs = Get-ChildItem -LiteralPath $pagesRoot -Directory |
    Where-Object { $_.Name -ne 'ad1e0000000000000000' } |
    Sort-Object Name

$updatedVisuals = 0
foreach ($pageDir in $pageDirs) {
    $visualDirs = Get-ChildItem -LiteralPath (Join-Path $pageDir.FullName 'visuals') -Directory -ErrorAction SilentlyContinue

    foreach ($visualDir in $visualDirs) {
        $visualPath = Join-Path $visualDir.FullName 'visual.json'
        if (-not (Test-Path -LiteralPath $visualPath)) {
            continue
        }

        $visual = Get-Content -LiteralPath $visualPath -Raw | ConvertFrom-Json
        $visualType = $visual.visual.visualType

        switch -Regex ($visualType) {
            '^slicer$' {
                Set-ContainerTitleStyle -Visual $visual -Color $Colors.BlueBase -FontSize '9D'
                Set-ContainerFrameStyle -Visual $visual -IncludeBorder $true
                Set-SlicerStyle -Visual $visual
                break
            }
            '^card$' {
                Set-ContainerTitleStyle -Visual $visual -Color $Colors.BlueBase -Background $Colors.Surface -FontSize '10D'
                Set-ContainerFrameStyle -Visual $visual -IncludeBorder $true
                Set-CardStyle -Visual $visual
                break
            }
            'barChart|columnChart|lineChart|comboChart|areaChart' {
                Set-ContainerTitleStyle -Visual $visual -Color $Colors.BlueBase -FontSize '10D'
                Set-ContainerFrameStyle -Visual $visual -IncludeBorder $true
                Set-ChartStyle -Visual $visual
                break
            }
            'tableEx|pivotTable' {
                Set-ContainerTitleStyle -Visual $visual -Color $Colors.Background -Background $Colors.BlueBase -FontSize '10D'
                Set-ContainerFrameStyle -Visual $visual -IncludeBorder $true
                Set-TableStyle -Visual $visual
                break
            }
            default {
                Set-ContainerTitleStyle -Visual $visual -Color $Colors.BlueBase -FontSize '10D'
                Set-ContainerFrameStyle -Visual $visual -IncludeBorder $true
                break
            }
        }

        ConvertTo-JsonFile -Path $visualPath -Value $visual -Depth 100
        $updatedVisuals++
    }
}

[pscustomobject]@{
    ThemeUpdated = $themePath
    PagesStyled = $pageDirs.Count
    VisualsUpdated = $updatedVisuals
}
