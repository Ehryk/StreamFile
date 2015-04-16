
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

	StartDate datetime2 null,
	Chunks int not null default(0),
	FileSize bigint null,
	FileName nvarchar(260) null,
	FilePath nvarchar(max) null,
	EndDate datetime2 null,

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

CREATE PROCEDURE [dbo].[StreamFile_Start] 
	(@filename nvarchar(260), @overwrite int = 1, @destination nvarchar(max) = 'C:\temp\StreamFile\')
AS
BEGIN
	BEGIN TRY
		IF (@filename is null)
			SET @filename = 'StreamedFile_' + REPLACE(CONVERT(VARCHAR(20), SYSDATETIME(), 20), ' ', '_')
		
		DECLARE @tmppath nvarchar(max)
		SET @tmppath = @destination + @filename + '.tmp'

		DECLARE @Inserted TABLE (StreamedFileID int)

		EXEC dbo.CreateFile @tmppath
		
		INSERT INTO StreamedFiles (StartDate, FileSize, Chunks, FileName, FilePath)
		OUTPUT inserted.StreamedFileID INTO @Inserted
		VALUES (SYSDATETIME(), 0, 0, @filename, @tmppath)

		SELECT * FROM StreamedFiles sf INNER JOIN @Inserted i on sf.StreamedFileID = i.StreamedFileID
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

CREATE PROCEDURE [dbo].[StreamFile_AddText]
	(@fileID int, @chunk nvarchar(max))
AS
BEGIN
	BEGIN TRY
		DECLARE @tmppath nvarchar(max)
		SELECT @tmppath = FilePath FROM StreamedFiles WHERE StreamedFileID = @fileID

		IF (@tmppath is null)
			RAISERROR (N'Invalid StreamedFileID Provided: %d', -- Message text.
					   11, -- Severity.
					   1, -- State.
					   @fileID);

		EXEC dbo.AppendText @tmppath, @chunk

		UPDATE StreamedFiles SET Chunks = Chunks + 1, FileSize = FileSize + LEN(@chunk) WHERE StreamedFileID = @fileID
		
		SELECT * FROM StreamedFiles sf WHERE sf.StreamedFileID = @fileID
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

CREATE PROCEDURE [dbo].[StreamFile_AddBytes]
	(@fileID int, @chunk varbinary(max))
AS
BEGIN
	BEGIN TRY
		DECLARE @tmppath nvarchar(max)
		SELECT @tmppath = FilePath FROM StreamedFiles WHERE StreamedFileID = @fileID

		IF (@tmppath is null)
			RAISERROR (N'Invalid StreamedFileID Provided: %d', -- Message text.
					   11, -- Severity.
					   1, -- State.
					   @fileID);

		EXEC dbo.AppendBytes @tmppath, @chunk

		UPDATE StreamedFiles SET Chunks = Chunks + 1, FileSize = FileSize + LEN(@chunk) WHERE StreamedFileID = @fileID
		
		SELECT * FROM StreamedFiles sf WHERE sf.StreamedFileID = @fileID
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

CREATE PROCEDURE [dbo].[StreamFile_End] 
	(@fileID int)
AS
BEGIN
	BEGIN TRY
		DECLARE @tmppath nvarchar(max), @path nvarchar(max)
		SELECT @tmppath = FilePath FROM StreamedFiles WHERE StreamedFileID = @fileID
		SELECT @path = LEFT(@tmppath, LEN(@tmppath)-4) 

		IF (@tmppath is null)
			RAISERROR (N'Invalid StreamedFileID Provided: %d', -- Message text.
					   11, -- Severity.
					   1, -- State.
					   @fileID);
	
		EXEC dbo.DeleteFile @path
		EXEC dbo.RenameFile @tmppath, @path
	
		UPDATE StreamedFiles 
		SET EndDate = SYSDATETIME(), FilePath = @path, Complete = 1
		WHERE StreamedFileID = @fileID
		
		SELECT * FROM StreamedFiles sf WHERE sf.StreamedFileID = @fileID
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

CREATE PROCEDURE [dbo].[StreamFile_Cleanup] 
	(@timeout_min int = 30, @force bit = 1)
AS
BEGIN
	BEGIN TRY
		--Select open files that have not been updated since the timeout (stale)
		DECLARE sf_cursor CURSOR FOR  
		SELECT StreamedFileID, FilePath
		FROM StreamedFiles
		WHERE 
			EndDate is null AND
			DATEDIFF(minute, SYSDATETIME(), UpdateDate) > @timeout_min

		DECLARE @fso int, @fileID int, @tmppath int
		DECLARE @ret int, @src varchar(255), @desc varchar(255)

		OPEN sf_cursor   
		FETCH NEXT FROM sf_cursor INTO @fileID, @tmppath
			
		WHILE @@FETCH_STATUS = 0   
		BEGIN   
			EXEC dbo.DeleteFile @tmppath
	
			UPDATE StreamedFiles 
			SET EndDate = SYSDATETIME(), Complete = 0
			WHERE StreamedFileID = @fileID

			FETCH NEXT FROM sf_cursor INTO @fileID, @tmppath
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

GRANT EXECUTE ON [dbo].[StreamFile_Start] TO StreamFile
GRANT EXECUTE ON [dbo].[StreamFile_AddText] TO StreamFile
GRANT EXECUTE ON [dbo].[StreamFile_AddBytes] TO StreamFile
GRANT EXECUTE ON [dbo].[StreamFile_End] TO StreamFile
GRANT EXECUTE ON [dbo].[StreamFile_Cleanup] TO StreamFile

GO

USE master
GO

CREATE USER StreamFile FOR LOGIN StreamFile;
GO

ALTER DATABASE StreamFile SET TRUSTWORTHY ON;
GO

USE StreamFile
GO
