
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

CREATE TRIGGER [dbo].[trg_StreamedFiles_Audit] ON [dbo].[StreamedFiles]
FOR INSERT, UPDATE
AS
BEGIN

	IF NOT EXISTS (SELECT 1 FROM deleted)
	BEGIN
		-- Insert
		update	StreamedFiles
		set		InsertUser = suser_sname(),
				InsertDate = sysdatetime()
		from	StreamedFiles
		join	Inserted on StreamedFiles.StreamedFileID = Inserted.StreamedFileID
	END
	ELSE
	BEGIN
		-- Update
		update	StreamedFiles
		set		UpdateUser = suser_sname(),
				UpdateDate = sysdatetime()
		from	StreamedFiles
		join	Inserted on StreamedFiles.StreamedFileID = Inserted.StreamedFileID
	END

END

GO

CREATE PROCEDURE [dbo].[StreamFile_Create] 
	(@filename nvarchar(260), @overwrite int = 1, @destination nvarchar(max) = 'C:\temp\StreamFile\')
AS
BEGIN
	BEGIN TRY
		IF (@filename is null)
			SET @filename = 'StreamedFile_' + REPLACE(CONVERT(VARCHAR(20), SYSDATETIME(), 20), ' ', '_')
		
		DECLARE @tmppath nvarchar(max)
		SET @tmppath = @destination + @filename + '.tmp'

		DECLARE @fso int, @file int
		DECLARE @ret int, @src varchar(255), @desc varchar(255)
		DECLARE @Inserted TABLE (StreamedFileID int)

		EXEC @ret = sp_OACreate 'Scripting.FileSystemObject', @fso OUT
			IF @ret <> 0 GOTO OleError
		EXEC @ret = sp_OAMethod @fso, 'CreateTextFile', @file OUT, @tmppath, @overwrite, 1
			IF @ret <> 0 GOTO OleError
		EXEC @ret = sp_OADestroy @fso
			IF @ret <> 0 GOTO OleError
		
		INSERT INTO StreamedFiles (OpenDate, FileName, FilePath)
		OUTPUT inserted.StreamedFileID INTO @Inserted
		VALUES (SYSDATETIME(), @filename, @tmppath)

		SELECT * FROM StreamedFiles sf INNER JOIN @Inserted i on sf.StreamedFileID = i.StreamedFileID
		RETURN

		OleError:
			EXEC sp_OAGetErrorInfo @fso, @src OUT, @desc OUT 
			raiserror('StreamFile_Create COM Exception 0x%x, %s, %s',16,1, @ret, @src, @desc)
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

CREATE PROCEDURE [dbo].[StreamFile_AddChunk]
	(@fileID int, @chunk nvarchar(max))
AS
BEGIN
	BEGIN TRY
		--IF (@streamFileID is null)
		--	SELECT top 1 @streamFileID = StreamedFileID FROM StreamedFiles WHERE Complete = 0 ORDER BY OpenDate desc;

		DECLARE @fso int, @file int, @tmppath nvarchar(max)
		DECLARE @ret int, @src varchar(255), @desc varchar(255)
		DECLARE @Inserted TABLE (StreamedFileID int)
		SELECT @tmppath = FilePath FROM StreamedFiles WHERE StreamedFileID = @fileID

		IF (@tmppath is null)
			RAISERROR (N'Invalid StreamedFileID Provided: %d', -- Message text.
					   11, -- Severity.
					   1, -- State.
					   @fileID);

		EXEC @ret = sp_OACreate 'Scripting.FileSystemObject', @fso OUT
			IF @ret <> 0 GOTO OleError
		EXEC @ret = sp_OAMethod @fso, 'OpenTextFile', @file OUT, @tmppath, 8, 0
			IF @ret <> 0 GOTO OleError
		EXEC @ret = sp_OAMethod @file, 'Write', NULL, @chunk
			IF @ret <> 0 GOTO OleError
		EXEC @ret = sp_OAMethod @file, 'Close'
			IF @ret <> 0 GOTO OleError
		EXEC @ret = sp_OADestroy @file
			IF @ret <> 0 GOTO OleError
		EXEC @ret = sp_OADestroy @fso
			IF @ret <> 0 GOTO OleError

		UPDATE StreamedFiles SET Chunks = Chunks + 1, FileSize = FileSize + LEN(@chunk) WHERE StreamedFileID = @fileID
		
		SELECT * FROM StreamedFiles sf WHERE sf.StreamedFileID = @fileID
		RETURN

		OleError:
			EXEC sp_OAGetErrorInfo @fso, @src OUT, @desc OUT 
			raiserror('StreamFile_AddChunk COM Exception 0x%x, %s, %s',16,1, @ret, @src, @desc)
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

CREATE PROCEDURE [dbo].[StreamFile_Close] (@fileID int)
AS
BEGIN
	BEGIN TRY
		--IF (@fileID is null)
		--	SELECT top 1 @fileID = StreamedFileID FROM StreamedFiles WHERE Complete = 0 ORDER BY OpenDate desc;

		DECLARE @fso int, @path nvarchar(max), @tmppath nvarchar(max)
		DECLARE @ret int, @src varchar(255), @desc varchar(255)
		SELECT @tmppath = FilePath FROM StreamedFiles WHERE StreamedFileID = @fileID
		SELECT @path = LEFT(@tmppath, LEN(@tmppath)-4) 

		IF (@tmppath is null)
			RAISERROR (N'Invalid StreamedFileID Provided: %d', -- Message text.
					   11, -- Severity.
					   1, -- State.
					   @fileID);
	
		EXEC sp_OACreate 'Scripting.FileSystemObject', @fso OUT
			IF @ret <> 0 GOTO OleError
		EXEC sp_OAMethod @fso, 'MoveFile', NULL, @tmppath, @path
			IF @ret <> 0 GOTO OleError
		EXEC sp_OADestroy @fso
			IF @ret <> 0 GOTO OleError
	
		UPDATE StreamedFiles 
		SET CloseDate = SYSDATETIME(), FilePath = @path, Complete = 1
		WHERE StreamedFileID = @fileID
		
		SELECT * FROM StreamedFiles sf WHERE sf.StreamedFileID = @fileID
		RETURN

		OleError:
			EXEC sp_OAGetErrorInfo @fso, @src OUT, @desc OUT 
			raiserror('StreamFile_Close COM Exception 0x%x, %s, %s',16,1, @ret, @src, @desc)
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

CREATE PROCEDURE [dbo].[StreamFile_Cleanup] (@timeout_min int = 30, @force bit = 1)
AS
BEGIN
	BEGIN TRY
		--Select open files that have not been updated since the timeout (stale)
		DECLARE sf_cursor CURSOR FOR  
		SELECT StreamedFileID, FilePath
		FROM StreamedFiles
		WHERE 
			CloseDate is null AND
			DATEDIFF(minute, SYSDATETIME(), UpdateDate) > @timeout_min

		DECLARE @fso int, @fileID int, @tmppath int
		DECLARE @ret int, @src varchar(255), @desc varchar(255)

		OPEN sf_cursor   
		FETCH NEXT FROM sf_cursor INTO @fileID, @tmppath
			
		WHILE @@FETCH_STATUS = 0   
		BEGIN   
			EXEC sp_OACreate 'Scripting.FileSystemObject', @fso OUT
				IF @ret <> 0 GOTO OleError
			EXEC sp_OAMethod @fso, 'DeleteFile', NULL, @tmppath, @force
				IF @ret <> 0 GOTO OleError
			EXEC sp_OADestroy @fso
				IF @ret <> 0 GOTO OleError
	
			UPDATE StreamedFiles 
			SET CloseDate = SYSDATETIME(), Complete = 0
			WHERE StreamedFileID = @fileID

			FETCH NEXT FROM sf_cursor INTO @fileID, @tmppath
		END
		RETURN

		OleError:
			EXEC sp_OAGetErrorInfo @fso, @src OUT, @desc OUT 
			raiserror('StreamFile_Cleanup COM Exception 0x%x, %s, %s',16,1, @ret, @src, @desc)
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

GRANT EXECUTE ON [dbo].[StreamFile_Create] TO StreamFile
GRANT EXECUTE ON [dbo].[StreamFile_AddChunk] TO StreamFile
GRANT EXECUTE ON [dbo].[StreamFile_Close] TO StreamFile
GRANT EXECUTE ON [dbo].[StreamFile_Cleanup] TO StreamFile

GO

USE master
GO

CREATE USER StreamFile FOR LOGIN StreamFile;
GO

GRANT EXECUTE ON master.sys.sp_OACreate TO StreamFile
GRANT EXECUTE ON master.sys.sp_OAGetErrorInfo TO StreamFile
GRANT EXECUTE ON master.sys.sp_OASetProperty TO StreamFile
GRANT EXECUTE ON master.sys.sp_OAMethod TO StreamFile
GRANT EXECUTE ON master.sys.sp_OADestroy TO StreamFile

GO
