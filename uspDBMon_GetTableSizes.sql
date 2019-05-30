SET NOCOUNT ON

USE [dba_local]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_Table_Size]
GO
CREATE TABLE [dbo].[tblDBMon_Table_Size](
	[Database_Name] [sysname] NULL,
	[Table_Name] [sysname] NOT NULL,
	[Row_Count] [varchar](20) NULL,
	[Reserved] [varchar](50) NULL,
	[Data] [varchar](50) NULL,
	[Index_Size] [varchar](50) NULL,
	[UnUsed] [varchar](50) NULL,
	[Date_Captured] [datetime] NULL
)
GO

ALTER TABLE [dbo].[tblDBMon_Table_Size] ADD  CONSTRAINT [DF_tblDBMon_Table_Size_Date_Captured]  DEFAULT (getdate()) FOR [Date_Captured]
CREATE CLUSTERED INDEX [IDX_tblDBMon_Table_Size] ON [dbo].[tblDBMon_Table_Size]([Date_Captured])
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_GetTableSize]
GO

CREATE proc [dbo].[uspDBMon_GetTableSize]
@Database_Name SYSNAME
AS
	/*
		Author	:	Raghu Gopalakrishnan
		Date	:	30th May 2019
		Purpose	:	This Stored Procedure is used by the DBMon tool
		Version	:	1.0 GTS
		License:
		This script is provided "AS IS" with no warranties, and confers no rights.
					EXEC [dbo].[uspDBMon_GetTableSize] @Database_Name = 'dba_local'
					SELECT * FROM [dbo].[tblDBMon_Table_Size]
	
		Modification History
		----------------------
		May	30th, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
	*/

SET NOCOUNT ON

--Variable declarations
DECLARE @Id INT
DECLARE @varErrorMessage VARCHAR(1000)
DECLARE @TblName VARCHAR(300)
DECLARE @SQLText VARCHAR(2000)

--Temporary table creation
CREATE TABLE [dbo].[#TblList](
						[ID]			INT IDENTITY(1,1)	NOT NULL, 
						[Table_Name]	VARCHAR(300)		NOT NULL)

CREATE TABLE [dbo].[#tblDBMon_Table_Size](
						[DB_Name]		[sysname]		NULL,
						[Table_Name]	[sysname]		NOT NULL,
						[Row_Count]		[varchar] (20)	NULL,
						[Reserved]		[varchar] (50)	NULL,
						[Data]			[varchar] (50)	NULL,
						[Index_Size]	[varchar] (50)	NULL,
						[UnUsed]		[varchar] (50)	NULL,
						[Date_Captured]	[datetime]		NOT NULL DEFAULT GETDATE()
)

IF EXISTS (SELECT TOP 1 1 FROM sys.databases WHERE [name] = @Database_Name AND [state] = 0)
	BEGIN
		--Capture list of tables in the database, passed as parameter to this SP
		SELECT @SQLText = 
				'USE [' + @Database_Name + '] ' + 
				'INSERT INTO [dbo].[#TblList]([Table_Name])
				SELECT ''['' + SCHEMA_NAME([schema_id]) + ''].['' + [name] + '']''
				FROM [sys].[tables]'

		EXEC ( @SQLText )

		--Loop trough each tables to capture the space details
		SELECT	@Id = MIN([ID]) 
		FROM	[dbo].[#TblList]

		WHILE(@Id IS NOT NULL)
			BEGIN
				SELECT @TblName = [Table_Name] FROM [dbo].[#TblList] WHERE [ID] = @Id 
				SELECT @TblName = REPLACE(@TblName, '''', '''''')
			
				SELECT @SQLText = 
				'USE [' + @Database_Name + '] ' +
				'INSERT INTO [dbo].[#tblDBMon_Table_Size] (Table_Name, Row_Count, Reserved, Data, Index_Size, UnUsed)
				EXEC sp_spaceused ''' + @TblName + ''''
			
				EXEC ( @SQLText )

				SELECT @Id = MIN([ID]) FROM [dbo].[#TblList] WHERE [ID] > @Id	
			END
	
		--Purge date older than 31 days. We will retain data for Wednesdays and Sundays for date older than 1 month.	
		DELETE FROM [dba_local].[dbo].[tblDBMon_Table_Size]
		WHERE		Date_Captured < (GETDATE() - 31)
		AND			DATEPART(dw, Date_Captured) NOT IN (1,4)

		INSERT INTO [dba_local].[dbo].[tblDBMon_Table_Size] ([Database_Name], Table_Name, Row_Count, Reserved, Data, Index_Size, UnUsed, Date_Captured)
		SELECT @Database_Name, Table_Name, Row_Count, Reserved, Data, Index_Size, UnUsed, Date_Captured FROM [dbo].[#tblDBMon_Table_Size]
	END
ELSE
	BEGIN
		SET @varErrorMessage = 'The database: ' + @Database_Name + ' does not exists or is not online.'
		RAISERROR (@varErrorMessage, 16,1)
	END

UPDATE	[dbo].[tblDBMon_SP_Version]
SET		Last_Executed = GETDATE()
WHERE	SP_Name = 'uspDBMon_GetTableSize'
GO

INSERT INTO [dbo].[tblDBMon_SP_Version] (SP_Name, SP_Version, Last_Executed, Date_Modified, Modified_By)
VALUES ('uspDBMon_GetTableSize', '1.0 GTS', NULL, GETDATE(), SUSER_SNAME())
GO

EXEC sp_addextendedproperty 
	@name = 'Version', @value = '1.0 GTS', 
	@level0type = 'SCHEMA', @level0name = 'dbo', 
	@level1type = 'PROCEDURE', @level1name = 'uspDBMon_GetTableSize'
GO
