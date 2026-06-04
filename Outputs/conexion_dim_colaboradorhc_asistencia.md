# Conexion Dim_ColaboradorHC con Fct_AsistenciaFormacion

Fecha: 2026-06-04

## Objetivo

Conectar `Dim_ColaboradorHC` con `Fct_AsistenciaFormacion` usando una llave mensual que permita identificar el nivel o tipo de cargo vigente del colaborador en el corte de HC correspondiente al mes de la asistencia.

## Cambio aplicado

Se agrego la columna calculada tecnica `Colaborador_Key` en `Fct_AsistenciaFormacion`.

Logica:

```DAX
VAR _doc0 =
    UPPER(
        TRIM(
            SUBSTITUTE(
                COALESCE('Fct_AsistenciaFormacion'[Número de documento del participante], ""),
                UNICHAR(160),
                " "
            )
        )
    )
VAR _doc1 =
    SUBSTITUTE(
        SUBSTITUTE(
            SUBSTITUTE(_doc0, ".", ""),
            ",",
            ""
        ),
        " ",
        ""
    )
VAR _fecha = 'Fct_AsistenciaFormacion'[Hora de inicio]
RETURN
    IF(
        _doc1 = "" || ISBLANK(_fecha),
        BLANK(),
        _doc1 & "-" & FORMAT(_fecha, "yyyy-MM")
    )
```

Ejemplo esperado:

```text
1022937645-2026-02
```

## Relacion creada

Se agrego la relacion:

```text
AD_ColaboradorHC_Asistencia
Fct_AsistenciaFormacion[Colaborador_Key] -> Dim_ColaboradorHC[Colaborador_Key]
```

## Validaciones realizadas

### Dim_ColaboradorHC

- Registros revisados: 7.456
- Llaves no vacias: 7.456
- Llaves distintas: 7.456
- Duplicados en `Colaborador_Key`: 0

### Fct_AsistenciaFormacion

- Registros revisados en archivo local: 575
- Llaves generadas: 575
- Llaves vacias o invalidas: 0
- Llaves distintas generadas: 324
- Coincidencias exactas con HC: 117

### Hallazgo de cobertura de cruce

El HC local contiene cortes:

```text
2026-02: 2461 registros
2026-03: 2494 registros
2026-04: 2501 registros
```

La asistencia contiene registros:

```text
2026-02: 65 registros
2026-03: 31 registros
2026-04: 23 registros
2026-05: 456 registros
```

Los 456 registros de asistencia de `2026-05` no encuentran match mensual porque el corte de HC de mayo no esta incluido actualmente en `Dim_ColaboradorHC`.

## Archivos modificados

- `PBIP/Proyecto.SemanticModel/definition/tables/Fct_AsistenciaFormacion.tmdl`
- `PBIP/Proyecto.SemanticModel/definition/relationships.tmdl`

## Respaldo previo

Antes del cambio se creo el checkpoint:

- `backups_codex/backup_20260604_073156_before_colaboradorhc_asistencia_relationship`
