/****** Object:  UserDefinedFunction [dbo].[GetOpenLocationCode]    Script Date: 11/26/2018 12:08:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Victor-Vartan Pambuccian
-- Create date: 2018-11-22
-- Description:	The MSSQL implementation of converting latitude and longitude to Open Location Code
-- =============================================
ALTER FUNCTION [dbo].[GetOpenLocationCode]
(
	@latitude DECIMAL(9,6), 
	@longitude DECIMAL(9,6),
	@codeLength INT = 10
)
RETURNS VARCHAR(MAX)
AS
BEGIN
	DECLARE @code VARCHAR(MAX) = '';

	DECLARE @CodePrecisionNormal INT = 10; -- Provides a normal precision code, approximately 14x14 meters.
   	DECLARE @CodePrecisionExtra INT = 11; -- Provides an extra precision code, approximately 2x3 meters.
	DECLARE @Separator CHAR(1) = '+'; -- A separator used to break the code into two parts to aid memorability.
    DECLARE @SeparatorPosition INT = 8; -- The number of characters to place before the separator.
	DECLARE @PaddingCharacter CHAR(1) = '0'; -- The character used to pad codes.
	DECLARE @CodeAlphabet CHAR(20) = '23456789CFGHJMPQRVWX'; -- The character set used to encode the values.
	DECLARE @EncodingBase INT = LEN(@CodeAlphabet); -- The base to use to convert numbers to/from.
	DECLARE @EncodingBaseSquared INT = @EncodingBase * @EncodingBase;
    DECLARE @LatitudeMax INT = 90; -- The maximum value for latitude in degrees.
    DECLARE @LongitudeMax INT = 180; -- The maximum value for longitude in degrees.
	DECLARE @PairCodeLength INT = 10; -- Maxiumum code length using just lat/lng pair encoding.
	DECLARE @GridColumns INT = 4; -- Number of columns in the grid refinement method.
	DECLARE @GridRows INT = 5; -- Number of rows in the grid refinement method.

	-- Check that the code length requested is valid.
	IF (@codeLength < 4 OR (@codeLength < @PairCodeLength AND @codeLength % 2 = 1)) RETURN N'Illegal code length ' + CAST(@codeLength as NVARCHAR);

	-- Ensure that latitude and longitude are valid.
	SET @latitude = (SELECT MIN(x) FROM (VALUES ((SELECT MAX(x) FROM (VALUES (@latitude), (-@LatitudeMax)) AS value(x))), (@LatitudeMax)) AS value(x));
	WHILE (@longitude < -@LongitudeMax) SET @longitude = @longitude + @LongitudeMax * 2;
	WHILE (@longitude >= @LongitudeMax) SET @longitude = @longitude - @LongitudeMax * 2;
	
	-- Latitude 90 needs to be adjusted to be just less, so the returned code can also be decoded.
    IF (@latitude = @LatitudeMax)
	BEGIN
		DECLARE @latitudePrecission DECIMAL(9,6);
		IF (@codeLength <= @CodePrecisionNormal) SET @latitudePrecission = POWER(@EncodingBase, @codeLength / -2 + 2);
		ELSE SET @latitudePrecission = POWER(@EncodingBase, -3) / POWER(@GridRows, @codeLength - @PairCodeLength);
		SET @latitude = @latitude - 0.9 * @latitudePrecission;
	END

	-- Adjust latitude and longitude to be in positive number ranges.
	DECLARE @remainingLatitude DECIMAL(9,6) = @latitude + @LatitudeMax;
	DECLARE @remainingLongitude DECIMAL(9,6) = @longitude + @LongitudeMax;

	-- Count how many digits have been created.
    DECLARE @generatedDigits INT = 0;

    -- The precisions are initially set to ENCODING_BASE^2 because they will be immediately divided.
    DECLARE @latPrecision DECIMAL(9,6) = @EncodingBaseSquared;
    DECLARE @lngPrecision DECIMAL(9,6) = @EncodingBaseSquared;

	WHILE (@generatedDigits < @codeLength)
	BEGIN
        IF (@generatedDigits < @PairCodeLength)
		BEGIN
            -- Use the normal algorithm for the first set of digits.
            SET @latPrecision = @latPrecision / @EncodingBase;
            SET @lngPrecision = @lngPrecision / @EncodingBase;
            DECLARE @latDigit INT = FLOOR(@remainingLatitude / @latPrecision);
            DECLARE @lngDigit INT = FLOOR(@remainingLongitude / @lngPrecision);
            SET @remainingLatitude = @remainingLatitude - @latPrecision * @latDigit;
            SET @remainingLongitude = @remainingLongitude - @lngPrecision * @lngDigit;
            SET @code = @code + SUBSTRING(@CodeAlphabet, @latDigit + 1, 1);
            SET @code = @code + SUBSTRING(@CodeAlphabet, @lngDigit + 1, 1);
            SET @generatedDigits = @generatedDigits + 2;
		END
        ELSE
		BEGIN
            -- Use the 4x5 grid for remaining digits.
            SET @latPrecision = @latPrecision / @GridRows;
            SET @lngPrecision = @lngPrecision / @GridColumns;
            DECLARE @row INT = FLOOR(@remainingLatitude / @latPrecision);
            DECLARE @col INT = FLOOR(@remainingLongitude / @lngPrecision);
            SET @remainingLatitude = @remainingLatitude - @latPrecision * @row;
            SET @remainingLongitude = @remainingLongitude - @lngPrecision * @col;
            SET @code = @code + SUBSTRING(@CodeAlphabet, @row * @GridColumns + @col + 1, 1);
            SET @generatedDigits = @generatedDigits + 1;
        END;

        -- If we are at the separator position, add the separator.
        IF (@generatedDigits = @SeparatorPosition) SET @code = @code + @Separator;
    END;

    -- If the generated code is shorter than the separator position, pad the code and add the separator.
    IF (@generatedDigits < @SeparatorPosition) SET @code = @code + REPLICATE(@PaddingCharacter, @SeparatorPosition - @generatedDigits) + @Separator;

	RETURN @code;
END;
