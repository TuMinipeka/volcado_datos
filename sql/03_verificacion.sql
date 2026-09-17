-- =====================================================================
-- Verificacion del volcado de datos
-- Conteos esperados: country 239 | city 4078 | countrylanguage 983 | continent 8
-- =====================================================================

-- 1. Conteo de filas por tabla
SELECT (SELECT count(*) FROM country)         AS country,
       (SELECT count(*) FROM city)            AS city,
       (SELECT count(*) FROM countrylanguage) AS countrylanguage,
       (SELECT count(*) FROM continent)       AS continent;

-- 2. Filas con el caracter invalido U+FFFD (chr(65533)). Esperado: 0 en todas.
SELECT 'city' AS tabla,
       count(*) FILTER (WHERE name     LIKE '%' || chr(65533) || '%'
                           OR district LIKE '%' || chr(65533) || '%') AS filas_con_caracter_invalido
FROM city
UNION ALL
SELECT 'country',
       count(*) FILTER (WHERE name                    LIKE '%' || chr(65533) || '%'
                           OR localname               LIKE '%' || chr(65533) || '%'
                           OR governmentform          LIKE '%' || chr(65533) || '%'
                           OR coalesce(headofstate,'') LIKE '%' || chr(65533) || '%')
FROM country
UNION ALL
SELECT 'countrylanguage',
       count(*) FILTER (WHERE language LIKE '%' || chr(65533) || '%')
FROM countrylanguage;

-- 3. Registros que originalmente traian el caracter; deben verse limpios
SELECT id, name, district FROM city WHERE id IN (20, 33, 40);
SELECT code, name, localname, headofstate FROM country WHERE code IN ('AGO', 'ALB');

-- 4. Revision estricta: textos con algun caracter fuera del rango ASCII. Esperado: 0 rows.
SELECT 'city' AS tabla, id::text AS clave, name AS valor
FROM city WHERE name ~ '[^ -~]' OR district ~ '[^ -~]'
UNION ALL
SELECT 'country', code, name
FROM country WHERE name ~ '[^ -~]' OR localname ~ '[^ -~]' OR coalesce(headofstate,'') ~ '[^ -~]'
UNION ALL
SELECT 'countrylanguage', countrycode, language
FROM countrylanguage WHERE language ~ '[^ -~]';

-- 5. Codificacion. Esperado: UTF8 en ambos.
SHOW server_encoding;
SHOW client_encoding;

-- 6. Continentes sin repetir (caso de uso del taller) y tabla continent
SELECT DISTINCT continent FROM country ORDER BY continent;
SELECT * FROM continent ORDER BY code;
