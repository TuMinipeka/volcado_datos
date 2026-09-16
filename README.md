# Taller: Volcado de datos en PostgreSQL

Migración de la base de datos de ejemplo **world** (países, ciudades e idiomas) a PostgreSQL,
resolviendo el problema de **caracteres especiales corruptos** en los archivos `.sql` de origen
y construyendo la tabla `continent` a partir de los datos cargados.

| Tabla | Filas | Descripción |
|---|---|---|
| `country` | 239 | Países con continente, región, superficie, población, PIB, etc. |
| `city` | 4078 | Ciudades con código de país, distrito y población |
| `countrylanguage` | 983 | Idiomas por país, si es oficial y porcentaje de hablantes |
| `continent` | 8 | Continentes únicos derivados de `country` |

## Estructura del repositorio

```
.
├── README.md
├── docs/
│   └── enunciado.md            # Enunciado original del taller
├── sql/
│   ├── 01_schema.sql           # DROP (en orden de FKs) + CREATE de las 4 tablas
│   ├── 02_continent.sql        # INSERT ... SELECT DISTINCT para poblar continent
│   └── 03_verificacion.sql     # Consultas de conteo y validación
├── data/
│   ├── original/               # Archivos tal como se entregaron (con caracteres �)
│   └── limpio/                 # Archivos corregidos, listos para cargar
└── scripts/
    ├── limpiar.ps1             # Genera data/limpio a partir de data/original
    ├── cargar-docker.ps1       # Carga completa en un contenedor Docker
    └── cargar-local.ps1        # Carga completa con psql instalado en Windows
```

## El problema: caracteres especiales

Los archivos originales contienen textos como `'Jos� Eduardo dos Santos'` o `'�s-Hertogenbosch'`.
Al inspeccionar los bytes se encontró que ese símbolo **no** es un acento mal codificado, sino el
carácter `U+FFFD` (*replacement character*, bytes `EF BF BD`). Aparece 1036 veces en total:

| Archivo | Ocurrencias |
|---|---|
| `city.sql` | 898 |
| `country.sql` | 121 |
| `countrylanguage.sql` | 17 |

Esto significa que la tilde original **ya se perdió** cuando se exportó el archivo: `José` se guardó
como `Jos�` y no existe forma automática de recuperar la letra. Dos consecuencias:

1. Los archivos son **UTF-8 válido**, así que no rompen el `INSERT` en una base UTF-8.
2. El error típico al cargarlos desde Windows es otro:
   ```
   ERROR: invalid byte sequence for encoding "WIN1252"
   ```
   Ocurre porque `psql` en Windows usa `client_encoding = WIN1252` por defecto y no entiende los
   bytes UTF-8 de 3 bytes. **La solución es declarar la codificación del cliente**, no alterar los datos:
   ```powershell
   $env:PGCLIENTENCODING = "UTF8"
   ```

### Solución aplicada

- Se eliminó el carácter `U+FFFD` de los tres archivos (`scripts/limpiar.ps1`), generando
  `data/limpio/`. Resultado: `Jos Eduardo dos Santos`, `s-Hertogenbosch`, `Shqipria`.
- Los archivos limpios se escriben en **UTF-8 sin BOM**: un BOM al inicio hace que `psql` falle con
  `syntax error at or near "INSERT"`.
- Las comillas internas (`Cote d''Ivoire`) ya venían correctamente escapadas y se conservaron.

> Si se requiere el nombre exacto de algún registro, se corrige puntualmente:
> `UPDATE country SET headofstate = 'José Eduardo dos Santos' WHERE code = 'AGO';`

## Pasos realizados

1. **Eliminar las tablas anteriores respetando las llaves foráneas.** El orden es hijas → padres:
   `city` (→ `region`) → `region` (→ `country`) → `country`. Para descubrir las dependencias:
   ```sql
   SELECT conname, conrelid::regclass AS tabla, confrelid::regclass AS referencia
   FROM pg_constraint WHERE contype = 'f';
   ```
2. **Crear las tablas** `city`, `country`, `countrylanguage` y `continent` (`sql/01_schema.sql`).
3. **Cargar los datos** en el orden `country` → `city` → `countrylanguage`, dentro de una sola
   transacción (`--single-transaction` + `ON_ERROR_STOP`): si algo falla, no queda nada a medias.
4. **Poblar `continent`** con `INSERT ... SELECT DISTINCT` (`sql/02_continent.sql`):
   ```sql
   INSERT INTO continent (name)
       SELECT DISTINCT continent FROM country ORDER BY continent ASC;
   ```
5. **Verificar** con `sql/03_verificacion.sql`.

## Cómo reproducirlo

### Opción A: Docker (usada en este taller)

Contenedor `postgres_db` (imagen `postgres:16`), usuario `bkseducate`, base `college`.
```powershell
.\scripts\cargar-docker.ps1 -Contenedor postgres_db -Usuario bkseducate -Db college
```
Dentro del contenedor el cliente ya es UTF-8, por lo que no hay problema de codificación.

### Opción B: psql instalado en Windows
```powershell
.\scripts\cargar-local.ps1 -Db college -Usuario postgres -Puerto 5432
```

### Opción C: pgAdmin
Abrir cada archivo en el *Query Tool* en este orden y ejecutarlo completo:
`sql/01_schema.sql` → `data/limpio/country.sql` → `data/limpio/city.sql` →
`data/limpio/countrylanguage.sql` → `sql/02_continent.sql`.

## Resultado

```
 country | city | countrylanguage | continent
---------+------+-----------------+-----------
     239 | 4078 |             983 |         8
```

| code | name |
|---|---|
| 1 | Africa |
| 2 | Antarctica |
| 3 | Asia |
| 4 | Central America |
| 5 | Europe |
| 6 | North America |
| 7 | Oceania |
| 8 | South America |

## Errores frecuentes

| Error | Causa | Solución |
|---|---|---|
| `invalid byte sequence for encoding "WIN1252"` | Cliente psql de Windows en WIN1252 | `$env:PGCLIENTENCODING = "UTF8"` |
| `syntax error at or near "INSERT"` en la línea 1 | El archivo tiene BOM | Guardar como UTF-8 sin BOM |
| `cannot drop table country because other objects depend on it` | Orden de borrado incorrecto | Borrar primero las tablas hijas (o `CASCADE`) |
| `duplicate key value violates unique constraint` | Archivo ejecutado dos veces | `TRUNCATE country, city, countrylanguage, continent;` y recargar |

## Herramientas

- PostgreSQL 16 (Docker) / PostgreSQL 18 (local), `psql`, pgAdmin 4
- PowerShell para los scripts de limpieza y carga
- `xxd` / `grep` para inspeccionar los bytes de los archivos
