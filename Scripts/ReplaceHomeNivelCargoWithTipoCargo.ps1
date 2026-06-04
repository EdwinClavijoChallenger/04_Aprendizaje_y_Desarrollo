param(
    [string]$VisualPath = (Join-Path $PSScriptRoot '..\PBIP\Proyecto.Report\definition\pages\ad1e0000000000000000\visuals\c9f72e5627b7182e11f6\visual.json')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function New-Literal {
    param([Parameter(Mandatory = $true)][string]$Value)

    [ordered]@{
        expr = [ordered]@{
            Literal = [ordered]@{
                Value = $Value
            }
        }
    }
}

if (-not (Test-Path -LiteralPath $VisualPath)) {
    throw "No se encontro el visual: $VisualPath"
}

$visual = Get-Content -LiteralPath $VisualPath -Raw | ConvertFrom-Json
$containerObjects = $visual.visual.visualContainerObjects

if ($containerObjects.title.Count -gt 0) {
    $containerObjects.title[0].properties.text = New-Literal "'Tipo de Cargo'"
    $containerObjects.title[0].properties.fontSize = New-Literal '12D'
}

$newVisual = [ordered]@{
    '$schema' = $visual.'$schema'
    name = $visual.name
    position = $visual.position
    visual = [ordered]@{
        visualType = 'barChart'
        query = [ordered]@{
            queryState = [ordered]@{
                Category = [ordered]@{
                    projections = @(
                        [ordered]@{
                            field = [ordered]@{
                                Column = [ordered]@{
                                    Expression = [ordered]@{
                                        SourceRef = [ordered]@{
                                            Entity = 'Dim_ColaboradorHC'
                                        }
                                    }
                                    Property = 'Tipo_Cargo'
                                }
                            }
                            queryRef = 'Dim_ColaboradorHC.Tipo_Cargo'
                            nativeQueryRef = 'Tipo_Cargo'
                            active = $true
                        }
                    )
                }
                Y = [ordered]@{
                    projections = @(
                        [ordered]@{
                            field = [ordered]@{
                                Measure = [ordered]@{
                                    Expression = [ordered]@{
                                        SourceRef = [ordered]@{
                                            Entity = 'Medidas_AD'
                                        }
                                    }
                                    Property = 'HC Porcentaje Tipo Cargo'
                                }
                            }
                            queryRef = 'Medidas_AD.HC Porcentaje Tipo Cargo'
                            nativeQueryRef = 'HC Porcentaje Tipo Cargo'
                        }
                    )
                }
            }
            sortDefinition = [ordered]@{
                sort = @(
                    [ordered]@{
                        field = [ordered]@{
                            Measure = [ordered]@{
                                Expression = [ordered]@{
                                    SourceRef = [ordered]@{
                                        Entity = 'Medidas_AD'
                                    }
                                }
                                Property = 'HC Porcentaje Tipo Cargo'
                            }
                        }
                        direction = 'Descending'
                    }
                )
                isDefaultSort = $true
            }
        }
        objects = [ordered]@{
            labels = @(
                [ordered]@{
                    properties = [ordered]@{
                        show = New-Literal 'true'
                        fontSize = New-Literal '8D'
                        labelDisplayUnits = New-Literal '1D'
                    }
                }
            )
            categoryAxis = @(
                [ordered]@{
                    properties = [ordered]@{
                        showAxisTitle = New-Literal 'false'
                        fontSize = New-Literal '7D'
                    }
                }
            )
            valueAxis = @(
                [ordered]@{
                    properties = [ordered]@{
                        showAxisTitle = New-Literal 'false'
                        fontSize = New-Literal '7D'
                    }
                }
            )
            legend = @(
                [ordered]@{
                    properties = [ordered]@{
                        showTitle = New-Literal 'false'
                    }
                }
            )
            dataPoint = @(
                [ordered]@{
                    properties = [ordered]@{
                        defaultColor = [ordered]@{
                            solid = [ordered]@{
                                color = [ordered]@{
                                    expr = [ordered]@{
                                        Literal = [ordered]@{
                                            Value = "'#1B487F'"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            )
        }
        visualContainerObjects = $containerObjects
        drillFilterOtherVisuals = $true
    }
}

$json = $newVisual | ConvertTo-Json -Depth 100
[System.IO.File]::WriteAllText($VisualPath, $json, $Utf8NoBom)

[pscustomobject]@{
    VisualPath = $VisualPath
    VisualType = 'barChart'
    Category = 'Dim_ColaboradorHC[Tipo_Cargo]'
    Value = '[HC Porcentaje Tipo Cargo]'
}
