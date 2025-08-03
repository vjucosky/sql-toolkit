/*
	DROP FUNCTION IF EXISTS CAPITALIZE
*/

/*
	Essa função retorna uma cadeia de texto capitalizada; semelhante
	ao método str.capitalize() do Python. Por exemplo:

	SELECT dbo.CAPITALIZE('aLgUm TeXtO') AS [SAMPLE]

	SAMPLE
	-----------
	Algum texto
*/

CREATE FUNCTION CAPITALIZE (@STRING AS varchar(4000))
RETURNS varchar(4000)
AS
BEGIN
	RETURN UPPER(LEFT(@STRING, 1)) + LOWER(SUBSTRING(@STRING, 2, 3999))
END
