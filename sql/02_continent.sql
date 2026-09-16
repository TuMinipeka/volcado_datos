INSERT INTO continent (name)
	SELECT DISTINCT continent
	FROM country
	ORDER BY continent ASC;
