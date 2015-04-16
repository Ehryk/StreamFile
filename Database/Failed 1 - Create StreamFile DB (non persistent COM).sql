
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

USE master;
IF EXISTS(SELECT name FROM master.sys.server_principals WHERE name = 'StreamFile')
	DROP LOGIN StreamFile;
IF EXISTS(SELECT * FROM sys.database_principals WHERE name = N'StreamFile')
	DROP USER StreamFile;
IF EXISTS(select * from sys.databases where name='StreamFile')
	DROP DATABASE StreamFile;

GO

CREATE DATABASE StreamFile
GO

USE StreamFile
GO

CREATE LOGIN StreamFile WITH PASSWORD = 'password', DEFAULT_DATABASE = StreamFile;
GO

CREATE USER StreamFile FOR LOGIN StreamFile;
GO

CREATE TABLE [dbo].[StreamedFiles]
(
	StreamedFileID int PRIMARY KEY IDENTITY(1,1),

	ObjectToken int null,
	OpenDate datetime2 null,
	Chunks int not null default(0),
	FileSize bigint null,
	FileName nvarchar(260) null,
	FilePath nvarchar(max) null,
	CloseDate datetime2 null,
	Complete bit not null default(0),

	InsertUser nvarchar(128) not null default(suser_sname()),
	InsertDate datetime2 not null default(SYSDATETIME()),
	UpdateUser nvarchar(128) null,
	UpdateDate datetime2 null
)

GO

CREATE TRIGGER [dbo].[trg_StreamedFiles_Insert] ON [dbo].[StreamedFiles]
FOR INSERT
AS
BEGIN

	update	StreamedFiles
	set		InsertUser = suser_sname(),
			InsertDate = sysdatetime()
	from	StreamedFiles
	join	Inserted on StreamedFiles.StreamedFileID = Inserted.StreamedFileID

END

GO

CREATE TRIGGER [dbo].[trg_StreamedFiles_Update] ON [dbo].[StreamedFiles]
FOR UPDATE
AS
BEGIN

	if update(InsertUser) or update (InsertDate)
	begin
		--Revert to original values
		update		StreamedFiles
		set 		InsertUser = Deleted.InsertUser, 
					InsertDate = Deleted.InsertDate
		from		StreamedFiles
		join		Inserted on StreamedFiles.StreamedFileID = Inserted.StreamedFileID
		join 		Deleted  on StreamedFiles.StreamedFileID = Deleted.StreamedFileID
		where		Deleted.InsertUser is not null 
		and			Deleted.InsertDate is not null
	end

	update	StreamedFiles 
	set		UpdateUser = suser_sname(),
			UpdateDate = sysdatetime()
	from	StreamedFiles
	join	Inserted on StreamedFiles.StreamedFileID = Inserted.StreamedFileID

END

GO

CREATE PROCEDURE [dbo].[StreamFile_Open]
AS
BEGIN

	BEGIN TRY
		DECLARE @ObjectToken INT, @FileStreamID INT
		DECLARE @Inserted TABLE (ID int)

		EXEC sp_OACreate 'ADODB.Stream', @ObjectToken OUTPUT
		EXEC sp_OASetProperty @ObjectToken, 'Type', 1
		EXEC sp_OAMethod @ObjectToken, 'Open'
		
		INSERT INTO StreamedFiles (OpenDate, ObjectToken)
		OUTPUT inserted.StreamedFileID INTO @Inserted
		VALUES (SYSDATETIME(), @ObjectToken)

		SELECT @ObjectToken, ID as StreamedFileID FROM @Inserted
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

CREATE PROCEDURE [dbo].[StreamFile_AddChunk] (@token int, @chunk varbinary(max), @streamID int = null)
AS
BEGIN
	BEGIN TRY
		IF (@streamID is null)
			SELECT top 1 @streamID = StreamedFileID FROM StreamedFiles WHERE ObjectToken = @token ORDER BY OpenDate desc;

		EXEC sp_OAMethod @token, 'Write', NULL, @chunk

		UPDATE StreamedFiles SET Chunks = Chunks + 1, FileSize = FileSize + LEN(@chunk) WHERE StreamedFileID = @streamID
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

