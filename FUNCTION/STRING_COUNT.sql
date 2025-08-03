/*
	DROP FUNCTION IF EXISTS STRING_COUNT
*/

/*
	Essa função retorna o número de ocorrências de @PATTERN em @STRING,
	similar ao método str.count() do Python. Por exemplo:

	SELECT dbo.STRING_COUNT('Algum texto contendo várias ocorrências de texto', 'TEXTO') AS RESULT

	RESULT
	------
	2
*/

CREATE FUNCTION STRING_COUNT (@STRING AS varchar(4000), @PATTERN AS varchar(4000))
RETURNS smallint
AS
BEGIN
	RETURN (LEN(@STRING) - LEN(REPLACE(@STRING, @PATTERN, ''))) / LEN(@PATTERN)
END
