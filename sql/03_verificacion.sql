-- Conteos esperados: country 239 | city 4078 | countrylanguage 983 | continent 8
SELECT (SELECT count(*) FROM country)         AS country,
       (SELECT count(*) FROM city)            AS city,
       (SELECT count(*) FROM countrylanguage) AS countrylanguage,
       (SELECT count(*) FROM continent)       AS continent;

-- Continentes sin repetir (caso de uso del taller)
SELECT DISTINCT continent FROM country ORDER BY continent;

-- Contenido de la tabla continent
SELECT * FROM continent ORDER BY code;
