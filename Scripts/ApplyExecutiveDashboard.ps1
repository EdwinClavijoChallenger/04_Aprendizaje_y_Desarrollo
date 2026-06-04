param(
    [int]$Port = 0,
    [switch]$ModelOnly,
    [switch]$ReportOnly
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$ReportRoot = Join-Path $WorkspaceRoot "PBIP\Proyecto.Report"
$PagesRoot = Join-Path $ReportRoot "definition\pages"
$ThemePath = Join-Path $ReportRoot "StaticResources\SharedResources\BaseThemes\CY25SU11.json"
$PowerBIBin = "C:\Program Files\Microsoft Power BI Desktop\bin"

function Get-PowerBIPort {
    if ($Port -gt 0) {
        return $Port
    }

    $proc = Get-Process -Name msmdsrv -ErrorAction Stop | Select-Object -First 1
    $conn = Get-NetTCPConnection -State Listen |
        Where-Object { $_.OwningProcess -eq $proc.Id -and $_.LocalAddress -eq "127.0.0.1" } |
        Sort-Object LocalPort |
        Select-Object -First 1

    if (-not $conn) {
        throw "No se encontro el puerto local de msmdsrv para Power BI Desktop."
    }

    return [int]$conn.LocalPort
}

function Add-TomAssemblies {
    Add-Type -Path (Join-Path $PowerBIBin "Microsoft.AnalysisServices.Server.Tabular.dll")
}

function Get-Column {
    param($Table, [string]$Name)
    $column = $Table.Columns.Find($Name)
    if (-not $column) {
        throw "No existe la columna '$Name' en la tabla '$($Table.Name)'."
    }
    return $column
}

function New-CleanTextExpression {
    param(
        [string]$ColumnRef,
        [string]$BlankValue = ""
    )

    $blankLiteral = if ($BlankValue -eq "") { '""' } else { '"' + $BlankValue + '"' }

    return @"
VAR _t0 = UPPER(TRIM(SUBSTITUTE(COALESCE($ColumnRef, ""), UNICHAR(160), " ")))
VAR _t1 = SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(_t0, "Á", "A"), "É", "E"), "Í", "I"), "Ó", "O"), "Ú", "U"), "Ñ", "N")
VAR _t2 = SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(_t1, ".", ""), "  ", " "), "  ", " ")
RETURN IF(_t2 = "", $blankLiteral, _t2)
"@
}

function New-EmpresaKeyExpression {
    param([string]$ColumnRef)

    return @"
VAR _t0 = UPPER(TRIM(SUBSTITUTE(COALESCE($ColumnRef, ""), UNICHAR(160), " ")))
VAR _t1 = SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(_t0, "Á", "A"), "É", "E"), "Í", "I"), "Ó", "O"), "Ú", "U"), "Ñ", "N")
VAR _t2 = SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(_t1, ".", ""), "  ", " "), "  ", " ")
RETURN
    SWITCH(
        TRUE(),
        _t2 = "", "SIN_EMPRESA",
        _t2 IN { "CHALLENGER SAS", "CHALLENGER S A S" }, "CHALLENGER SAS",
        _t2 IN { "LEMCO SAS", "LEMCO S A S" }, "LEMCO SAS",
        CONTAINSSTRING(_t2, "FUNDACION CHALLENGER"), "FUNDACION CHALLENGER",
        _t2
    )
"@
}

function New-EstadoInduccionExpression {
    param([string]$ColumnRef)

    return @"
VAR _t0 = UPPER(TRIM(SUBSTITUTE(COALESCE($ColumnRef, ""), UNICHAR(160), " ")))
VAR _t1 = SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(_t0, "Á", "A"), "É", "E"), "Í", "I"), "Ó", "O"), "Ú", "U"), "Ñ", "N")
RETURN
    SWITCH(
        TRUE(),
        _t1 = "", "SIN_ESTADO",
        _t1 = "NO APROBO", "NO_APROBO",
        _t1
    )
"@
}

function Set-CalculatedColumn {
    param(
        $Model,
        [string]$TableName,
        [string]$ColumnName,
        [string]$Expression,
        [string]$DataType = "String",
        [bool]$Hidden = $true,
        [string]$FormatString = ""
    )

    $table = $Model.Tables.Find($TableName)
    if (-not $table) {
        throw "No existe la tabla '$TableName'."
    }

    $column = $table.Columns.Find($ColumnName)
    if ($column -and $column.GetType().Name -ne "CalculatedColumn") {
        throw "La columna '$TableName[$ColumnName]' ya existe y no es calculada."
    }

    if (-not $column) {
        $column = New-Object Microsoft.AnalysisServices.Tabular.CalculatedColumn
        $column.Name = $ColumnName
        $table.Columns.Add($column)
    }

    $column.Expression = $Expression
    $column.DataType = [Enum]::Parse([Microsoft.AnalysisServices.Tabular.DataType], $DataType)
    $column.IsHidden = $Hidden
    if ($FormatString -ne "") {
        $column.FormatString = $FormatString
    }
}

function Set-CalculatedTable {
    param(
        $Model,
        [string]$TableName,
        [string]$Expression,
        [array]$Columns,
        [bool]$Hidden = $false
    )

    $table = New-Object Microsoft.AnalysisServices.Tabular.Table
    $table.Name = $TableName
    $table.IsHidden = $Hidden

    $partition = New-Object Microsoft.AnalysisServices.Tabular.Partition
    $partition.Name = $TableName
    $partition.Mode = [Microsoft.AnalysisServices.Tabular.ModeType]::Import
    $source = New-Object Microsoft.AnalysisServices.Tabular.CalculatedPartitionSource
    $source.Expression = $Expression
    $partition.Source = $source
    $table.Partitions.Add($partition)

    foreach ($spec in $Columns) {
        $column = New-Object Microsoft.AnalysisServices.Tabular.CalculatedTableColumn
        $column.Name = $spec.Name
        $column.SourceColumn = "[$($spec.Source)]"
        $column.DataType = [Enum]::Parse([Microsoft.AnalysisServices.Tabular.DataType], $spec.DataType)
        if ($spec.ContainsKey("Hidden")) {
            $column.IsHidden = [bool]$spec.Hidden
        }
        if ($spec.ContainsKey("FormatString")) {
            $column.FormatString = [string]$spec.FormatString
        }
        $table.Columns.Add($column)
    }

    $Model.Tables.Add($table)
}

function Set-Measure {
    param(
        $Table,
        [string]$Name,
        [string]$Expression,
        [string]$FormatString = "",
        [string]$DisplayFolder = ""
    )

    $measure = $Table.Measures.Find($Name)
    if (-not $measure) {
        $measure = New-Object Microsoft.AnalysisServices.Tabular.Measure
        $measure.Name = $Name
        $Table.Measures.Add($measure)
    }

    $measure.Expression = $Expression
    if ($FormatString -ne "") {
        $measure.FormatString = $FormatString
    }
    if ($DisplayFolder -ne "") {
        $measure.DisplayFolder = $DisplayFolder
    }
}

function Add-Relationship {
    param(
        $Model,
        [string]$Name,
        [string]$FromTable,
        [string]$FromColumn,
        [string]$ToTable,
        [string]$ToColumn
    )

    $existing = $Model.Relationships.Find($Name)
    if ($existing) {
        $Model.Relationships.Remove($existing)
    }

    $rel = New-Object Microsoft.AnalysisServices.Tabular.SingleColumnRelationship
    $rel.Name = $Name
    $rel.FromColumn = (Get-Column -Table $Model.Tables.Find($FromTable) -Name $FromColumn)
    $rel.ToColumn = (Get-Column -Table $Model.Tables.Find($ToTable) -Name $ToColumn)
    $rel.FromCardinality = [Microsoft.AnalysisServices.Tabular.RelationshipEndCardinality]::Many
    $rel.ToCardinality = [Microsoft.AnalysisServices.Tabular.RelationshipEndCardinality]::One
    $rel.CrossFilteringBehavior = [Microsoft.AnalysisServices.Tabular.CrossFilteringBehavior]::OneDirection
    $rel.IsActive = $true
    $Model.Relationships.Add($rel)
}

