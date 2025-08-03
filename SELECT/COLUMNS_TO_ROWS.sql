SELECT
	T.ID,
	N.C.value('local-name(.)', 'varchar(128)') AS COLUMN_NAME,
	N.C.value('.', 'varchar(max)') AS COLUMN_VALUE
FROM (
	SELECT TOP(1)
		ID,
		(
			SELECT S.*
			FOR XML RAW('row'), TYPE
		) AS [DATA]
	FROM WEATHER_STATION_READING AS S
) AS T
OUTER APPLY T.[DATA].nodes('row/@*') AS N(C)
ORDER BY T.ID
