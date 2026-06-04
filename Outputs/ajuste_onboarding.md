# Ajuste medida Onboarding

## Cambio aplicado

La tarjeta `Onboarding` de la pagina `00 Inicio Corporativo` conserva la medida `Induccion Onboarding`, pero ahora calcula:

`Onboarding realizados / Participantes`

## Medidas

Se agregaron dos medidas auxiliares en la carpeta `04 Induccion UC`:

- `Induccion Onboarding Realizados`: conteo de registros con `EstadoInduccion_Key` en `{ "APROBO", "APROBADO" }`.
- `Induccion Onboarding Participantes`: conteo distinto de `Fct_Induccion[Colaborador_Key]`, excluyendo registros con `EstadoInduccion_Key = "RENUNCIA"`.

La medida principal quedo como:

```DAX
Induccion Onboarding =
DIVIDE(
    [Induccion Onboarding Realizados],
    [Induccion Onboarding Participantes],
    0
)
```

## Validacion de datos fuente

En el archivo local de seguimiento de induccion se validaron las tablas fuente:

| Tabla | Campo participante | Registros aprobados | Participantes sin renuncia |
| --- | --- | ---: | ---: |
| Tabla2 | ID | 446 | 483 |
| Tabla24 | CEDULA | 417 | 432 |
| Tabla242 | CEDULA | 412 | 421 |

Resultado consolidado esperado con datos actuales:

- Onboarding realizados: 1.275
- Participantes distintos sin renuncia: 1.319
- Indicador esperado: 96,66%

## Nota tecnica

En la tabla consolidada `Fct_Induccion`, el campo `Estado` de las fuentes queda homologado como `EstadoInduccion_Key`, y el campo `CEDULA`/`ID` queda homologado como `Colaborador_Key`.
