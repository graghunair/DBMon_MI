/*
	Author	:	Raghu Gopalakrishnan
	Date	:	10th September 2019
	Purpose	:	This script sets database size for System Databases and user database: dba_local per DBA team standards.
	Version	:	1.0
	License:
	This script is provided "AS IS" with no warranties, and confers no rights.
	
		MASTER:		DATA FILE - 250MB,	LOG FILE - 250MB, Disable Auto-Growth
		MODEL:		DATA FILE - 250MB,	LOG FILE - 250MB, Disable Auto-Growth
		MSDB:		DATA FILE - 2G,		LOG FILE - 1G, Disable Auto-Growth
		DBA_LOCAL:	DATA FILE - 5G,		LOG FILE - 2G, Disable Auto-Growth
	
	Modification History
	----------------------
	Jun	10th, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
*/

USE [master]
GO
DECLARE @DataFileSize	DECIMAL(10,2), @LogFileSize	DECIMAL(10,2)

SELECT	@DataFileSize = size/128.0 FROM	sys.database_files WHERE [type] = 0
SELECT	@LogFileSize = size/128.0 FROM	sys.database_files WHERE [type] = 1

IF (@DataFileSize < 250.00)
	BEGIN
		ALTER DATABASE [master] MODIFY FILE ( NAME = N'data_0', SIZE = 250MB, FILEGROWTH = 0)
		PRINT 'Master data file adjusted to 250 MB.'
END

IF (@LogFileSize < 250.00)
	BEGIN
		ALTER DATABASE [master] MODIFY FILE ( NAME = N'log', SIZE = 250MB, FILEGROWTH = 0)
		PRINT 'Master log file adjusted to 250 MB.'
	END

USE [model]
GO
DECLARE @DataFileSize	DECIMAL(10,2), @LogFileSize	DECIMAL(10,2)

SELECT	@DataFileSize = size/128.0 FROM	sys.database_files WHERE	[type] = 0
SELECT	@LogFileSize = size/128.0 FROM	sys.database_files WHERE	[type] = 1

IF (@DataFileSize < 250.00)
	BEGIN
		ALTER DATABASE [model] MODIFY FILE ( NAME = N'data_0', SIZE = 250MB, FILEGROWTH = 0)
		PRINT 'Model data file adjusted to 250 MB.'
	END

IF (@LogFileSize < 250.00)
	BEGIN
		ALTER DATABASE [model] MODIFY FILE ( NAME = N'log', SIZE = 250MB, FILEGROWTH = 0)
		PRINT 'Model log file adjusted to 250 MB.'
	END


USE [msdb]
GO
DECLARE @DataFileSize	DECIMAL(10,2), @LogFileSize	DECIMAL(10,2)

SELECT	@DataFileSize = size/128.0 FROM	sys.database_files WHERE	[type] = 0
SELECT	@LogFileSize = size/128.0 FROM	sys.database_files WHERE	[type] = 1

IF (@DataFileSize < 2048.00)
	BEGIN
		ALTER DATABASE [msdb] MODIFY FILE ( NAME = N'data_0', SIZE = 2GB , FILEGROWTH = 0)
		PRINT 'MSDB data file adjusted to 2 GB.'
	END

IF (@LogFileSize < 1024.00)
	BEGIN
		ALTER DATABASE [msdb] MODIFY FILE ( NAME = N'log', SIZE = 1GB , FILEGROWTH = 0)
		PRINT 'MSDB log file adjusted to 1 GB.'
	END

IF NOT EXISTS (SELECT TOP 1 1 FROM sys.databases WHERE LOWER([name]) = 'dba_local')
	BEGIN
		CREATE DATABASE [dba_local]
	END
GO

USE [dba_local]
GO
DECLARE @DataFileSize	DECIMAL(10,2), @LogFileSize	DECIMAL(10,2)

SELECT	@DataFileSize = size/128.0 FROM	sys.database_files WHERE	[type] = 0
SELECT	@LogFileSize = size/128.0 FROM	sys.database_files WHERE	[type] = 1

IF (@DataFileSize < 5120.00)
	BEGIN
		ALTER DATABASE [dba_local] MODIFY FILE ( NAME = N'data_0', SIZE = 5GB )
		PRINT 'DBA_Local data file adjusted to 5 GB.'
	END

IF (@LogFileSize < 2048.00)
	BEGIN
		ALTER DATABASE [dba_local] MODIFY FILE ( NAME = N'log', SIZE = 2GB , FILEGROWTH = 0)
		PRINT 'DBA_Local log file adjusted to 2 GB.'
	END
GO

EXEC [dbo].[uspDBMon_MI_TrackDBAChanges] 'Resized system databases and dba_local.'
GO