# Volcado de datos

Elimine las tablas country, region, city. Tenga en cuenta que la eliminación la debe realizar respetando la relacion y las llaves foraneas.

```sql
DROP TABLE city;
DROP TABLE region;
DROP TABLE country;
```

```
               Listado de relaciones
 Esquema |      Nombre      |   Tipo    |  Due±o
---------+------------------+-----------+----------
 public  | empleados        | tabla     | postgres
 public  | empleados_id_seq | secuencia | postgres
```

Cree las siguientes tablas

```sql
CREATE TABLE "public"."city" (
    "id" int4 NOT NULL,
    "name" text NOT NULL,
    "countrycode" bpchar(3) NOT NULL,
    "district" text NOT NULL,
    "population" int4 NOT NULL CHECK (population >= 0),
    PRIMARY KEY ("id")
);
CREATE TABLE "public"."country" (
    "code" bpchar(3) NOT NULL,
    "name" text NOT NULL,
    "continent" text NOT NULL CHECK ((continent = 'Asia'::text) OR (continent = 'South America'::text) OR (continent = 'North America'::text) OR (continent = 'Oceania'::text) OR (continent = 'Antarctica'::text) OR (continent = 'Africa'::text) OR (continent = 'Europe'::text) OR (continent = 'Central America'::text)),
    "region" text NOT NULL,
    "surfacearea" float4 NOT NULL CHECK (surfacearea >= (0)::double precision),
    "indepyear" int2,
    "population" int4 NOT NULL,
    "lifeexpectancy" float4,
    "gnp" numeric(10,2),
    "gnpold" numeric(10,2),
    "localname" text NOT NULL,
    "governmentform" text NOT NULL,
    "headofstate" text,
    "capital" int4,
    "code2" bpchar(2) NOT NULL,
    PRIMARY KEY ("code")
);
CREATE TABLE "public"."countrylanguage" (
    "countrycode" bpchar(3) NOT NULL,
    "language" text NOT NULL,
    "isofficial" bool NOT NULL,
    "percentage" float4 NOT NULL CHECK ((percentage >= (0)::double precision) AND (percentage <= (100)::double precision)),
    PRIMARY KEY ("countrycode","language")
);
```

Data Inicial : country.sql - city.sql - countrylanguage.sql

Cree una tabla llamada continent

```sql
CREATE TABLE public.continent (
	code serial4 NOT NULL,
	name text NULL,
	CONSTRAINT continent_pk PRIMARY KEY (code)
);
```

Caso de uso : Se requiere llenar la tabla continent con los continentes que se encuentran en la tabla country

![](https://i.ibb.co/VcrBm5dy/image.png)

Caso de uso : Liste los continentes de la tabla country. Los continentes no se deben repetir.

![](https://i.ibb.co/LhBLfTBh/image.png)

Ejecute el siguiente comando sql para listar e insertar los registros de continentes.

```SQL
INSERT INTO continent (name)
	SELECT DISTINCT continent
	FROM country
	ORDER BY continent ASC;
```

![](https://i.ibb.co/QFPnq25T/image.png)