CREATE PROCEDURE [dbo].[StreamFile_AddChunkText] (@token int, @chunk nvarchar(max), @streamID int = null)
AS
BEGIN
	BEGIN TRY
		IF (@streamID is null)
			SELECT top 1 @streamID = StreamedFileID FROM StreamedFiles WHERE ObjectToken = @token ORDER BY OpenDate desc;

		EXEC sp_OAMethod @token, 'WriteText', NULL, @chunk

		UPDATE StreamedFiles SET Chunks = Chunks + 1, FileSize = FileSize + LEN(@chunk) WHERE StreamedFileID = @streamID
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

CREATE PROCEDURE [dbo].[StreamFile_Close] (@token int, @filename nvarchar(260) = null, @streamID int = null, @destination nvarchar(max) = 'C:\temp\StreamFile\')
AS
BEGIN
	BEGIN TRY
		IF (@streamID is null)
			SELECT top 1 @streamID = StreamedFileID FROM StreamedFiles WHERE ObjectToken = @token ORDER BY OpenDate desc;
		IF (@filename is null)
			SET @filename = 'StreamedFile_' + REPLACE(CONVERT(VARCHAR(20), SYSDATETIME(), 20), ' ', '_')

		DECLARE @path nvarchar(max)
		SET @path = @destination + @filename

		EXEC sp_OAMethod @token, 'SaveToFile', NULL, @path, 2
		EXEC sp_OAMethod @token, 'Close'
		EXEC sp_OADestroy @token
	
		UPDATE StreamedFiles 
		SET CloseDate = SYSDATETIME(), FileName = @filename, FilePath = @path, Complete = 1
		WHERE StreamedFileID = @streamID
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

CREATE PROCEDURE [dbo].[StreamFile_Cleanup] (@timeout_min int = 30)
AS
BEGIN
	BEGIN TRY
		--Select open files that have not been updated since the timeout (stale)
		DECLARE sf_cursor CURSOR FOR  
		SELECT StreamedFileID, ObjectToken
		FROM StreamedFiles
		WHERE 
			CloseDate is null AND
			DATEDIFF(minute, SYSDATETIME(), UpdateDate) > @timeout_min

		DECLARE @streamID int, @token int

		OPEN sf_cursor   
		FETCH NEXT FROM sf_cursor INTO @streamID, @token
			
		WHILE @@FETCH_STATUS = 0   
		BEGIN   
			EXEC sp_OAMethod @token, 'Close'
			EXEC sp_OADestroy @token
	
			UPDATE StreamedFiles 
			SET CloseDate = SYSDATETIME(), Complete = 0
			WHERE StreamedFileID = @streamID

			FETCH NEXT FROM sf_cursor INTO @streamID, @token
		END
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

GRANT EXECUTE ON [dbo].[StreamFile_Open] TO StreamFile
GRANT EXECUTE ON [dbo].[StreamFile_AddChunk] TO StreamFile
GRANT EXECUTE ON [dbo].[StreamFile_AddChunkText] TO StreamFile
GRANT EXECUTE ON [dbo].[StreamFile_Close] TO StreamFile
GRANT EXECUTE ON [dbo].[StreamFile_Cleanup] TO StreamFile

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
		EXEC sp_OASetProperty @ObjectToken, 'Type', 1
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
		EXEC sp_OASetProperty @ObjectToken, 'Type', 1
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

USE master
GO

CREATE USER StreamFile FOR LOGIN StreamFile;
GO

GRANT EXECUTE ON master.sys.sp_OACreate TO StreamFile
GRANT EXECUTE ON master.sys.sp_OASetProperty TO StreamFile
GRANT EXECUTE ON master.sys.sp_OAMethod TO StreamFile
GRANT EXECUTE ON master.sys.sp_OADestroy TO StreamFile

GO
