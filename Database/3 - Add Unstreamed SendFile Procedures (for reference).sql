
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SendFile] (@contents varbinary(max), @filename nvarchar(260) = null, @destination nvarchar(max) = 'C:\temp\StreamFile\')
AS
BEGIN
	BEGIN TRY
		IF (@filename is null)
			SET @filename = 'SentFile_' + REPLACE(CONVERT(VARCHAR(20), SYSDATETIME(), 20), ' ', '_')
		
		DECLARE @path nvarchar(max)
		SET @path = @destination + @filename

		DECLARE @ObjectToken INT
		EXEC sp_OACreate 'ADODB.Stream', @ObjectToken OUTPUT
		EXEC sp_OASetProperty @ObjectToken, 'Type', 1 --1=Binary,2=Text
		EXEC sp_OAMethod @ObjectToken, 'Open'
		EXEC sp_OAMethod @ObjectToken, 'Write', NULL, @contents
		EXEC sp_OAMethod @ObjectToken, 'SaveToFile', NULL, @path, 2
		EXEC sp_OAMethod @ObjectToken, 'Close'
		EXEC sp_OADestroy @ObjectToken
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

CREATE PROCEDURE [dbo].[SendFileText] (@contents nvarchar(max), @filename nvarchar(260) = null, @destination nvarchar(max) = 'C:\temp\StreamFile\')
AS
BEGIN
	BEGIN TRY
		IF (@filename is null)
			SET @filename = 'SentFile_' + REPLACE(CONVERT(VARCHAR(20), SYSDATETIME(), 20), ' ', '_')
		
		DECLARE @path nvarchar(max)
		SET @path = @destination + @filename

		DECLARE @ObjectToken INT
		EXEC sp_OACreate 'ADODB.Stream', @ObjectToken OUTPUT
		EXEC sp_OASetProperty @ObjectToken, 'Type', 2 --1=Binary,2=Text
		EXEC sp_OAMethod @ObjectToken, 'Open'
		EXEC sp_OAMethod @ObjectToken, 'WriteText', NULL, @contents
		EXEC sp_OAMethod @ObjectToken, 'SaveToFile', NULL, @path, 2
		EXEC sp_OAMethod @ObjectToken, 'Close'
		EXEC sp_OADestroy @ObjectToken
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

GRANT EXECUTE ON [dbo].[SendFile] TO StreamFile
GRANT EXECUTE ON [dbo].[SendFileText] TO StreamFile

GO