function Set-ModelLayer {
    param([int]$LocalPort)

    Add-TomAssemblies
    $server = New-Object Microsoft.AnalysisServices.Tabular.Server
    $server.Connect("localhost:$LocalPort")
    $db = $server.Databases[0]
    $model = $db.Model

    $managedTables = @(
        "Medidas_AD",
        "Fct_Induccion",
        "Dim_Empresa",
        "Dim_Area",
        "Dim_TipoFormacion",
        "Dim_Modalidad",
        "Dim_TemaFormacion",
        "Dim_EntidadFormadora",
        "Dim_EstadoFormacion",
        "Dim_EstadoInduccion",
        "Dim_SegmentoUC"
    )

    foreach ($rel in @($model.Relationships)) {
        if (
            $rel.Name -like "AD_*" -or
            $rel.ToTable.Name -like "LocalDateTable_*" -or
            $rel.FromTable.Name -like "LocalDateTable_*" -or
            $rel.ToTable.Name -like "DateTableTemplate_*" -or
            $rel.FromTable.Name -like "DateTableTemplate_*" -or
            $managedTables -contains $rel.FromTable.Name -or
            $managedTables -contains $rel.ToTable.Name
        ) {
            $model.Relationships.Remove($rel) | Out-Null
        }
    }

    foreach ($name in $managedTables) {
        $table = $model.Tables.Find($name)
        if ($table) {
            $model.Tables.Remove($table) | Out-Null
        }
    }

    foreach ($table in @($model.Tables)) {
        foreach ($column in @($table.Columns)) {
            try {
                foreach ($variation in @($column.Variations)) {
                    $column.Variations.Remove($variation) | Out-Null
                }
            }
            catch {
                # Some column types do not expose variations.
            }
        }
    }

    foreach ($table in @($model.Tables)) {
        if ($table.Name -like "LocalDateTable_*" -or $table.Name -like "DateTableTemplate_*") {
            $model.Tables.Remove($table) | Out-Null
        }
    }

    $ann = $model.Annotations | Where-Object { $_.Name -eq "__PBI_TimeIntelligenceEnabled" } | Select-Object -First 1
    if (-not $ann) {
        $ann = New-Object Microsoft.AnalysisServices.Tabular.Annotation
        $ann.Name = "__PBI_TimeIntelligenceEnabled"
        $model.Annotations.Add($ann)
    }
    $ann.Value = "0"

    Set-CalculatedColumn $model "Dim_Calendario" "Fecha" "'Dim_Calendario'[Date]" "DateTime" $false "Short Date"
    Set-CalculatedColumn $model "Dim_Calendario" "Anio" "YEAR('Dim_Calendario'[Date])" "Int64" $false "0"
    Set-CalculatedColumn $model "Dim_Calendario" "MesNumero" "MONTH('Dim_Calendario'[Date])" "Int64" $false "0"
    Set-CalculatedColumn $model "Dim_Calendario" "MesNombreCorto" "FORMAT('Dim_Calendario'[Date], ""mmm"")" "String" $false
    Set-CalculatedColumn $model "Dim_Calendario" "AnioMes" "FORMAT('Dim_Calendario'[Date], ""YYYY-MM"")" "String" $false
    Set-CalculatedColumn $model "Dim_Calendario" "AnioMesOrden" "YEAR('Dim_Calendario'[Date]) * 100 + MONTH('Dim_Calendario'[Date])" "Int64" $true "0"
    Set-CalculatedColumn $model "Dim_Calendario" "Trimestre" """T"" & FORMAT(QUARTER('Dim_Calendario'[Date]), ""0"")" "String" $false

    foreach ($colName in @("Año", "AñoMes", "Numero Mes", "Mes Abreviado", "Numero Semana", "Numero Dia", "Numero Dia de la Semana", "Dia Semana", "Dia Abreviado", "Día del año")) {
        $col = $model.Tables.Find("Dim_Calendario").Columns.Find($colName)
        if ($col) {
            $col.IsHidden = $true
        }
    }

    Set-CalculatedColumn $model "Fct_PlanFormacion" "Fecha_Formacion" "VAR _d = 'Fct_PlanFormacion'[FECHA DE FORMACIÓN] RETURN IF(ISBLANK(_d), BLANK(), DATE(YEAR(_d), MONTH(_d), DAY(_d)))" "DateTime" $true "Short Date"
    Set-CalculatedColumn $model "Fct_PlanFormacion" "TemaFormacion_Key" (New-CleanTextExpression "'Fct_PlanFormacion'[NOMBRE FORMACIÓN]") "String" $true
    Set-CalculatedColumn $model "Fct_PlanFormacion" "TipoFormacion_Key" (New-CleanTextExpression "'Fct_PlanFormacion'[TIPO DE FORMACIÓN]" "SIN_TIPO") "String" $true
    Set-CalculatedColumn $model "Fct_PlanFormacion" "Modalidad_Key" (New-CleanTextExpression "'Fct_PlanFormacion'[MODALIDAD]" "SIN_MODALIDAD") "String" $true
    Set-CalculatedColumn $model "Fct_PlanFormacion" "Area_Key" (New-CleanTextExpression "'Fct_PlanFormacion'[AREA A FORMAR]" "SIN_AREA") "String" $true
    Set-CalculatedColumn $model "Fct_PlanFormacion" "EstadoFormacion_Key" (New-CleanTextExpression "'Fct_PlanFormacion'[ESTADO DE FORMACIÓN]" "SIN_ESTADO") "String" $true
    Set-CalculatedColumn $model "Fct_PlanFormacion" "EntidadFormadora_Key" (New-CleanTextExpression "'Fct_PlanFormacion'[ENTIDAD]" "SIN_ENTIDAD") "String" $true

    Set-CalculatedColumn $model "Fct_AsistenciaFormacion" "Fecha_Asistencia" "VAR _d = 'Fct_AsistenciaFormacion'[Hora de inicio] RETURN IF(ISBLANK(_d), BLANK(), DATE(YEAR(_d), MONTH(_d), DAY(_d)))" "DateTime" $true "Short Date"
    Set-CalculatedColumn $model "Fct_AsistenciaFormacion" "TemaFormacion_Key" (New-CleanTextExpression "'Fct_AsistenciaFormacion'[Selecciona la formación en la que estás participando]") "String" $true
    Set-CalculatedColumn $model "Fct_AsistenciaFormacion" "Empresa_Key" (New-EmpresaKeyExpression "'Fct_AsistenciaFormacion'[Indícanos de qué empresa haces parte]") "String" $true

    Set-CalculatedColumn $model "Fct_EncuestaFormacion" "Fecha_Encuesta" "VAR _d = 'Fct_EncuestaFormacion'[Hora de inicio] RETURN IF(ISBLANK(_d), BLANK(), DATE(YEAR(_d), MONTH(_d), DAY(_d)))" "DateTime" $true "Short Date"
    Set-CalculatedColumn $model "Fct_EncuestaFormacion" "TemaFormacion_Key" (New-CleanTextExpression "'Fct_EncuestaFormacion'[¡Cuéntanos tu percepción de la formación!]" ) "String" $true
    Set-CalculatedColumn $model "Fct_EncuestaFormacion" "Empresa_Key" (New-EmpresaKeyExpression "'Fct_EncuestaFormacion'[Indícanos de qué empresa haces parte]") "String" $true

    $model.SaveChanges()

    $empresaAntes = New-EmpresaKeyExpression "'Fct_InduccionColaborador_antes_de_UC_2025'[EMPRESA]"
    $empresaUC2025 = New-EmpresaKeyExpression "'Fct_InduccionColaborador_UC_2025'[EMPRESA]"
    $empresaUC2026 = New-EmpresaKeyExpression "'Fct_InduccionColaborador_UC_2026'[EMPRESA]"
    $areaAntes = New-CleanTextExpression "'Fct_InduccionColaborador_antes_de_UC_2025'[DEPENDENCIA]" "SIN_AREA"
    $areaUC2025 = New-CleanTextExpression "'Fct_InduccionColaborador_UC_2025'[DEPENDENCIA]" "SIN_AREA"
    $areaUC2026 = New-CleanTextExpression "'Fct_InduccionColaborador_UC_2026'[DEPENDENCIA]" "SIN_AREA"
    $estadoAntes = New-EstadoInduccionExpression "'Fct_InduccionColaborador_antes_de_UC_2025'[Estado]"
    $estadoUC2025 = New-EstadoInduccionExpression "'Fct_InduccionColaborador_UC_2025'[Estado]"
    $estadoUC2026 = New-EstadoInduccionExpression "'Fct_InduccionColaborador_UC_2026'[Estado]"

    $fctInduccion = @"
VAR _Antes =
    SELECTCOLUMNS(
        'Fct_InduccionColaborador_antes_de_UC_2025',
        "Cohorte_Fuente", "Antes_UC_2025",
        "SegmentoUC_Key", "Antes_UC",
        "Colaborador_Key", FORMAT('Fct_InduccionColaborador_antes_de_UC_2025'[ID], "0"),
        "Nombres", 'Fct_InduccionColaborador_antes_de_UC_2025'[NOMBRES],
        "Apellidos", 'Fct_InduccionColaborador_antes_de_UC_2025'[APELLIDOS],
        "Correo", 'Fct_InduccionColaborador_antes_de_UC_2025'[CORREO],
        "Ciudad", 'Fct_InduccionColaborador_antes_de_UC_2025'[CIUDAD],
        "Empresa_Key", $empresaAntes,
        "Area_Key", $areaAntes,
        "Cargo", 'Fct_InduccionColaborador_antes_de_UC_2025'[CARGO],
        "Gerencia", 'Fct_InduccionColaborador_antes_de_UC_2025'[GERENCIA O DIRECCIÓN],
        "Fecha_Ingreso", VAR _d = 'Fct_InduccionColaborador_antes_de_UC_2025'[FECHA_INGRESO] RETURN IF(ISBLANK(_d), BLANK(), DATE(YEAR(_d), MONTH(_d), DAY(_d))),
        "Fecha_Certificado", VAR _d = 'Fct_InduccionColaborador_antes_de_UC_2025'[Fecha Certificado] RETURN IF(ISBLANK(_d), BLANK(), DATE(YEAR(_d), MONTH(_d), DAY(_d))),
        "EstadoInduccion_Key", $estadoAntes,
        "Horas_Induccion", 'Fct_InduccionColaborador_antes_de_UC_2025'[Horas de inducción],
        "Min_Entrenamiento", 'Fct_InduccionColaborador_antes_de_UC_2025'[Min de entrenamientos],
        "Entrenamiento", VAR _raw = 'Fct_InduccionColaborador_antes_de_UC_2025'[Entrenamiento ] VAR _t0 = UPPER(TRIM(SUBSTITUTE(COALESCE(_raw, ""), UNICHAR(160), " "))) VAR _t1 = SUBSTITUTE(_t0, UNICHAR(205), "I") RETURN IF(_t1 = "", BLANK(), _t1),
        "Estado_Colaborador", 'Fct_InduccionColaborador_antes_de_UC_2025'[Estado del colaborador],
        "Tiempo_Finalizacion_Dias", VAR _fi = 'Fct_InduccionColaborador_antes_de_UC_2025'[FECHA_INGRESO] VAR _fc = 'Fct_InduccionColaborador_antes_de_UC_2025'[Fecha Certificado] RETURN IF(NOT ISBLANK(_fi) && NOT ISBLANK(_fc), DATEDIFF(_fi, _fc, DAY), BLANK())
    )
VAR _UC2025 =
    SELECTCOLUMNS(
        'Fct_InduccionColaborador_UC_2025',
        "Cohorte_Fuente", "UC_2025",
        "SegmentoUC_Key", VAR _d = 'Fct_InduccionColaborador_UC_2025'[FECHA_INGRESO] RETURN IF(NOT ISBLANK(_d) && _d < DATE(2025, 7, 4), "Antes_UC", "UC_2025"),
        "Colaborador_Key", FORMAT('Fct_InduccionColaborador_UC_2025'[CEDULA], "0"),
        "Nombres", 'Fct_InduccionColaborador_UC_2025'[NOMBRES],
        "Apellidos", 'Fct_InduccionColaborador_UC_2025'[APELLIDOS],
        "Correo", 'Fct_InduccionColaborador_UC_2025'[CORREO],
        "Ciudad", 'Fct_InduccionColaborador_UC_2025'[CIUDAD],
        "Empresa_Key", $empresaUC2025,
        "Area_Key", $areaUC2025,
        "Cargo", 'Fct_InduccionColaborador_UC_2025'[CARGO],
        "Gerencia", 'Fct_InduccionColaborador_UC_2025'[GERENCIA O DIRECCIÓN],
        "Fecha_Ingreso", VAR _d = 'Fct_InduccionColaborador_UC_2025'[FECHA_INGRESO] RETURN IF(ISBLANK(_d), BLANK(), DATE(YEAR(_d), MONTH(_d), DAY(_d))),
        "Fecha_Certificado", VAR _d = 'Fct_InduccionColaborador_UC_2025'[Fecha Certificado] RETURN IF(ISBLANK(_d), BLANK(), DATE(YEAR(_d), MONTH(_d), DAY(_d))),
        "EstadoInduccion_Key", $estadoUC2025,
        "Horas_Induccion", 'Fct_InduccionColaborador_UC_2025'[Horas de inducción],
        "Min_Entrenamiento", 'Fct_InduccionColaborador_UC_2025'[Min de entrenamientos],
        "Entrenamiento", VAR _raw = 'Fct_InduccionColaborador_UC_2025'[Entrenamiento ] VAR _t0 = UPPER(TRIM(SUBSTITUTE(COALESCE(_raw, ""), UNICHAR(160), " "))) VAR _t1 = SUBSTITUTE(_t0, UNICHAR(205), "I") RETURN IF(_t1 = "", BLANK(), _t1),
        "Estado_Colaborador", 'Fct_InduccionColaborador_UC_2025'[Estado del colaborador],
        "Tiempo_Finalizacion_Dias", VAR _fi = 'Fct_InduccionColaborador_UC_2025'[FECHA_INGRESO] VAR _fc = 'Fct_InduccionColaborador_UC_2025'[Fecha Certificado] RETURN IF(NOT ISBLANK(_fi) && NOT ISBLANK(_fc), DATEDIFF(_fi, _fc, DAY), BLANK())
    )
VAR _UC2026 =
    SELECTCOLUMNS(
        'Fct_InduccionColaborador_UC_2026',
        "Cohorte_Fuente", "UC_2026",
        "SegmentoUC_Key", "UC_2026",
        "Colaborador_Key", FORMAT('Fct_InduccionColaborador_UC_2026'[CEDULA], "0"),
        "Nombres", 'Fct_InduccionColaborador_UC_2026'[NOMBRES],
        "Apellidos", 'Fct_InduccionColaborador_UC_2026'[APELLIDOS],
        "Correo", 'Fct_InduccionColaborador_UC_2026'[CORREO],
        "Ciudad", 'Fct_InduccionColaborador_UC_2026'[CIUDAD],
        "Empresa_Key", $empresaUC2026,
        "Area_Key", $areaUC2026,
        "Cargo", 'Fct_InduccionColaborador_UC_2026'[CARGO],
        "Gerencia", 'Fct_InduccionColaborador_UC_2026'[GERENCIA O DIRECCIÓN],
        "Fecha_Ingreso", VAR _d = 'Fct_InduccionColaborador_UC_2026'[FECHA_INGRESO] RETURN IF(ISBLANK(_d), BLANK(), DATE(YEAR(_d), MONTH(_d), DAY(_d))),
        "Fecha_Certificado", VAR _txt = TRIM(SUBSTITUTE('Fct_InduccionColaborador_UC_2026'[Fecha Certificado], UNICHAR(160), " ")) RETURN IFERROR(DATEVALUE(_txt), BLANK()),
        "EstadoInduccion_Key", $estadoUC2026,
        "Horas_Induccion", 'Fct_InduccionColaborador_UC_2026'[Horas de inducción],
        "Min_Entrenamiento", 'Fct_InduccionColaborador_UC_2026'[Min de entrenamientos],
        "Entrenamiento", VAR _raw = 'Fct_InduccionColaborador_UC_2026'[Entrenamiento ] VAR _t0 = UPPER(TRIM(SUBSTITUTE(COALESCE(_raw, ""), UNICHAR(160), " "))) VAR _t1 = SUBSTITUTE(_t0, UNICHAR(205), "I") RETURN IF(_t1 = "", BLANK(), _t1),
        "Estado_Colaborador", 'Fct_InduccionColaborador_UC_2026'[Estado del colaborador],
        "Tiempo_Finalizacion_Dias", VAR _fi = 'Fct_InduccionColaborador_UC_2026'[FECHA_INGRESO] VAR _txt = TRIM(SUBSTITUTE('Fct_InduccionColaborador_UC_2026'[Fecha Certificado], UNICHAR(160), " ")) VAR _fc = IFERROR(DATEVALUE(_txt), BLANK()) RETURN IF(NOT ISBLANK(_fi) && NOT ISBLANK(_fc), DATEDIFF(_fi, _fc, DAY), BLANK())
    )
VAR _Base = UNION(_Antes, _UC2025, _UC2026)
RETURN
    FILTER(_Base, [Colaborador_Key] <> "" && NOT ISBLANK([Fecha_Ingreso]))
"@

    Set-CalculatedTable $model "Fct_Induccion" $fctInduccion @(
        @{ Name = "Cohorte_Fuente"; Source = "Cohorte_Fuente"; DataType = "String" },
        @{ Name = "SegmentoUC_Key"; Source = "SegmentoUC_Key"; DataType = "String"; Hidden = $true },
        @{ Name = "Colaborador_Key"; Source = "Colaborador_Key"; DataType = "String"; Hidden = $true },
        @{ Name = "Nombres"; Source = "Nombres"; DataType = "String"; Hidden = $true },
        @{ Name = "Apellidos"; Source = "Apellidos"; DataType = "String"; Hidden = $true },
        @{ Name = "Correo"; Source = "Correo"; DataType = "String"; Hidden = $true },
        @{ Name = "Ciudad"; Source = "Ciudad"; DataType = "String" },
        @{ Name = "Empresa_Key"; Source = "Empresa_Key"; DataType = "String"; Hidden = $true },
        @{ Name = "Area_Key"; Source = "Area_Key"; DataType = "String"; Hidden = $true },
        @{ Name = "Cargo"; Source = "Cargo"; DataType = "String"; Hidden = $true },
        @{ Name = "Gerencia"; Source = "Gerencia"; DataType = "String" },
        @{ Name = "Fecha_Ingreso"; Source = "Fecha_Ingreso"; DataType = "DateTime"; FormatString = "Short Date" },
        @{ Name = "Fecha_Certificado"; Source = "Fecha_Certificado"; DataType = "DateTime"; FormatString = "Short Date" },
        @{ Name = "EstadoInduccion_Key"; Source = "EstadoInduccion_Key"; DataType = "String"; Hidden = $true },
        @{ Name = "Horas_Induccion"; Source = "Horas_Induccion"; DataType = "Int64"; FormatString = "0" },
        @{ Name = "Min_Entrenamiento"; Source = "Min_Entrenamiento"; DataType = "Int64"; FormatString = "0" },
        @{ Name = "Entrenamiento"; Source = "Entrenamiento"; DataType = "String" },
        @{ Name = "Estado_Colaborador"; Source = "Estado_Colaborador"; DataType = "String" },
        @{ Name = "Tiempo_Finalizacion_Dias"; Source = "Tiempo_Finalizacion_Dias"; DataType = "Int64"; FormatString = "0" }
    )

    Set-CalculatedTable $model "Medidas_AD" "DATATABLE(""Indice"", INTEGER, {{ 0 }})" @(
        @{ Name = "Indice"; Source = "Indice"; DataType = "Int64"; Hidden = $true }
    ) $true

    Set-CalculatedTable $model "Dim_SegmentoUC" @"
UNION(
    ROW("SegmentoUC_Key", "Antes_UC", "SegmentoUC", "Antes UC", "OrdenSegmentoUC", 1, "Fecha_Lanzamiento_UC", DATE(2025, 7, 4)),
    ROW("SegmentoUC_Key", "UC_2025", "SegmentoUC", "UC 2025", "OrdenSegmentoUC", 2, "Fecha_Lanzamiento_UC", DATE(2025, 7, 4)),
    ROW("SegmentoUC_Key", "UC_2026", "SegmentoUC", "UC 2026", "OrdenSegmentoUC", 3, "Fecha_Lanzamiento_UC", DATE(2025, 7, 4))
)
"@ @(
        @{ Name = "SegmentoUC_Key"; Source = "SegmentoUC_Key"; DataType = "String"; Hidden = $true },
        @{ Name = "SegmentoUC"; Source = "SegmentoUC"; DataType = "String" },
        @{ Name = "OrdenSegmentoUC"; Source = "OrdenSegmentoUC"; DataType = "Int64"; Hidden = $true },
        @{ Name = "Fecha_Lanzamiento_UC"; Source = "Fecha_Lanzamiento_UC"; DataType = "DateTime"; FormatString = "Short Date" }
    )

    $model.SaveChanges()

    Set-CalculatedTable $model "Dim_Empresa" @"
VAR _Empresas =
    DISTINCT(
        UNION(
            SELECTCOLUMNS('Fct_AsistenciaFormacion', "Empresa_Key", 'Fct_AsistenciaFormacion'[Empresa_Key]),
            SELECTCOLUMNS('Fct_EncuestaFormacion', "Empresa_Key", 'Fct_EncuestaFormacion'[Empresa_Key]),
            SELECTCOLUMNS('Fct_Induccion', "Empresa_Key", 'Fct_Induccion'[Empresa_Key])
        )
    )
RETURN
    ADDCOLUMNS(_Empresas, "Empresa", [Empresa_Key])
"@ @(
        @{ Name = "Empresa_Key"; Source = "Empresa_Key"; DataType = "String"; Hidden = $true },
        @{ Name = "Empresa"; Source = "Empresa"; DataType = "String" }
    )

    Set-CalculatedTable $model "Dim_Area" @"
VAR _Areas =
    DISTINCT(
        UNION(
            SELECTCOLUMNS('Fct_PlanFormacion', "Area_Key", 'Fct_PlanFormacion'[Area_Key]),
            SELECTCOLUMNS('Fct_Induccion', "Area_Key", 'Fct_Induccion'[Area_Key])
        )
    )
RETURN
    ADDCOLUMNS(_Areas, "Area", [Area_Key])
"@ @(
        @{ Name = "Area_Key"; Source = "Area_Key"; DataType = "String"; Hidden = $true },
        @{ Name = "Area"; Source = "Area"; DataType = "String" }
    )

    Set-CalculatedTable $model "Dim_TemaFormacion" @"
VAR _Temas =
    DISTINCT(
        UNION(
            SELECTCOLUMNS('Fct_PlanFormacion', "TemaFormacion_Key", 'Fct_PlanFormacion'[TemaFormacion_Key]),
            SELECTCOLUMNS('Fct_AsistenciaFormacion', "TemaFormacion_Key", 'Fct_AsistenciaFormacion'[TemaFormacion_Key]),
            SELECTCOLUMNS('Fct_EncuestaFormacion', "TemaFormacion_Key", 'Fct_EncuestaFormacion'[TemaFormacion_Key])
        )
    )
RETURN
    FILTER(ADDCOLUMNS(_Temas, "TemaFormacion", [TemaFormacion_Key]), [TemaFormacion_Key] <> "")
"@ @(
        @{ Name = "TemaFormacion_Key"; Source = "TemaFormacion_Key"; DataType = "String"; Hidden = $true },
        @{ Name = "TemaFormacion"; Source = "TemaFormacion"; DataType = "String" }
    )

    Set-CalculatedTable $model "Dim_TipoFormacion" @"
ADDCOLUMNS(DISTINCT(SELECTCOLUMNS('Fct_PlanFormacion', "TipoFormacion_Key", 'Fct_PlanFormacion'[TipoFormacion_Key])), "TipoFormacion", [TipoFormacion_Key])
"@ @(
        @{ Name = "TipoFormacion_Key"; Source = "TipoFormacion_Key"; DataType = "String"; Hidden = $true },
        @{ Name = "TipoFormacion"; Source = "TipoFormacion"; DataType = "String" }
    )

    Set-CalculatedTable $model "Dim_Modalidad" @"
ADDCOLUMNS(DISTINCT(SELECTCOLUMNS('Fct_PlanFormacion', "Modalidad_Key", 'Fct_PlanFormacion'[Modalidad_Key])), "Modalidad", [Modalidad_Key])
"@ @(
        @{ Name = "Modalidad_Key"; Source = "Modalidad_Key"; DataType = "String"; Hidden = $true },
        @{ Name = "Modalidad"; Source = "Modalidad"; DataType = "String" }
    )

    Set-CalculatedTable $model "Dim_EntidadFormadora" @"
ADDCOLUMNS(DISTINCT(SELECTCOLUMNS('Fct_PlanFormacion', "EntidadFormadora_Key", 'Fct_PlanFormacion'[EntidadFormadora_Key])), "EntidadFormadora", [EntidadFormadora_Key])
"@ @(
        @{ Name = "EntidadFormadora_Key"; Source = "EntidadFormadora_Key"; DataType = "String"; Hidden = $true },
        @{ Name = "EntidadFormadora"; Source = "EntidadFormadora"; DataType = "String" }
    )

    Set-CalculatedTable $model "Dim_EstadoFormacion" @"
ADDCOLUMNS(DISTINCT(SELECTCOLUMNS('Fct_PlanFormacion', "EstadoFormacion_Key", 'Fct_PlanFormacion'[EstadoFormacion_Key])), "EstadoFormacion", SWITCH([EstadoFormacion_Key], "SIN_ESTADO", "Sin estado", [EstadoFormacion_Key]))
"@ @(
        @{ Name = "EstadoFormacion_Key"; Source = "EstadoFormacion_Key"; DataType = "String"; Hidden = $true },
        @{ Name = "EstadoFormacion"; Source = "EstadoFormacion"; DataType = "String" }
    )

    Set-CalculatedTable $model "Dim_EstadoInduccion" @"
ADDCOLUMNS(
    DISTINCT(SELECTCOLUMNS('Fct_Induccion', "EstadoInduccion_Key", 'Fct_Induccion'[EstadoInduccion_Key])),
    "EstadoInduccion",
    SWITCH(
        [EstadoInduccion_Key],
        "APROBO", "Aprobo",
        "NO_APROBO", "No Aprobo",
        "RETIRADO", "Retirado",
        "RENUNCIA", "Renuncia",
        "SIN_ESTADO", "Sin estado",
        [EstadoInduccion_Key]
    )
)
"@ @(
        @{ Name = "EstadoInduccion_Key"; Source = "EstadoInduccion_Key"; DataType = "String"; Hidden = $true },
        @{ Name = "EstadoInduccion"; Source = "EstadoInduccion"; DataType = "String" }
    )

    $model.SaveChanges()

    $cal = $model.Tables.Find("Dim_Calendario")
    if ($cal.Columns.Find("MesNombreCorto") -and $cal.Columns.Find("MesNumero")) {
        $cal.Columns.Find("MesNombreCorto").SortByColumn = $cal.Columns.Find("MesNumero")
    }
    if ($cal.Columns.Find("AnioMes") -and $cal.Columns.Find("AnioMesOrden")) {
        $cal.Columns.Find("AnioMes").SortByColumn = $cal.Columns.Find("AnioMesOrden")
    }
    $seg = $model.Tables.Find("Dim_SegmentoUC")
    if ($seg.Columns.Find("SegmentoUC") -and $seg.Columns.Find("OrdenSegmentoUC")) {
        $seg.Columns.Find("SegmentoUC").SortByColumn = $seg.Columns.Find("OrdenSegmentoUC")
    }

    Add-Relationship $model "AD_Calendario_Plan" "Fct_PlanFormacion" "Fecha_Formacion" "Dim_Calendario" "Date"
    Add-Relationship $model "AD_Calendario_Asistencia" "Fct_AsistenciaFormacion" "Fecha_Asistencia" "Dim_Calendario" "Date"
    Add-Relationship $model "AD_Calendario_Encuesta" "Fct_EncuestaFormacion" "Fecha_Encuesta" "Dim_Calendario" "Date"
    Add-Relationship $model "AD_Calendario_Induccion" "Fct_Induccion" "Fecha_Ingreso" "Dim_Calendario" "Date"
    Add-Relationship $model "AD_Tema_Plan" "Fct_PlanFormacion" "TemaFormacion_Key" "Dim_TemaFormacion" "TemaFormacion_Key"
    Add-Relationship $model "AD_Tema_Asistencia" "Fct_AsistenciaFormacion" "TemaFormacion_Key" "Dim_TemaFormacion" "TemaFormacion_Key"
    Add-Relationship $model "AD_Tema_Encuesta" "Fct_EncuestaFormacion" "TemaFormacion_Key" "Dim_TemaFormacion" "TemaFormacion_Key"
    Add-Relationship $model "AD_Empresa_Asistencia" "Fct_AsistenciaFormacion" "Empresa_Key" "Dim_Empresa" "Empresa_Key"
    Add-Relationship $model "AD_Empresa_Encuesta" "Fct_EncuestaFormacion" "Empresa_Key" "Dim_Empresa" "Empresa_Key"
    Add-Relationship $model "AD_Empresa_Induccion" "Fct_Induccion" "Empresa_Key" "Dim_Empresa" "Empresa_Key"
    Add-Relationship $model "AD_Area_Plan" "Fct_PlanFormacion" "Area_Key" "Dim_Area" "Area_Key"
    Add-Relationship $model "AD_Area_Induccion" "Fct_Induccion" "Area_Key" "Dim_Area" "Area_Key"
    Add-Relationship $model "AD_TipoFormacion_Plan" "Fct_PlanFormacion" "TipoFormacion_Key" "Dim_TipoFormacion" "TipoFormacion_Key"
    Add-Relationship $model "AD_Modalidad_Plan" "Fct_PlanFormacion" "Modalidad_Key" "Dim_Modalidad" "Modalidad_Key"
    Add-Relationship $model "AD_EntidadFormadora_Plan" "Fct_PlanFormacion" "EntidadFormadora_Key" "Dim_EntidadFormadora" "EntidadFormadora_Key"
    Add-Relationship $model "AD_EstadoFormacion_Plan" "Fct_PlanFormacion" "EstadoFormacion_Key" "Dim_EstadoFormacion" "EstadoFormacion_Key"
    Add-Relationship $model "AD_EstadoInduccion_Fct" "Fct_Induccion" "EstadoInduccion_Key" "Dim_EstadoInduccion" "EstadoInduccion_Key"
    Add-Relationship $model "AD_SegmentoUC_Fct" "Fct_Induccion" "SegmentoUC_Key" "Dim_SegmentoUC" "SegmentoUC_Key"

    $m = $model.Tables.Find("Medidas_AD")
    foreach ($oldMeasureName in @(
        "Encuesta Satisfaccion General",
        "Encuesta Satisfaccion Variacion MoM",
        "Encuesta Satisfaccion Variacion YoY"
    )) {
        $oldMeasure = $m.Measures.Find($oldMeasureName)
        if ($oldMeasure) {
            $m.Measures.Remove($oldMeasure)
        }
    }

    Set-Measure $m "Plan Actividades Planificadas" "COUNTROWS('Fct_PlanFormacion')" "#,0" "01 Plan Formacion"
    Set-Measure $m "Plan Actividades Ejecutadas" "CALCULATE(COUNTROWS('Fct_PlanFormacion'), 'Fct_PlanFormacion'[EstadoFormacion_Key] = ""EJECUTADA"")" "#,0" "01 Plan Formacion"
    Set-Measure $m "Plan Actividades Canceladas" "CALCULATE(COUNTROWS('Fct_PlanFormacion'), 'Fct_PlanFormacion'[EstadoFormacion_Key] = ""CANCELADA"")" "#,0" "01 Plan Formacion"
    Set-Measure $m "Plan Actividades Reprogramadas" "CALCULATE(COUNTROWS('Fct_PlanFormacion'), 'Fct_PlanFormacion'[EstadoFormacion_Key] = ""REPROGRAMADA"")" "#,0" "01 Plan Formacion"
    Set-Measure $m "Plan Actividades Vigentes" "[Plan Actividades Planificadas] - [Plan Actividades Canceladas]" "#,0" "01 Plan Formacion"
    Set-Measure $m "Plan Porcentaje Ejecucion" "DIVIDE([Plan Actividades Ejecutadas], [Plan Actividades Vigentes])" "0.0%;-0.0%;0.0%" "01 Plan Formacion"
    Set-Measure $m "Plan Brecha Actividades" "[Plan Actividades Ejecutadas] - [Plan Actividades Vigentes]" "#,0" "01 Plan Formacion"
    Set-Measure $m "Plan Publico Objetivo" "SUM('Fct_PlanFormacion'[PUBLICO OBJETIVO ])" "#,0" "01 Plan Formacion"
    Set-Measure $m "Plan Asistencia Registrada" "SUM('Fct_PlanFormacion'[ASISTENCIA])" "#,0" "01 Plan Formacion"
    Set-Measure $m "% Cobertura" "DIVIDE(SUM('Fct_PlanFormacion'[ASISTENCIA]), SUM('Fct_PlanFormacion'[PUBLICO OBJETIVO ]), 0)" "0.0%;-0.0%;0.0%" "01 Plan Formacion"
    Set-Measure $m "% Brecha Cobertura" "VAR _p = [% Cobertura] RETURN IF(ISBLANK(_p), BLANK(), MAX(0, 1 - _p))" "0.0%;-0.0%;0.0%" "01 Plan Formacion"
    Set-Measure $m "Plan Cobertura Asistencia" "[% Cobertura]" "0.0%;-0.0%;0.0%" "01 Plan Formacion"
    Set-Measure $m "Plan Horas Formacion" "SUM('Fct_PlanFormacion'[TOTAL DE HORAS DE FORMACIÓN ])" "#,0" "01 Plan Formacion"
    Set-Measure $m "Plan Total Horas Formacion" "SUM('Fct_PlanFormacion'[TOTAL DE HORAS DE FORMACIÓN ])" "#,0" "01 Plan Formacion"
    Set-Measure $m "Plan Costo" "SUM('Fct_PlanFormacion'[COSTO])" "$ #,0" "01 Plan Formacion"

    Set-Measure $m "Asistencia Total Registros" "COUNTROWS('Fct_AsistenciaFormacion')" "#,0" "02 Asistencia"
    Set-Measure $m "Asistencia Total Asistentes" "[Asistencia Total Registros]" "#,0" "02 Asistencia"
    Set-Measure $m "Asistencia Participantes Unicos" "DISTINCTCOUNT('Fct_AsistenciaFormacion'[Número de documento del participante])" "#,0" "02 Asistencia"
    Set-Measure $m "Asistencia Formaciones" "DISTINCTCOUNT('Fct_AsistenciaFormacion'[TemaFormacion_Key])" "#,0" "02 Asistencia"
    Set-Measure $m "Asistencia Total Convocados" "[Plan Publico Objetivo]" "#,0" "02 Asistencia"
    Set-Measure $m "Asistencia Porcentaje Asistencia" "DIVIDE([Asistencia Total Asistentes], [Asistencia Total Convocados])" "0.0%;-0.0%;0.0%" "02 Asistencia"
    Set-Measure $m "Asistencia Porcentaje Ausentismo" "VAR _p = [Asistencia Porcentaje Asistencia] RETURN IF(ISBLANK(_p), BLANK(), MAX(0, 1 - _p))" "0.0%;-0.0%;0.0%" "02 Asistencia"
    Set-Measure $m "Asistencia Promedio Por Formacion" "DIVIDE([Asistencia Total Asistentes], [Asistencia Formaciones])" "#,0.0" "02 Asistencia"

    Set-Measure $m "HC Total Colaborador Mes" "DISTINCTCOUNT('Dim_ColaboradorHC'[Colaborador_Key])" "#,0" "08 Headcount HC"
    Set-Measure $m "HC Total Colaboradores Unicos" "DISTINCTCOUNT('Dim_ColaboradorHC'[Numero_Documento])" "#,0" "08 Headcount HC"
    Set-Measure $m "HC Recuento Tipo Cargo" "COUNTA('Dim_ColaboradorHC'[Tipo_Cargo])" "#,0" "08 Headcount HC"
    Set-Measure $m "HC Porcentaje Tipo Cargo" "DIVIDE([HC Recuento Tipo Cargo], CALCULATE([HC Recuento Tipo Cargo], ALLSELECTED('Dim_ColaboradorHC'[Tipo_Cargo])))" "0.0%;-0.0%;0.0%" "08 Headcount HC"
    Set-Measure $m "HC Tipos Cargo" "DISTINCTCOUNT('Dim_ColaboradorHC'[Tipo_Cargo])" "#,0" "08 Headcount HC"
    Set-Measure $m "Asistencia Registros HC Match" @"
VAR _KeysHC = VALUES('Dim_ColaboradorHC'[Colaborador_Key])
RETURN
    CALCULATE(
        [Asistencia Total Registros],
        TREATAS(_KeysHC, 'Fct_AsistenciaFormacion'[Colaborador_Key])
    )
"@ "#,0" "08 Headcount HC"
    Set-Measure $m "Asistencia Colaborador Mes HC Match" @"
VAR _KeysHC = VALUES('Dim_ColaboradorHC'[Colaborador_Key])
RETURN
    CALCULATE(
        DISTINCTCOUNT('Fct_AsistenciaFormacion'[Colaborador_Key]),
        TREATAS(_KeysHC, 'Fct_AsistenciaFormacion'[Colaborador_Key])
    )
"@ "#,0" "08 Headcount HC"
    Set-Measure $m "Asistencia Distribucion Tipo Cargo %" "DIVIDE([Asistencia Registros HC Match], CALCULATE([Asistencia Registros HC Match], ALLSELECTED('Dim_ColaboradorHC'[Tipo_Cargo])))" "0.0%;-0.0%;0.0%" "08 Headcount HC"
    Set-Measure $m "Asistencia Registros Sin HC Match" @"
VAR _Total =
    CALCULATE(
        [Asistencia Total Registros],
        REMOVEFILTERS('Dim_ColaboradorHC')
    )
VAR _Match =
    CALCULATE(
        [Asistencia Registros HC Match],
        REMOVEFILTERS('Dim_ColaboradorHC')
    )
RETURN
    _Total - _Match
"@ "#,0" "08 Headcount HC"
    Set-Measure $m "Asistencia Porcentaje HC Match" @"
VAR _Total =
    CALCULATE(
        [Asistencia Total Registros],
        REMOVEFILTERS('Dim_ColaboradorHC')
    )
VAR _Match =
    CALCULATE(
        [Asistencia Registros HC Match],
        REMOVEFILTERS('Dim_ColaboradorHC')
    )
RETURN
    DIVIDE(_Match, _Total)
"@ "0.0%;-0.0%;0.0%" "08 Headcount HC"

    Set-Measure $m "Encuesta Total Respuestas" "COUNTROWS('Fct_EncuestaFormacion')" "#,0" "03 Encuesta Formacion"
    Set-Measure $m "Encuesta Participantes Estimados" "[Encuesta Total Respuestas]" "#,0" "03 Encuesta Formacion"
    Set-Measure $m "Encuesta Tasa Respuesta" "DIVIDE([Encuesta Total Respuestas], [Asistencia Total Asistentes])" "0.0%;-0.0%;0.0%" "03 Encuesta Formacion"
    Set-Measure $m "Encuesta Calificacion Satisfaccion Formacion" "AVERAGE('Fct_EncuestaFormacion'[En general, ¿Qué tan satisfecho te encuentras con la formación recibida?])" "0.00" "03 Encuesta Formacion"
    Set-Measure $m "Encuesta Calificacion Promedio" @"
VAR _Suma =
    SUM('Fct_EncuestaFormacion'[¿Qué tan satisfecho te encuentras con el dominio del tema por parte del facilitador?]) +
    SUM('Fct_EncuestaFormacion'[¿Qué tan satisfecho te encuentras con la habilidad para comunicarse y transmitir ideas por parte del facilitador?]) +
    SUM('Fct_EncuestaFormacion'[¿Qué tan satisfecho te encuentras con las actividades o ejercicios por parte del facilitador?]) +
    SUM('Fct_EncuestaFormacion'[¿Qué tan satisfecho te encuentras con el uso de ayudas didácticas por parte del facilitador?]) +
    SUM('Fct_EncuestaFormacion'[¿Qué tan satisfecho te encuentras con la resolución de dudas u observaciones del facilitador?]) +
    SUM('Fct_EncuestaFormacion'[¿Qué tan satisfecho te encuentras con el cumplimiento del programa propuesto?]) +
    SUM('Fct_EncuestaFormacion'[¿Qué tan satisfecho te encuentras con el espacio, logística y ambiente de la formación?]) +
    SUM('Fct_EncuestaFormacion'[¿Qué tan oportuna fue la información respecto a fechas, horarios y lugar?]) +
    SUM('Fct_EncuestaFormacion'[¿Qué tan satisfecho te encuentras con el logro de los objetivos propuestos?]) +
    SUM('Fct_EncuestaFormacion'[¿Qué tan satisfecho te encuentras con la contribución del programa para tu desarrollo personal y/o profesional?]) +
    SUM('Fct_EncuestaFormacion'[¿Qué tan satisfecho te encuentras con el acompañamiento de la Universidad Challenger en tu desarrollo personal y/o profesional?]) +
    SUM('Fct_EncuestaFormacion'[En general, ¿Qué tan satisfecho te encuentras con la formación recibida?])
VAR _Conteo =
    COUNT('Fct_EncuestaFormacion'[¿Qué tan satisfecho te encuentras con el dominio del tema por parte del facilitador?]) +
    COUNT('Fct_EncuestaFormacion'[¿Qué tan satisfecho te encuentras con la habilidad para comunicarse y transmitir ideas por parte del facilitador?]) +
    COUNT('Fct_EncuestaFormacion'[¿Qué tan satisfecho te encuentras con las actividades o ejercicios por parte del facilitador?]) +
    COUNT('Fct_EncuestaFormacion'[¿Qué tan satisfecho te encuentras con el uso de ayudas didácticas por parte del facilitador?]) +
    COUNT('Fct_EncuestaFormacion'[¿Qué tan satisfecho te encuentras con la resolución de dudas u observaciones del facilitador?]) +
    COUNT('Fct_EncuestaFormacion'[¿Qué tan satisfecho te encuentras con el cumplimiento del programa propuesto?]) +
    COUNT('Fct_EncuestaFormacion'[¿Qué tan satisfecho te encuentras con el espacio, logística y ambiente de la formación?]) +
    COUNT('Fct_EncuestaFormacion'[¿Qué tan oportuna fue la información respecto a fechas, horarios y lugar?]) +
    COUNT('Fct_EncuestaFormacion'[¿Qué tan satisfecho te encuentras con el logro de los objetivos propuestos?]) +
    COUNT('Fct_EncuestaFormacion'[¿Qué tan satisfecho te encuentras con la contribución del programa para tu desarrollo personal y/o profesional?]) +
    COUNT('Fct_EncuestaFormacion'[¿Qué tan satisfecho te encuentras con el acompañamiento de la Universidad Challenger en tu desarrollo personal y/o profesional?]) +
    COUNT('Fct_EncuestaFormacion'[En general, ¿Qué tan satisfecho te encuentras con la formación recibida?])
RETURN
    DIVIDE(_Suma, _Conteo)
"@ "0.00" "03 Encuesta Formacion"
    Set-Measure $m "Encuesta Favorabilidad" "DIVIDE(CALCULATE(COUNTROWS('Fct_EncuestaFormacion'), 'Fct_EncuestaFormacion'[En general, ¿Qué tan satisfecho te encuentras con la formación recibida?] >= 4), [Encuesta Total Respuestas])" "0.0%;-0.0%;0.0%" "03 Encuesta Formacion"
    Set-Measure $m "Encuesta NPS Equivalente" @"
VAR _Total = COUNT('Fct_EncuestaFormacion'[En general, ¿Qué tan satisfecho te encuentras con la formación recibida?])
VAR _Promotores = CALCULATE(COUNTROWS('Fct_EncuestaFormacion'), 'Fct_EncuestaFormacion'[En general, ¿Qué tan satisfecho te encuentras con la formación recibida?] >= 5)
VAR _Detractores = CALCULATE(COUNTROWS('Fct_EncuestaFormacion'), 'Fct_EncuestaFormacion'[En general, ¿Qué tan satisfecho te encuentras con la formación recibida?] <= 3)
RETURN
    DIVIDE(_Promotores - _Detractores, _Total) * 100
"@ "0.0" "03 Encuesta Formacion"

    Set-Measure $m "Induccion Total Colaboradores" "COUNTROWS('Fct_Induccion')" "#,0" "04 Induccion UC"
    Set-Measure $m "Induccion Colaboradores Unicos" "DISTINCTCOUNT('Fct_Induccion'[Colaborador_Key])" "#,0" "04 Induccion UC"
    Set-Measure $m "Induccion Aprobados" "CALCULATE(COUNTROWS('Fct_Induccion'), 'Fct_Induccion'[EstadoInduccion_Key] IN { ""APROBO"", ""APROBADO"" })" "#,0" "04 Induccion UC"
    Set-Measure $m "Induccion No Aprobados" "CALCULATE(COUNTROWS('Fct_Induccion'), 'Fct_Induccion'[EstadoInduccion_Key] = ""NO_APROBO"")" "#,0" "04 Induccion UC"
    Set-Measure $m "Induccion Retiros" "CALCULATE(COUNTROWS('Fct_Induccion'), 'Fct_Induccion'[EstadoInduccion_Key] IN { ""RETIRADO"", ""RENUNCIA"" })" "#,0" "04 Induccion UC"
    Set-Measure $m "Induccion Onboarding Realizados" "CALCULATE(COUNTROWS('Fct_Induccion'), 'Fct_Induccion'[EstadoInduccion_Key] IN { ""APROBO"", ""APROBADO"" })" "#,0" "04 Induccion UC"
    Set-Measure $m "Induccion Onboarding Participantes" "CALCULATE(DISTINCTCOUNT('Fct_Induccion'[Colaborador_Key]), 'Fct_Induccion'[EstadoInduccion_Key] <> ""RENUNCIA"")" "#,0" "04 Induccion UC"
    Set-Measure $m "Induccion Onboarding" "DIVIDE([Induccion Onboarding Realizados], [Induccion Onboarding Participantes], 0)" "0.0%;-0.0%;0.0%" "04 Induccion UC"
    Set-Measure $m "Induccion Minutos Entrenamiento" "SUM('Fct_Induccion'[Min_Entrenamiento])" "#,0" "04 Induccion UC"
    Set-Measure $m "Induccion Horas Entrenamiento" "DIVIDE([Induccion Minutos Entrenamiento], 60)" "#,0.0" "04 Induccion UC"
    Set-Measure $m "Induccion Entrenamiento Realizados" "CALCULATE(COUNTROWS('Fct_Induccion'), 'Fct_Induccion'[Entrenamiento] = ""SI"")" "#,0" "04 Induccion UC"
    Set-Measure $m "Induccion Entrenamiento Base" "CALCULATE(COUNTROWS('Fct_Induccion'), 'Fct_Induccion'[Entrenamiento] = ""SI"" || 'Fct_Induccion'[Entrenamiento] = ""PENDIENTE"" || ISBLANK('Fct_Induccion'[Entrenamiento]))" "#,0" "04 Induccion UC"
    Set-Measure $m "Induccion Porcentaje Entrenamiento" "DIVIDE([Induccion Entrenamiento Realizados], [Induccion Entrenamiento Base], 0)" "0.0%;-0.0%;0.0%" "04 Induccion UC"
    Set-Measure $m "Induccion Porcentaje Cumplimiento" "DIVIDE([Induccion Aprobados], [Induccion Total Colaboradores])" "0.0%;-0.0%;0.0%" "04 Induccion UC"
    Set-Measure $m "Induccion Tiempo Promedio Finalizacion Dias" "AVERAGE('Fct_Induccion'[Tiempo_Finalizacion_Dias])" "#,0.0" "04 Induccion UC"
    Set-Measure $m "Induccion Cumplimiento Antes UC" "CALCULATE([Induccion Porcentaje Cumplimiento], 'Dim_SegmentoUC'[SegmentoUC_Key] = ""Antes_UC"")" "0.0%;-0.0%;0.0%" "04 Induccion UC"
    Set-Measure $m "Induccion Cumplimiento UC 2025" "CALCULATE([Induccion Porcentaje Cumplimiento], 'Dim_SegmentoUC'[SegmentoUC_Key] = ""UC_2025"")" "0.0%;-0.0%;0.0%" "04 Induccion UC"
    Set-Measure $m "Induccion Cumplimiento UC 2026" "CALCULATE([Induccion Porcentaje Cumplimiento], 'Dim_SegmentoUC'[SegmentoUC_Key] = ""UC_2026"")" "0.0%;-0.0%;0.0%" "04 Induccion UC"
    Set-Measure $m "Induccion Variacion UC2025 vs Antes UC" "[Induccion Cumplimiento UC 2025] - [Induccion Cumplimiento Antes UC]" "0.0 pp;-0.0 pp;0.0 pp" "04 Induccion UC"
    Set-Measure $m "Induccion Variacion UC2026 vs UC2025" "[Induccion Cumplimiento UC 2026] - [Induccion Cumplimiento UC 2025]" "0.0 pp;-0.0 pp;0.0 pp" "04 Induccion UC"

    Set-Measure $m "KPI Indice Aprendizaje" @"
VAR _Base =
    {
        [Plan Porcentaje Ejecucion],
        [Plan Cobertura Asistencia],
        [Encuesta Favorabilidad],
        [Induccion Porcentaje Cumplimiento]
    }
RETURN
    AVERAGEX(FILTER(_Base, NOT ISBLANK([Value])), [Value])
"@ "0.0%;-0.0%;0.0%" "00 KPIs Gerenciales"
    Set-Measure $m "KPI Actividades Totales Gestionadas" "[Plan Actividades Planificadas] + [Asistencia Total Registros] + [Encuesta Total Respuestas] + [Induccion Total Colaboradores]" "#,0" "00 KPIs Gerenciales"
    Set-Measure $m "Ranking Area Cumplimiento Plan" "RANKX(ALLSELECTED('Dim_Area'[Area]), [Plan Porcentaje Ejecucion], , DESC, Dense)" "#,0" "05 Rankings y Alertas"
    Set-Measure $m "Ranking Area Cumplimiento Induccion" "RANKX(ALLSELECTED('Dim_Area'[Area]), [Induccion Porcentaje Cumplimiento], , DESC, Dense)" "#,0" "05 Rankings y Alertas"
    Set-Measure $m "Ranking Empresa Asistencia" "RANKX(ALLSELECTED('Dim_Empresa'[Empresa]), [Asistencia Total Asistentes], , DESC, Dense)" "#,0" "05 Rankings y Alertas"
    Set-Measure $m "Alerta Plan Bajo Cumplimiento" "IF(NOT ISBLANK([Plan Porcentaje Ejecucion]) && [Plan Porcentaje Ejecucion] < 0.8, 1, 0)" "#,0" "05 Rankings y Alertas"
    Set-Measure $m "Alerta Induccion Bajo Cumplimiento" "IF(NOT ISBLANK([Induccion Porcentaje Cumplimiento]) && [Induccion Porcentaje Cumplimiento] < 0.9, 1, 0)" "#,0" "05 Rankings y Alertas"
    Set-Measure $m "Hallazgo Plan" @"
""Plan: "" & FORMAT([Plan Porcentaje Ejecucion], ""0.0%"") &
"" de ejecucion; brecha de "" & FORMAT([Plan Brecha Actividades], ""#,0"") & "" actividades.""
"@ "" "06 Hallazgos"
    Set-Measure $m "Hallazgo Asistencia" @"
""Asistencia: "" & FORMAT([Asistencia Total Asistentes], ""#,0"") &
"" registros y "" & FORMAT([% Cobertura], ""0.0%"") & "" de cobertura registrada en el plan.""
"@ "" "06 Hallazgos"
    Set-Measure $m "Hallazgo UC" @"
""UC: Antes "" & FORMAT([Induccion Cumplimiento Antes UC], ""0.0%"") &
"", UC 2025 "" & FORMAT([Induccion Cumplimiento UC 2025], ""0.0%"") &
"", UC 2026 "" & FORMAT([Induccion Cumplimiento UC 2026], ""0.0%"") & "".""
"@ "" "06 Hallazgos"
    Set-Measure $m "Plan Eficacia Promedio" "DIVIDE(AVERAGE('Fct_PlanFormacion'[EFICACIA]), 100)" "0.0%;-0.0%;0.0%" "01 Plan Formacion"
    Set-Measure $m "Plan Actividades Pendientes" "[Plan Actividades Vigentes] - [Plan Actividades Ejecutadas]" "#,0" "01 Plan Formacion"
    Set-Measure $m "Plan Variacion Ejecutadas MoM" "[Plan Actividades Ejecutadas] - CALCULATE([Plan Actividades Ejecutadas], DATEADD('Dim_Calendario'[Date], -1, MONTH))" "#,0" "07 Comparativos"
    Set-Measure $m "Plan Variacion Ejecutadas MoM %" "DIVIDE([Plan Variacion Ejecutadas MoM], CALCULATE([Plan Actividades Ejecutadas], DATEADD('Dim_Calendario'[Date], -1, MONTH)))" "0.0%;-0.0%;0.0%" "07 Comparativos"
    Set-Measure $m "Plan Variacion Ejecutadas YoY" "[Plan Actividades Ejecutadas] - CALCULATE([Plan Actividades Ejecutadas], SAMEPERIODLASTYEAR('Dim_Calendario'[Date]))" "#,0" "07 Comparativos"
    Set-Measure $m "Plan Variacion Ejecutadas YoY %" "DIVIDE([Plan Variacion Ejecutadas YoY], CALCULATE([Plan Actividades Ejecutadas], SAMEPERIODLASTYEAR('Dim_Calendario'[Date])))" "0.0%;-0.0%;0.0%" "07 Comparativos"
    Set-Measure $m "Asistencia Variacion MoM" "[Asistencia Total Asistentes] - CALCULATE([Asistencia Total Asistentes], DATEADD('Dim_Calendario'[Date], -1, MONTH))" "#,0" "07 Comparativos"
    Set-Measure $m "Asistencia Variacion MoM %" "DIVIDE([Asistencia Variacion MoM], CALCULATE([Asistencia Total Asistentes], DATEADD('Dim_Calendario'[Date], -1, MONTH)))" "0.0%;-0.0%;0.0%" "07 Comparativos"
    Set-Measure $m "Asistencia Variacion YoY" "[Asistencia Total Asistentes] - CALCULATE([Asistencia Total Asistentes], SAMEPERIODLASTYEAR('Dim_Calendario'[Date]))" "#,0" "07 Comparativos"
    Set-Measure $m "Asistencia Variacion YoY %" "DIVIDE([Asistencia Variacion YoY], CALCULATE([Asistencia Total Asistentes], SAMEPERIODLASTYEAR('Dim_Calendario'[Date])))" "0.0%;-0.0%;0.0%" "07 Comparativos"
    Set-Measure $m "Encuesta Favorabilidad Variacion MoM" "[Encuesta Favorabilidad] - CALCULATE([Encuesta Favorabilidad], DATEADD('Dim_Calendario'[Date], -1, MONTH))" "0.0%;-0.0%;0.0%" "07 Comparativos"
    Set-Measure $m "Encuesta Favorabilidad Variacion YoY" "[Encuesta Favorabilidad] - CALCULATE([Encuesta Favorabilidad], SAMEPERIODLASTYEAR('Dim_Calendario'[Date]))" "0.0%;-0.0%;0.0%" "07 Comparativos"
    Set-Measure $m "Induccion Variacion Colaboradores MoM" "[Induccion Total Colaboradores] - CALCULATE([Induccion Total Colaboradores], DATEADD('Dim_Calendario'[Date], -1, MONTH))" "#,0" "07 Comparativos"
    Set-Measure $m "Induccion Variacion Colaboradores MoM %" "DIVIDE([Induccion Variacion Colaboradores MoM], CALCULATE([Induccion Total Colaboradores], DATEADD('Dim_Calendario'[Date], -1, MONTH)))" "0.0%;-0.0%;0.0%" "07 Comparativos"
    Set-Measure $m "Induccion Variacion Cumplimiento MoM" "[Induccion Porcentaje Cumplimiento] - CALCULATE([Induccion Porcentaje Cumplimiento], DATEADD('Dim_Calendario'[Date], -1, MONTH))" "0.0 pp;-0.0 pp;0.0 pp" "07 Comparativos"
    Set-Measure $m "KPI Frente Pendiente" "BLANK()" "0.0%;-0.0%;0.0%" "00 KPIs Gerenciales"
    Set-Measure $m "KPI Nivel Cargo Pendiente" "BLANK()" "0.0%;-0.0%;0.0%" "00 KPIs Gerenciales"

    $model.RequestRefresh([Microsoft.AnalysisServices.Tabular.RefreshType]::Calculate)
    $model.SaveChanges()
    $server.Disconnect()
}

function New-MeasureProjection {
    param([string]$Measure)
    return [ordered]@{
        field = [ordered]@{
            Measure = [ordered]@{
                Expression = [ordered]@{ SourceRef = [ordered]@{ Entity = "Medidas_AD" } }
                Property = $Measure
            }
        }
        queryRef = "Medidas_AD.$Measure"
        nativeQueryRef = $Measure
    }
}

function New-ColumnProjection {
    param([string]$Entity, [string]$Column, [bool]$Active = $true)
    $projection = [ordered]@{
        field = [ordered]@{
            Column = [ordered]@{
                Expression = [ordered]@{ SourceRef = [ordered]@{ Entity = $Entity } }
                Property = $Column
            }
        }
        queryRef = "$Entity.$Column"
        nativeQueryRef = $Column
    }
    if ($Active) {
        $projection.active = $true
    }
    return $projection
}

function New-TitleObject {
    param([string]$Title)
    return [ordered]@{
        title = @(
            [ordered]@{
                properties = [ordered]@{
                    show = [ordered]@{ expr = [ordered]@{ Literal = [ordered]@{ Value = "true" } } }
                    text = [ordered]@{ expr = [ordered]@{ Literal = [ordered]@{ Value = "'$Title'" } } }
                }
            }
        )
        visualHeader = @(
            [ordered]@{
                properties = [ordered]@{
                    show = [ordered]@{ expr = [ordered]@{ Literal = [ordered]@{ Value = "true" } } }
                }
            }
        )
        visualTooltip = @(
            [ordered]@{
                properties = [ordered]@{
                    show = [ordered]@{ expr = [ordered]@{ Literal = [ordered]@{ Value = "true" } } }
                }
            }
        )
    }
}

function ConvertTo-PbirId {
    param([string]$Value)
    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
        $hash = $sha1.ComputeHash($bytes)
        return (($hash | ForEach-Object { $_.ToString("x2") }) -join "").Substring(0, 20)
    }
    finally {
        $sha1.Dispose()
    }
}

function New-Visual {
    param(
        [string]$Name,
        [string]$Type,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [int]$Z,
        [string]$Title,
        [array]$Measures,
        [string]$CategoryEntity = "",
        [string]$CategoryColumn = "",
        [array]$TableColumns = @()
    )

    $queryState = [ordered]@{}
    if ($Type -eq "card") {
        $queryState.Values = [ordered]@{ projections = @((New-MeasureProjection $Measures[0])) }
    }
    elseif ($Type -eq "slicer") {
        if ($CategoryEntity -eq "" -or $CategoryColumn -eq "") {
            throw "Los slicers requieren CategoryEntity y CategoryColumn."
        }
        $queryState.Values = [ordered]@{ projections = @((New-ColumnProjection $CategoryEntity $CategoryColumn)) }
    }
    elseif ($Type -eq "tableEx") {
        $projections = @()
        foreach ($col in $TableColumns) {
            $projections += New-ColumnProjection $col.Entity $col.Column $false
        }
        foreach ($measure in $Measures) {
            $projections += New-MeasureProjection $measure
        }
        $queryState.Values = [ordered]@{ projections = $projections }
    }
    else {
        $queryState.Category = [ordered]@{ projections = @((New-ColumnProjection $CategoryEntity $CategoryColumn)) }
        if ($Measures -and $Measures.Count -gt 0) {
            $queryState.Y = [ordered]@{ projections = @($Measures | ForEach-Object { New-MeasureProjection $_ }) }
        }
    }

    $visualId = ConvertTo-PbirId $Name
    $visual = [ordered]@{
        '$schema' = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.4.0/schema.json"
        name = $visualId
        position = [ordered]@{
            x = $X
            y = $Y
            z = $Z
            height = $Height
            width = $Width
            tabOrder = $Z
        }
        visual = [ordered]@{
            visualType = $Type
            query = [ordered]@{ queryState = $queryState }
            drillFilterOtherVisuals = $true
        }
    }

    if ($Type -eq "card" -and $Name -like "home_apr_*") {
        $visual.visual.objects = [ordered]@{
            labels = @(
                [ordered]@{
                    properties = [ordered]@{
                        fontSize = [ordered]@{ expr = [ordered]@{ Literal = [ordered]@{ Value = "16D" } } }
                    }
                }
            )
            categoryLabels = @(
                [ordered]@{
                    properties = [ordered]@{
                        show = [ordered]@{ expr = [ordered]@{ Literal = [ordered]@{ Value = "false" } } }
                    }
                }
            )
        }
    }
    elseif ($Type -ne "card") {
        if ($Type -eq "slicer") {
            $visual.visual.objects = [ordered]@{
                data = @([ordered]@{ properties = [ordered]@{ mode = [ordered]@{ expr = [ordered]@{ Literal = [ordered]@{ Value = "'Dropdown'" } } } } })
                selection = @([ordered]@{ properties = [ordered]@{ singleSelect = [ordered]@{ expr = [ordered]@{ Literal = [ordered]@{ Value = "false" } } } } })
                header = @([ordered]@{ properties = [ordered]@{ show = [ordered]@{ expr = [ordered]@{ Literal = [ordered]@{ Value = "false" } } } } })
                slicerHeader = @([ordered]@{ properties = [ordered]@{ show = [ordered]@{ expr = [ordered]@{ Literal = [ordered]@{ Value = "false" } } } } })
            }
        }
        else {
            $visual.visual.objects = [ordered]@{
                labels = @([ordered]@{ properties = [ordered]@{ show = [ordered]@{ expr = [ordered]@{ Literal = [ordered]@{ Value = "true" } } } } })
                categoryAxis = @([ordered]@{ properties = [ordered]@{ showAxisTitle = [ordered]@{ expr = [ordered]@{ Literal = [ordered]@{ Value = "false" } } } } })
                valueAxis = @([ordered]@{ properties = [ordered]@{ showAxisTitle = [ordered]@{ expr = [ordered]@{ Literal = [ordered]@{ Value = "false" } } } } })
                legend = @([ordered]@{ properties = [ordered]@{ showTitle = [ordered]@{ expr = [ordered]@{ Literal = [ordered]@{ Value = "false" } } } } })
            }
        }
    }
    $visual.visual.visualContainerObjects = New-TitleObject $Title
    if ($Type -eq "card" -and $Name -like "home_apr_*") {
        $visual.visual.visualContainerObjects.title[0].properties.fontSize = [ordered]@{ expr = [ordered]@{ Literal = [ordered]@{ Value = "12D" } } }
    }
    return $visual
}

function New-TextBox {
    param(
        [string]$Name,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [int]$Z,
        [string]$Text,
        [string]$FontSize = "22pt",
        [string]$Color = "#0B1C35",
        [bool]$Bold = $true
    )

    $textStyle = [ordered]@{
        fontSize = $FontSize
        color = $Color
        fontFamily = "Outfit"
    }
    if ($Bold) {
        $textStyle.fontWeight = "bold"
    }

    return [ordered]@{
        '$schema' = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.4.0/schema.json"
        name = ConvertTo-PbirId $Name
        position = [ordered]@{
            x = $X
            y = $Y
            z = $Z
            height = $Height
            width = $Width
            tabOrder = $Z
        }
        visual = [ordered]@{
            visualType = "textbox"
            drillFilterOtherVisuals = $true
            objects = [ordered]@{
                general = @(
                    [ordered]@{
                        properties = [ordered]@{
                            paragraphs = @(
                                [ordered]@{
                                    textRuns = @(
                                        [ordered]@{
                                            value = $Text
                                            textStyle = $textStyle
                                        }
                                    )
                                    horizontalTextAlignment = "left"
                                }
                            )
                        }
                    }
                )
            }
        }
    }
}

function Write-JsonFile {
    param([string]$Path, $Object)
    $json = $Object | ConvertTo-Json -Depth 100
    [System.IO.File]::WriteAllText($Path, $json, (New-Object System.Text.UTF8Encoding($false)))
}

function New-ReportPage {
    param([string]$Name, [string]$DisplayName, [array]$Visuals)

    $pageDir = Join-Path $PagesRoot $Name
    $visualsDir = Join-Path $pageDir "visuals"
    New-Item -ItemType Directory -Force -Path $visualsDir | Out-Null

    Write-JsonFile (Join-Path $pageDir "page.json") ([ordered]@{
        '$schema' = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/page/2.0.0/schema.json"
        name = $Name
        displayName = $DisplayName
        displayOption = "FitToPage"
        height = 720
        width = 1280
    })

    foreach ($visual in $Visuals) {
        $dir = Join-Path $visualsDir $visual.name
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        Write-JsonFile (Join-Path $dir "visual.json") $visual
    }
}

function Set-ReportLayer {
    $pages = @(
        [ordered]@{
            Name = "ad1e0000000000000000"
            Display = "00 Inicio Corporativo"
            Visuals = @(
                (New-TextBox "home_titulo_corporativo" 32 4 760 30 100 "Dashboard Corporativo de Desarrollo Organizacional" "18pt" "#0B1C35" $true),
                (New-TextBox "home_subtitulo_corporativo" 872 8 376 24 101 "Mapa de frentes | Aprendizaje activo" "12pt" "#F7931E" $true),
                (New-Visual "home_filtro_anio" "slicer" 32 42 118 46 10 "Anio" @() "Dim_Calendario" "Anio"),
                (New-Visual "home_filtro_mes" "slicer" 158 42 132 46 11 "Mes" @() "Dim_Calendario" "AnioMes"),
                (New-Visual "home_filtro_empresa" "slicer" 300 42 170 46 12 "Empresa" @() "Dim_Empresa" "Empresa"),
                (New-Visual "home_filtro_area" "slicer" 480 42 170 46 13 "Area" @() "Dim_Area" "Area"),
                (New-Visual "home_filtro_tipo" "slicer" 660 42 170 46 14 "Tipo formacion" @() "Dim_TipoFormacion" "TipoFormacion"),
                (New-Visual "home_filtro_modalidad" "slicer" 840 42 170 46 15 "Modalidad" @() "Dim_Modalidad" "Modalidad"),
                (New-Visual "home_filtro_segmento" "slicer" 1020 42 228 46 16 "Segmento UC" @() "Dim_SegmentoUC" "SegmentoUC"),

                (New-TextBox "home_titulo_aprendizaje" 32 96 590 24 200 "Aprendizaje" "17pt" "#1B487F" $true),
                (New-Visual "home_apr_horas" "card" 32 124 136 58 1000 "Horas Formacion" @("Plan Horas Formacion")),
                (New-Visual "home_apr_cobertura" "card" 178 124 136 58 1001 "Cobertura" @("% Cobertura")),
                (New-Visual "home_apr_satisfaccion" "card" 324 124 136 58 1002 "Satisfaccion" @("Encuesta Favorabilidad")),
                (New-Visual "home_apr_eficacia" "card" 470 124 152 58 1003 "Eficacia" @("Plan Eficacia Promedio")),
                (New-Visual "home_apr_tipo_cargo" "barChart" 32 188 136 58 1004 "Tipo de Cargo" @("HC Porcentaje Tipo Cargo") "Dim_ColaboradorHC" "Tipo_Cargo"),
                (New-Visual "home_apr_onboarding" "card" 178 188 136 58 1005 "Onboarding" @("Induccion Onboarding")),
                (New-Visual "home_apr_entrenamiento" "card" 324 188 136 58 1006 "Entrenamiento %" @("Induccion Porcentaje Entrenamiento")),
                (New-Visual "home_apr_indice" "card" 470 188 152 58 1007 "Indice aprendizaje" @("KPI Indice Aprendizaje")),
                (New-Visual "home_apr_tipo_formacion" "barChart" 32 258 590 92 2000 "Tipo de Formacion" @("Plan Actividades Ejecutadas") "Dim_TipoFormacion" "TipoFormacion"),

                (New-TextBox "home_titulo_desempeno" 658 96 590 24 300 "Desempeno" "17pt" "#1B487F" $true),
                (New-TextBox "home_desempeno_1" 658 140 270 32 1100 "Cobertura evaluacion" "14pt" "#1A3059" $true),
                (New-TextBox "home_desempeno_2" 958 140 270 32 1101 "Resultado promedio" "14pt" "#1A3059" $true),
                (New-TextBox "home_desempeno_3" 658 198 270 32 1102 "Competencias" "14pt" "#1A3059" $true),
                (New-TextBox "home_desempeno_4" 958 198 270 32 1103 "Planes de mejora" "14pt" "#1A3059" $true),
                (New-TextBox "home_desempeno_estado" 658 270 590 36 1104 "Proxima fase" "17pt" "#F7931E" $true),

                (New-TextBox "home_titulo_desarrollo" 32 386 590 28 400 "Desarrollo" "18pt" "#1B487F" $true),
                (New-TextBox "home_desarrollo_1" 32 438 270 36 1200 "Movilidad interna" "15pt" "#1A3059" $true),
                (New-TextBox "home_desarrollo_2" 332 438 270 36 1201 "Sucesion" "15pt" "#1A3059" $true),
                (New-TextBox "home_desarrollo_3" 32 504 270 36 1202 "Cargos criticos" "15pt" "#1A3059" $true),
                (New-TextBox "home_desarrollo_4" 332 504 270 36 1203 "Plan carrera" "15pt" "#1A3059" $true),
                (New-TextBox "home_desarrollo_estado" 32 592 590 42 1204 "Proxima fase" "18pt" "#F7931E" $true),

                (New-TextBox "home_titulo_bienestar" 658 386 590 28 500 "Bienestar y Clima" "18pt" "#1B487F" $true),
                (New-TextBox "home_bienestar_1" 658 438 270 36 1300 "Encuesta clima" "15pt" "#1A3059" $true),
                (New-TextBox "home_bienestar_2" 958 438 270 36 1301 "Bienestar" "15pt" "#1A3059" $true),
                (New-TextBox "home_bienestar_3" 658 504 270 36 1302 "Retiros" "15pt" "#1A3059" $true),
                (New-TextBox "home_bienestar_4" 958 504 270 36 1303 "Alertas" "15pt" "#1A3059" $true),
                (New-TextBox "home_bienestar_estado" 658 592 590 42 1304 "Proxima fase" "18pt" "#F7931E" $true)
            )
        },
        [ordered]@{
            Name = "ad1e0100000000000001"
            Display = "01 Resumen Ejecutivo Aprendizaje"
            Visuals = @(
                (New-Visual "res_filtro_anio" "slicer" 32 18 176 60 10 "Anio" @() "Dim_Calendario" "Anio"),
                (New-Visual "res_filtro_mes" "slicer" 220 18 176 60 11 "Mes" @() "Dim_Calendario" "AnioMes"),
                (New-Visual "res_filtro_empresa" "slicer" 408 18 188 60 12 "Empresa" @() "Dim_Empresa" "Empresa"),
                (New-Visual "res_filtro_area" "slicer" 608 18 188 60 13 "Area" @() "Dim_Area" "Area"),
                (New-Visual "res_filtro_tipo" "slicer" 808 18 188 60 14 "Tipo formacion" @() "Dim_TipoFormacion" "TipoFormacion"),
                (New-Visual "res_filtro_segmento" "slicer" 1008 18 240 60 15 "Segmento UC" @() "Dim_SegmentoUC" "SegmentoUC"),
                (New-Visual "res_kpi_indice" "card" 32 98 188 82 1000 "Indice aprendizaje" @("KPI Indice Aprendizaje")),
                (New-Visual "res_kpi_plan" "card" 236 98 188 82 1001 "Ejecucion plan" @("Plan Porcentaje Ejecucion")),
                (New-Visual "res_kpi_cobertura" "card" 440 98 188 82 1002 "% Cobertura" @("% Cobertura")),
                (New-Visual "res_kpi_horas" "card" 644 98 188 82 1003 "Horas de formacion" @("Plan Horas Formacion")),
                (New-Visual "res_kpi_satisfaccion" "card" 848 98 188 82 1004 "Satisfaccion" @("Encuesta Favorabilidad")),
                (New-Visual "res_kpi_induccion" "card" 1052 98 196 82 1005 "Cumplimiento induccion" @("Induccion Porcentaje Cumplimiento")),
                (New-Visual "res_tendencia" "lineChart" 32 208 724 214 2000 "Tendencia mensual de gestion" @("Plan Actividades Ejecutadas", "Asistencia Total Asistentes", "Encuesta Total Respuestas", "Induccion Total Colaboradores") "Dim_Calendario" "AnioMes"),
                (New-Visual "res_segmento_uc" "barChart" 784 208 464 214 2001 "Cumplimiento por segmento UC" @("Induccion Porcentaje Cumplimiento") "Dim_SegmentoUC" "SegmentoUC"),
                (New-Visual "res_variaciones" "tableEx" 32 452 590 218 3000 "Variaciones ejecutivas por mes" @("Plan Variacion Ejecutadas MoM", "Asistencia Variacion MoM", "Encuesta Favorabilidad Variacion MoM", "Induccion Variacion Colaboradores MoM") "" "" @(@{ Entity = "Dim_Calendario"; Column = "AnioMes" })),
                (New-Visual "res_tipo_formacion" "barChart" 658 452 590 218 3001 "Mix de ejecucion por tipo" @("Plan Actividades Ejecutadas") "Dim_TipoFormacion" "TipoFormacion")
            )
        },
        [ordered]@{
            Name = "ad1e0200000000000002"
            Display = "02 Plan y Ejecucion"
            Visuals = @(
                (New-Visual "plan_filtro_anio" "slicer" 32 18 176 60 10 "Anio" @() "Dim_Calendario" "Anio"),
                (New-Visual "plan_filtro_mes" "slicer" 220 18 176 60 11 "Mes" @() "Dim_Calendario" "AnioMes"),
                (New-Visual "plan_filtro_area" "slicer" 408 18 188 60 12 "Area" @() "Dim_Area" "Area"),
                (New-Visual "plan_filtro_tipo" "slicer" 608 18 188 60 13 "Tipo formacion" @() "Dim_TipoFormacion" "TipoFormacion"),
                (New-Visual "plan_filtro_modalidad" "slicer" 808 18 188 60 14 "Modalidad" @() "Dim_Modalidad" "Modalidad"),
                (New-Visual "plan_filtro_estado" "slicer" 1008 18 240 60 15 "Estado" @() "Dim_EstadoFormacion" "EstadoFormacion"),
                (New-Visual "plan_kpi_planificadas" "card" 32 98 190 82 1000 "Planificadas" @("Plan Actividades Planificadas")),
                (New-Visual "plan_kpi_ejecutadas" "card" 238 98 190 82 1001 "Ejecutadas" @("Plan Actividades Ejecutadas")),
                (New-Visual "plan_kpi_pendientes" "card" 444 98 190 82 1002 "Pendientes" @("Plan Actividades Pendientes")),
                (New-Visual "plan_kpi_horas" "card" 650 98 190 82 1003 "Horas formacion" @("Plan Horas Formacion")),
                (New-Visual "plan_kpi_total_horas" "card" 856 98 190 82 1004 "Total horas" @("Plan Total Horas Formacion")),
                (New-Visual "plan_kpi_eficacia" "card" 1062 98 186 82 1005 "Eficacia promedio" @("Plan Eficacia Promedio")),
                (New-Visual "plan_mes" "lineChart" 32 208 760 214 2000 "Plan vs ejecucion mensual" @("Plan Actividades Planificadas", "Plan Actividades Ejecutadas") "Dim_Calendario" "AnioMes"),
                (New-Visual "plan_area" "barChart" 820 208 428 214 2001 "Cumplimiento por area" @("Plan Porcentaje Ejecucion") "Dim_Area" "Area"),
                (New-Visual "plan_tipo" "barChart" 32 452 390 218 3000 "Ejecucion por tipo" @("Plan Actividades Ejecutadas") "Dim_TipoFormacion" "TipoFormacion"),
                (New-Visual "plan_estado" "barChart" 452 452 390 218 3001 "Estado del plan" @("Plan Actividades Planificadas") "Dim_EstadoFormacion" "EstadoFormacion"),
                (New-Visual "plan_variaciones" "tableEx" 872 452 376 218 3002 "Variacion mensual y anual" @("Plan Variacion Ejecutadas MoM", "Plan Variacion Ejecutadas MoM %", "Plan Variacion Ejecutadas YoY", "Plan Variacion Ejecutadas YoY %") "" "" @(@{ Entity = "Dim_Calendario"; Column = "AnioMes" }))
            )
        },
        [ordered]@{
            Name = "ad1e0300000000000003"
            Display = "03 Cobertura y Participacion"
            Visuals = @(
                (New-Visual "cob_filtro_anio" "slicer" 32 18 176 60 10 "Anio" @() "Dim_Calendario" "Anio"),
                (New-Visual "cob_filtro_mes" "slicer" 220 18 176 60 11 "Mes" @() "Dim_Calendario" "AnioMes"),
                (New-Visual "cob_filtro_empresa" "slicer" 408 18 188 60 12 "Empresa" @() "Dim_Empresa" "Empresa"),
                (New-Visual "cob_filtro_tema" "slicer" 608 18 188 60 13 "Formacion" @() "Dim_TemaFormacion" "TemaFormacion"),
                (New-Visual "cob_filtro_tipo" "slicer" 808 18 188 60 14 "Tipo formacion" @() "Dim_TipoFormacion" "TipoFormacion"),
                (New-Visual "cob_filtro_modalidad" "slicer" 1008 18 240 60 15 "Modalidad" @() "Dim_Modalidad" "Modalidad"),
                (New-Visual "cob_kpi_convocados" "card" 32 98 190 82 1000 "Convocados plan" @("Asistencia Total Convocados")),
                (New-Visual "cob_kpi_asistentes" "card" 238 98 190 82 1001 "Asistentes" @("Asistencia Total Asistentes")),
                (New-Visual "cob_kpi_unicos" "card" 444 98 190 82 1002 "Participantes unicos" @("Asistencia Participantes Unicos")),
                (New-Visual "cob_kpi_pct" "card" 650 98 190 82 1003 "% Cobertura" @("% Cobertura")),
                (New-Visual "cob_kpi_ausentismo" "card" 856 98 190 82 1004 "Brecha cobertura" @("% Brecha Cobertura")),
                (New-Visual "cob_kpi_var" "card" 1062 98 186 82 1005 "Var asistentes MoM" @("Asistencia Variacion MoM")),
                (New-Visual "cob_mes" "lineChart" 32 208 760 214 2000 "Participacion mensual y variacion" @("Asistencia Total Asistentes", "Asistencia Variacion MoM") "Dim_Calendario" "AnioMes"),
                (New-Visual "cob_empresa" "barChart" 820 208 428 214 2001 "Asistencia por empresa" @("Asistencia Total Asistentes") "Dim_Empresa" "Empresa"),
                (New-Visual "cob_tema" "barChart" 32 452 590 218 3000 "Asistencia por formacion" @("Asistencia Total Asistentes") "Dim_TemaFormacion" "TemaFormacion"),
                (New-Visual "cob_tabla" "tableEx" 658 452 590 218 3001 "Resumen ejecutivo por empresa" @("Asistencia Total Asistentes", "Asistencia Participantes Unicos", "Asistencia Promedio Por Formacion", "Asistencia Variacion MoM") "" "" @(@{ Entity = "Dim_Empresa"; Column = "Empresa" }))
            )
        },
        [ordered]@{
            Name = "ad1e0400000000000004"
            Display = "04 Satisfaccion y Eficacia"
            Visuals = @(
                (New-Visual "cal_filtro_anio" "slicer" 32 18 176 60 10 "Anio" @() "Dim_Calendario" "Anio"),
                (New-Visual "cal_filtro_mes" "slicer" 220 18 176 60 11 "Mes" @() "Dim_Calendario" "AnioMes"),
                (New-Visual "cal_filtro_empresa" "slicer" 408 18 188 60 12 "Empresa" @() "Dim_Empresa" "Empresa"),
                (New-Visual "cal_filtro_tema" "slicer" 608 18 188 60 13 "Formacion" @() "Dim_TemaFormacion" "TemaFormacion"),
                (New-Visual "cal_filtro_tipo" "slicer" 808 18 188 60 14 "Tipo formacion" @() "Dim_TipoFormacion" "TipoFormacion"),
                (New-Visual "cal_filtro_modalidad" "slicer" 1008 18 240 60 15 "Modalidad" @() "Dim_Modalidad" "Modalidad"),
                (New-Visual "cal_kpi_respuestas" "card" 32 98 190 82 1000 "Encuestas" @("Encuesta Total Respuestas")),
                (New-Visual "cal_kpi_tasa" "card" 238 98 190 82 1001 "Tasa respuesta" @("Encuesta Tasa Respuesta")),
                (New-Visual "cal_kpi_satisfaccion" "card" 444 98 190 82 1002 "Satisfaccion" @("Encuesta Favorabilidad")),
                (New-Visual "cal_kpi_favorabilidad" "card" 650 98 190 82 1003 "Calif satisfaccion" @("Encuesta Calificacion Satisfaccion Formacion")),
                (New-Visual "cal_kpi_eficacia" "card" 856 98 190 82 1004 "Eficacia plan" @("Plan Eficacia Promedio")),
                (New-Visual "cal_kpi_var_sat" "card" 1062 98 186 82 1005 "Var sat MoM" @("Encuesta Favorabilidad Variacion MoM")),
                (New-Visual "cal_mes" "lineChart" 32 208 760 214 2000 "Satisfaccion y respuesta mensual" @("Encuesta Favorabilidad", "Encuesta Tasa Respuesta") "Dim_Calendario" "AnioMes"),
                (New-Visual "cal_empresa" "barChart" 820 208 428 214 2001 "Favorabilidad por empresa" @("Encuesta Favorabilidad") "Dim_Empresa" "Empresa"),
                (New-Visual "cal_tema" "barChart" 32 452 390 218 3000 "Satisfaccion por formacion" @("Encuesta Favorabilidad") "Dim_TemaFormacion" "TemaFormacion"),
                (New-Visual "cal_tipo_eficacia" "barChart" 452 452 390 218 3001 "Eficacia por tipo" @("Plan Eficacia Promedio") "Dim_TipoFormacion" "TipoFormacion"),
                (New-Visual "cal_tabla" "tableEx" 872 452 376 218 3002 "Detalle calidad" @("Encuesta Total Respuestas", "Encuesta Favorabilidad", "Encuesta Calificacion Satisfaccion Formacion", "Encuesta NPS Equivalente") "" "" @(@{ Entity = "Dim_TemaFormacion"; Column = "TemaFormacion" }))
            )
        },
        [ordered]@{
            Name = "ad1e0500000000000005"
            Display = "05 Inducción y Entrenamiento"
            Visuals = @(
                (New-Visual "ind_filtro_anio" "slicer" 32 18 176 60 10 "Anio" @() "Dim_Calendario" "Anio"),
                (New-Visual "ind_filtro_mes" "slicer" 220 18 176 60 11 "Mes" @() "Dim_Calendario" "AnioMes"),
                (New-Visual "ind_filtro_empresa" "slicer" 408 18 188 60 12 "Empresa" @() "Dim_Empresa" "Empresa"),
                (New-Visual "ind_filtro_area" "slicer" 608 18 188 60 13 "Area" @() "Dim_Area" "Area"),
                (New-Visual "ind_filtro_estado" "slicer" 808 18 188 60 14 "Estado" @() "Dim_EstadoInduccion" "EstadoInduccion"),
                (New-Visual "ind_filtro_segmento" "slicer" 1008 18 240 60 15 "Segmento UC" @() "Dim_SegmentoUC" "SegmentoUC"),
                (New-Visual "ind_kpi_total" "card" 32 98 138 82 1000 "Colaboradores" @("Induccion Total Colaboradores")),
                (New-Visual "ind_kpi_cumplimiento" "card" 186 98 138 82 1001 "Onboarding %" @("Induccion Porcentaje Cumplimiento")),
                (New-Visual "ind_kpi_entrenamiento" "card" 340 98 138 82 1002 "Entrenamiento %" @("Induccion Porcentaje Entrenamiento")),
                (New-Visual "ind_kpi_onboarding" "card" 494 98 138 82 1003 "Onboarding neto" @("Induccion Onboarding")),
                (New-Visual "ind_kpi_tiempo" "card" 648 98 138 82 1004 "Dias promedio" @("Induccion Tiempo Promedio Finalizacion Dias")),
                (New-Visual "ind_kpi_antes" "card" 802 98 138 82 1005 "Antes UC" @("Induccion Cumplimiento Antes UC")),
                (New-Visual "ind_kpi_uc2025" "card" 956 98 138 82 1006 "UC 2025" @("Induccion Cumplimiento UC 2025")),
                (New-Visual "ind_kpi_uc2026" "card" 1110 98 138 82 1007 "UC 2026" @("Induccion Cumplimiento UC 2026")),
                (New-Visual "ind_segmento" "barChart" 32 208 420 214 2000 "Onboarding y entrenamiento por segmento" @("Induccion Porcentaje Cumplimiento", "Induccion Porcentaje Entrenamiento") "Dim_SegmentoUC" "SegmentoUC"),
                (New-Visual "ind_mes" "lineChart" 482 208 480 214 2001 "Onboarding y entrenamiento mensual" @("Induccion Porcentaje Cumplimiento", "Induccion Porcentaje Entrenamiento") "Dim_Calendario" "AnioMes"),
                (New-Visual "ind_variacion_2025" "card" 992 208 256 94 2002 "Var UC 2025 vs Antes" @("Induccion Variacion UC2025 vs Antes UC")),
                (New-Visual "ind_variacion_2026" "card" 992 328 256 94 2003 "Var UC 2026 vs UC 2025" @("Induccion Variacion UC2026 vs UC2025")),
                (New-Visual "ind_empresa" "barChart" 32 452 590 218 3000 "Onboarding y entrenamiento por empresa" @("Induccion Porcentaje Cumplimiento", "Induccion Porcentaje Entrenamiento") "Dim_Empresa" "Empresa"),
                (New-Visual "ind_tabla" "tableEx" 658 452 590 218 3001 "Comparativo induccion y entrenamiento" @("Induccion Total Colaboradores", "Induccion Aprobados", "Induccion Porcentaje Cumplimiento", "Induccion Porcentaje Entrenamiento", "Induccion Onboarding", "Induccion Tiempo Promedio Finalizacion Dias") "" "" @(@{ Entity = "Dim_SegmentoUC"; Column = "SegmentoUC" }))
            )
        },
        [ordered]@{
            Name = "ad1e0600000000000006"
            Display = "06 Focos de Gestion"
            Visuals = @(
                (New-Visual "foc_filtro_anio" "slicer" 32 18 176 60 10 "Anio" @() "Dim_Calendario" "Anio"),
                (New-Visual "foc_filtro_mes" "slicer" 220 18 176 60 11 "Mes" @() "Dim_Calendario" "AnioMes"),
                (New-Visual "foc_filtro_empresa" "slicer" 408 18 188 60 12 "Empresa" @() "Dim_Empresa" "Empresa"),
                (New-Visual "foc_filtro_area" "slicer" 608 18 188 60 13 "Area" @() "Dim_Area" "Area"),
                (New-Visual "foc_filtro_tipo" "slicer" 808 18 188 60 14 "Tipo formacion" @() "Dim_TipoFormacion" "TipoFormacion"),
                (New-Visual "foc_filtro_segmento" "slicer" 1008 18 240 60 15 "Segmento UC" @() "Dim_SegmentoUC" "SegmentoUC"),
                (New-Visual "foc_kpi_alerta_plan" "card" 32 98 190 82 1000 "Alerta plan bajo" @("Alerta Plan Bajo Cumplimiento")),
                (New-Visual "foc_kpi_alerta_ind" "card" 238 98 190 82 1001 "Alerta induccion baja" @("Alerta Induccion Bajo Cumplimiento")),
                (New-Visual "foc_kpi_indice" "card" 444 98 190 82 1002 "Indice aprendizaje" @("KPI Indice Aprendizaje")),
                (New-Visual "foc_kpi_pendientes" "card" 650 98 190 82 1003 "Pendientes plan" @("Plan Actividades Pendientes")),
                (New-Visual "foc_kpi_var_asis" "card" 856 98 190 82 1004 "Var asistentes MoM" @("Asistencia Variacion MoM")),
                (New-Visual "foc_kpi_var_ind" "card" 1062 98 186 82 1005 "Var cumpl. induccion" @("Induccion Variacion Cumplimiento MoM")),
                (New-Visual "foc_rank_plan" "barChart" 32 208 390 214 2000 "Areas con mayor cumplimiento del plan" @("Plan Porcentaje Ejecucion") "Dim_Area" "Area"),
                (New-Visual "foc_rank_ind" "barChart" 452 208 390 214 2001 "Areas con cumplimiento de induccion" @("Induccion Porcentaje Cumplimiento") "Dim_Area" "Area"),
                (New-Visual "foc_rank_empresa" "barChart" 872 208 376 214 2002 "Empresas con mayor asistencia" @("Asistencia Total Asistentes") "Dim_Empresa" "Empresa"),
                (New-Visual "foc_decision_area" "tableEx" 32 452 590 218 3000 "Tablero de decision por area" @("Plan Porcentaje Ejecucion", "Induccion Porcentaje Cumplimiento", "Alerta Plan Bajo Cumplimiento", "Alerta Induccion Bajo Cumplimiento") "" "" @(@{ Entity = "Dim_Area"; Column = "Area" })),
                (New-Visual "foc_decision_empresa" "tableEx" 658 452 590 218 3001 "Tablero de decision por empresa" @("Asistencia Total Asistentes", "Encuesta Favorabilidad", "Induccion Porcentaje Cumplimiento", "KPI Indice Aprendizaje") "" "" @(@{ Entity = "Dim_Empresa"; Column = "Empresa" }))
            )
        }
    )

    if (Test-Path $PagesRoot) {
        Get-ChildItem -LiteralPath $PagesRoot -Directory | Remove-Item -Recurse -Force
    }
    else {
        New-Item -ItemType Directory -Force -Path $PagesRoot | Out-Null
    }

    foreach ($page in $pages) {
        New-ReportPage -Name $page.Name -DisplayName $page.Display -Visuals $page.Visuals
    }

    Write-JsonFile (Join-Path $PagesRoot "pages.json") ([ordered]@{
        '$schema' = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/pagesMetadata/1.0.0/schema.json"
        pageOrder = @($pages | ForEach-Object { $_.Name })
        activePageName = $pages[0].Name
    })

    $theme = Get-Content -LiteralPath $ThemePath -Raw | ConvertFrom-Json
    $theme.name = "CY25SU11"
    $theme.dataColors = @("#1B487F", "#F7931E", "#1A3059", "#0B1C35", "#000032", "#4D6F8F", "#7A7F85", "#D64550", "#2F8F83", "#9AA6B2")
    $theme.foreground = "#0B1C35"
    $theme.foregroundNeutralSecondary = "#1A3059"
    $theme.foregroundNeutralTertiary = "#4D6F8F"
    $theme.background = "#FFFFFF"
    $theme.backgroundLight = "#F4F7FA"
    $theme.backgroundNeutral = "#E6EEF5"
    $theme.tableAccent = "#F7931E"
    $theme.good = "#1A7F37"
    $theme.neutral = "#F7931E"
    $theme.bad = "#D64550"
    $theme.maximum = "#1B487F"
    $theme.center = "#F7931E"
    $theme.minimum = "#E6EEF5"
    if ($theme.textClasses) {
        $theme.textClasses.callout.fontFace = "Outfit"
        $theme.textClasses.callout.color = "#1B487F"
        $theme.textClasses.title.fontFace = "Outfit"
        $theme.textClasses.title.color = "#0B1C35"
        $theme.textClasses.header.fontFace = "Outfit"
        $theme.textClasses.header.color = "#1B487F"
        $theme.textClasses.label.fontFace = "Segoe UI"
        $theme.textClasses.label.color = "#0B1C35"
    }
    Write-JsonFile $ThemePath $theme
}

if (-not $ReportOnly) {
    $localPort = Get-PowerBIPort
    Write-Host "Conectando a Power BI Desktop en localhost:$localPort"
    Set-ModelLayer -LocalPort $localPort
    Write-Host "Modelo tabular actualizado."
}

if (-not $ModelOnly) {
    Set-ReportLayer
    Write-Host "Definicion PBIR y tema visual actualizados."
}
