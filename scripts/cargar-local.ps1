# Carga con psql instalado en Windows. La clave es PGCLIENTENCODING=UTF8:
# sin ella psql usa WIN1252 y falla con "invalid byte sequence for encoding".
# Uso: .\scripts\cargar-local.ps1 -Db college [-Usuario postgres] [-Puerto 5432]
param(
    [string]$Db,
    [string]$Usuario = "postgres",
    [int]$Puerto     = 5432,
    [string]$Psql    = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
)
$env:PGCLIENTENCODING = "UTF8"
$root = Split-Path $PSScriptRoot -Parent
& $Psql -U $Usuario -p $Puerto -d $Db -v ON_ERROR_STOP=1 --single-transaction `
    -f "$root\sql\01_schema.sql" `
    -f "$root\data\limpio\country.sql" `
    -f "$root\data\limpio\city.sql" `
    -f "$root\data\limpio\countrylanguage.sql" `
    -f "$root\sql\02_continent.sql"
