param(
    [string]$ReportPath = (Join-Path $PSScriptRoot '..\PBIP\Proyecto.Report'),
    [string]$TitleFontSize = '12D',
    [string]$ValueFontSize = '16D'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][object]$Value
    )

    $json = $Value | ConvertTo-Json -Depth 100
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

$pagesRoot = Join-Path $ReportPath 'definition\pages'
if (-not (Test-Path -LiteralPath $pagesRoot)) {
    throw "No se encontro la carpeta de paginas: $pagesRoot"
}

$updated = @()

Get-ChildItem -LiteralPath $pagesRoot -Directory | Sort-Object Name | ForEach-Object {
    $pageDir = $_
    $pageJsonPath = Join-Path $pageDir.FullName 'page.json'
    $displayName = $pageDir.Name
    if (Test-Path -LiteralPath $pageJsonPath) {
        try {
            $pageJson = Get-Content -LiteralPath $pageJsonPath -Raw | ConvertFrom-Json
            if ($pageJson.displayName) {
                $displayName = $pageJson.displayName
            }
        }
        catch {
            $displayName = $pageDir.Name
        }
    }

    $visualsRoot = Join-Path $pageDir.FullName 'visuals'
    if (-not (Test-Path -LiteralPath $visualsRoot)) {
        return
    }

    Get-ChildItem -LiteralPath $visualsRoot -Directory | Sort-Object Name | ForEach-Object {
        $visualPath = Join-Path $_.FullName 'visual.json'
        if (-not (Test-Path -LiteralPath $visualPath)) {
            return
        }

        $visualJson = Get-Content -LiteralPath $visualPath -Raw | ConvertFrom-Json
        if ($visualJson.visual.visualType -ne 'card') {
            return
        }

        $containerObjects = Ensure-Property -Object $visualJson.visual -Name 'visualContainerObjects' -DefaultValue ([pscustomobject]@{})
        $titleEntry = Ensure-FormattingEntry -ObjectContainer $containerObjects -ObjectName 'title'
        Set-Property -Object $titleEntry.properties -Name 'fontSize' -Value (New-Literal $TitleFontSize)

        $visualObjects = Ensure-Property -Object $visualJson.visual -Name 'objects' -DefaultValue ([pscustomobject]@{})

        $valueEntry = Ensure-FormattingEntry -ObjectContainer $visualObjects -ObjectName 'labels'
        Set-Property -Object $valueEntry.properties -Name 'fontSize' -Value (New-Literal $ValueFontSize)

        Write-JsonFile -Path $visualPath -Value $visualJson

        $updated += [pscustomobject]@{
            Page = $displayName
            VisualId = $_.Name
            TitleFontSize = $TitleFontSize
            ValueFontSize = $ValueFontSize
        }
    }
}

$summary = $updated | Group-Object Page | Sort-Object Name | ForEach-Object {
    [pscustomobject]@{
        Page = $_.Name
        CardsUpdated = $_.Count
    }
}

[pscustomobject]@{
    CardsUpdated = $updated.Count
    Pages = $summary
}
