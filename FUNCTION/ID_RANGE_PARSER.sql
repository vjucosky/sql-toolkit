/*
	DROP FUNCTION IF EXISTS ID_RANGE_PARSER
*/

/*
	Essa função converte um array JSON contendo intervalos em
	uma tabela SQL, útil para operações JOIN com intervalos.
	Por exemplo:

	SELECT *
	FROM ID_RANGE_PARSER('[1,2,[3,5],[7,9]]')

	START_ID END_ID
	-------- ------
	1        1
	2        2
	3        5
	7        9
*/

CREATE FUNCTION ID_RANGE_PARSER (@RANGE AS varchar(4000))
RETURNS table
AS
RETURN
	SELECT
		CASE
			WHEN [TYPE] = 4 THEN JSON_VALUE([VALUE], '$[0]')
			ELSE [VALUE]
		END AS START_ID,
		CASE
			WHEN [TYPE] = 4 THEN JSON_VALUE([VALUE], '$[1]')
			ELSE [VALUE]
		END AS END_ID
	FROM OPENJSON(@RANGE)
