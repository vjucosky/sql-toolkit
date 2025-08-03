/*
	DROP FUNCTION IF EXISTS LEVENSHTEIN
*/

/*
	Essa função retorna a distância Levenshtein de duas cadeias de
	texto. A função original está disponível em
	https://stackoverflow.com/a/27734606. Por exemplo:

	SELECT dbo.LEVENSHTEIN('vjucosky', 'jucosky', 10) AS EDIT_DISTANCE

	EDIT_DISTANCE
	-------------
	1
*/

CREATE FUNCTION LEVENSHTEIN (@SOURCE AS varchar(4000), @TARGET AS varchar(4000), @LIMIT AS int)
RETURNS int
WITH SCHEMABINDING
AS
BEGIN
	DECLARE @DISTANCE AS int = 0             -- Return variable
	DECLARE @SCRATCHPAD AS varchar(4000)     -- Running scratchpad for storing computed distances
	DECLARE @START_INDEX AS int = 1          -- Index (1 based) of first non-matching character between the two strings
	DECLARE @SOURCE_COUNTER AS int           -- Loop counter for @SOURCE string
	DECLARE @TARGET_COUNTER AS int           -- Loop counter for @TARGET string
	DECLARE @DIAGONAL_DISTANCE AS int        -- Distance in cell diagonally above and left if we were using an M by N matrix
	DECLARE @LEFT_DISTANCE AS int            -- Distance in cell to the left if we were using an M by N matrix
	DECLARE @SOURCE_CHAR AS char(1)          -- Character at index i from @SOURCE string
	DECLARE @TEMPORARY_TARGET_COUNTER AS int -- Temporary storage of @TARGET_COUNTER to allow combining
	DECLARE @TARGET_OFFSET AS int            -- Offset used to calculate starting value for @TARGET loop
	DECLARE @TARGET_END AS int               -- Ending value for @TARGET loop (stopping point for processing a column)

	-- Get input string lengths including any trailing spaces (which SQL Server would otherwise ignore).
	DECLARE @SourceLength AS int = DATALENGTH(@SOURCE) / DATALENGTH(LEFT(LEFT(@SOURCE, 1) + '.', 1)) -- Length of @SOURCE string
	DECLARE @TargetLength AS int = DATALENGTH(@TARGET) / DATALENGTH(LEFT(LEFT(@TARGET, 1) + '.', 1)) -- Length of @TARGET string
	DECLARE @LengthDifference AS int                                                                 -- Difference in length between the two strings

	-- If strings of different lengths, ensure shorter string is in @SOURCE, temporarily using @SCRATCHPAD for swap.
	-- This can result in a little faster speed by spending more time spinning just the inner loop during the main processing.
	IF @SourceLength > @TargetLength
	BEGIN
		SET @SCRATCHPAD = @SOURCE
		SET @SOURCE_COUNTER = @SourceLength
		SET @SOURCE = @TARGET
		SET @SourceLength = @TargetLength
		SET @TARGET = @SCRATCHPAD
		SET @TargetLength = @SOURCE_COUNTER
	END

	SET @LIMIT = ISNULL(@LIMIT, @TargetLength)
	SET @LengthDifference = @TargetLength - @SourceLength

	IF @LengthDifference > @LIMIT RETURN NULL

	-- Suffixes common to both strings can be ignored.
	WHILE @SourceLength > 0 AND SUBSTRING(@SOURCE, @SourceLength, 1) = SUBSTRING(@TARGET, @TargetLength, 1)
	BEGIN
		SET @SourceLength = @SourceLength - 1
		SET @TargetLength = @TargetLength - 1
	END

	IF @SourceLength = 0 RETURN @TargetLength

	-- Prefixes common to both strings can be ignored.
	WHILE @START_INDEX < @SourceLength AND SUBSTRING(@SOURCE, @START_INDEX, 1) = SUBSTRING(@TARGET, @START_INDEX, 1)
	BEGIN
		SET @START_INDEX = @START_INDEX + 1
	END

	IF @START_INDEX > 1
	BEGIN
		SET @SourceLength = @SourceLength - (@START_INDEX - 1)
		SET @TargetLength = @TargetLength - (@START_INDEX - 1)

		-- If all of shorter string matches prefix and/or suffix of longer string, then edit distance is just the delete of additional characters present in longer string.
		IF @SourceLength <= 0 RETURN @TargetLength

		SET @SOURCE = SUBSTRING(@SOURCE, @START_INDEX, @SourceLength)
		SET @TARGET = SUBSTRING(@TARGET, @START_INDEX, @TargetLength)
	END

	-- Initialize @SCRATCHPAD array of distances.
	SET @SCRATCHPAD = ''
	SET @TARGET_COUNTER = 1

	WHILE @TARGET_COUNTER <= @TargetLength
	BEGIN
		SET @SCRATCHPAD = @SCRATCHPAD + CASE
			WHEN @TARGET_COUNTER > @LIMIT THEN char(@LIMIT)
			ELSE char(@TARGET_COUNTER)
		END

		SET @TARGET_COUNTER = @TARGET_COUNTER + 1
	END

	SET @TARGET_OFFSET = @LIMIT - @LengthDifference
	SET @SOURCE_COUNTER = 1

	WHILE @SOURCE_COUNTER <= @SourceLength
	BEGIN
		SET @DISTANCE = @SOURCE_COUNTER
		SET @DIAGONAL_DISTANCE = @SOURCE_COUNTER - 1
		SET @SOURCE_CHAR = SUBSTRING(@SOURCE, @SOURCE_COUNTER, 1)

		-- No need to look beyond window of upper left diagonal @SOURCE_COUNTER + @LIMIT cells and the lower right diagonal (@SOURCE_COUNTER - @LengthDifference) - @LIMIT cells.
		SET @TARGET_COUNTER = CASE
			WHEN @SOURCE_COUNTER <= @TARGET_OFFSET THEN 1
			ELSE @SOURCE_COUNTER - @TARGET_OFFSET
		END

		SET @TARGET_END = CASE
			WHEN @SOURCE_COUNTER + @LIMIT >= @TargetLength THEN @TargetLength
			ELSE @SOURCE_COUNTER + @LIMIT
		END

		WHILE @TARGET_COUNTER <= @TARGET_END
		BEGIN
			-- At this point, @DISTANCE holds the previous value (the cell above if we were using an M by N matrix).
			SET @LEFT_DISTANCE = UNICODE(SUBSTRING(@SCRATCHPAD, @TARGET_COUNTER, 1))
			SET @TEMPORARY_TARGET_COUNTER = @TARGET_COUNTER

			SET @DISTANCE = CASE
				WHEN @SOURCE_CHAR = SUBSTRING(@TARGET, @TARGET_COUNTER, 1) THEN @DIAGONAL_DISTANCE                      -- Match, no change
				ELSE 1 + CASE
					WHEN @DIAGONAL_DISTANCE < @LEFT_DISTANCE AND @DIAGONAL_DISTANCE < @DISTANCE THEN @DIAGONAL_DISTANCE -- Substitution
					WHEN @LEFT_DISTANCE < @DISTANCE THEN @LEFT_DISTANCE                                                 -- Insertion
					ELSE @DISTANCE                                                                                      -- Deletion
				END
			END

			SET @SCRATCHPAD = STUFF(@SCRATCHPAD, @TEMPORARY_TARGET_COUNTER, 1, char(@DISTANCE))
			SET @DIAGONAL_DISTANCE = @LEFT_DISTANCE

			SET @TARGET_COUNTER = CASE
				WHEN @DISTANCE > @LIMIT AND @TEMPORARY_TARGET_COUNTER = @SOURCE_COUNTER + @LengthDifference THEN @TARGET_END + 2
				ELSE @TEMPORARY_TARGET_COUNTER + 1
			END
		END

		SET @SOURCE_COUNTER = CASE
			WHEN @TARGET_COUNTER > @TARGET_END + 1 THEN @SourceLength + 1
			ELSE @SOURCE_COUNTER + 1
		END
	END

	RETURN CASE
		WHEN @DISTANCE <= @LIMIT THEN @DISTANCE
		ELSE NULL
	END
END
