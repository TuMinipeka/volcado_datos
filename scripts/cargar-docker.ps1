# Carga completa en el contenedor Docker (todo en una transaccion).
# Uso: .\scripts\cargar-docker.ps1 [-Contenedor postgres_db] [-Usuario bkseducate] [-Db college]
param(
    [string]$Contenedor = "postgres_db",
    [string]$Usuario    = "bkseducate",
    [string]$Db         = "college"
)
$root = Split-Path $PSScriptRoot -Parent
$archivos = @("sql\01_schema.sql", "data\limpio\country.sql", "data\limpio\city.sql",
              "data\limpio\countrylanguage.sql", "sql\02_continent.sql")
foreach ($a in $archivos) { docker cp "$root\$a" "${Contenedor}:/tmp/$(Split-Path $a -Leaf)" }
$args = $archivos | ForEach-Object { "-f"; "/tmp/$(Split-Path $_ -Leaf)" }
docker exec $Contenedor psql -U $Usuario -d $Db -v ON_ERROR_STOP=1 --single-transaction @args
docker exec $Contenedor psql -U $Usuario -d $Db -c "SELECT (SELECT count(*) FROM country) country, (SELECT count(*) FROM city) city, (SELECT count(*) FROM countrylanguage) countrylanguage, (SELECT count(*) FROM continent) continent;"
