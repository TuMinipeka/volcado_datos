# Genera data/limpio/*.sql a partir de data/original/*.sql eliminando el
# caracter U+FFFD (replacement character) que dejo la exportacion original.
# Escribe UTF-8 SIN BOM: psql falla con "syntax error" si el archivo trae BOM.
$root = Split-Path $PSScriptRoot -Parent
$utf8 = New-Object System.Text.UTF8Encoding($false)
Get-ChildItem "$root\data\original\*.sql" | ForEach-Object {
    $txt = [IO.File]::ReadAllText($_.FullName, [Text.Encoding]::UTF8) -replace [char]0xFFFD, ''
    [IO.File]::WriteAllText("$root\data\limpio\$($_.Name)", $txt, $utf8)
    Write-Host "limpio -> data/limpio/$($_.Name)"
}
