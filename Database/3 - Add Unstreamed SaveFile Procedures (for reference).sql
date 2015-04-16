
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SaveFile_Bytes]') AND type IN (N'P', N'PC')) 
DROP PROCEDURE [dbo].[SaveFile_Bytes]
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SaveFile_Text]') AND type IN (N'P', N'PC')) 
DROP PROCEDURE [dbo].[SaveFile_Text]

GO

CREATE PROCEDURE [dbo].[SaveFile_Bytes] (@contents varbinary(max), @filename nvarchar(260) = null, @destination nvarchar(max) = 'C:\temp\StreamFile\')
AS
BEGIN
	BEGIN TRY
		IF (@filename is null)
			SET @filename = 'SentFile_' + REPLACE(CONVERT(VARCHAR(20), SYSDATETIME(), 20), ' ', '_')
		
		DECLARE @path nvarchar(max)
		SET @path = @destination + @filename

		EXEC dbo.SaveFileBytes @path, @contents
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;

		SELECT 
			@ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();

		RAISERROR (@ErrorMessage, -- Message text.
				   @ErrorSeverity, -- Severity.
				   @ErrorState -- State.
				   );
	END CATCH
END

GO

CREATE PROCEDURE [dbo].[SaveFile_Text] (@contents nvarchar(max), @filename nvarchar(260) = null, @destination nvarchar(max) = 'C:\temp\StreamFile\')
AS
BEGIN
	BEGIN TRY
		IF (@filename is null)
			SET @filename = 'SentFile_' + REPLACE(CONVERT(VARCHAR(20), SYSDATETIME(), 20), ' ', '_')
		
		DECLARE @path nvarchar(max)
		SET @path = @destination + @filename
		
		EXEC dbo.SaveFileText @path, @contents
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;

		SELECT 
			@ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();

		RAISERROR (@ErrorMessage, -- Message text.
				   @ErrorSeverity, -- Severity.
				   @ErrorState -- State.
				   );
	END CATCH
END

GO

GRANT EXECUTE ON [dbo].[SaveFile_Bytes] TO StreamFile
GRANT EXECUTE ON [dbo].[SaveFile_Text] TO StreamFile

GO
