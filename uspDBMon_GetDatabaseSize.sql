SET NOCOUNT ON

USE [dba_local]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_Database_Size]
GO
CREATE TABLE [dbo].[tblDBMon_Database_Size](
	[Database_Name]		[nvarchar](128) NULL,
	[File_Name]			[sysname] NOT NULL,
	[Filegroup_Name]	[sysname] NOT NULL,
	[Type]				[varchar](10) NOT NULL,
	[Current_Size_MB]	[int] NULL,
	[Used_Space_MB]		[int] NULL,
	[Free_Space_MB]		[int] NULL,
	[Physical_Name]		[nvarchar](260) NOT NULL,
	[Date_Captured]		[datetime] NOT NULL
)
GO

ALTER TABLE [dbo].[tblDBMon_Database_Size] ADD  CONSTRAINT [DF_tblDBMon_Database_Size_Date_Captured]  DEFAULT (getdate()) FOR [Date_Captured]
CREATE CLUSTERED INDEX [IDX_tblDBMon_Database_Size] ON [dbo].[tblDBMon_Database_Size]([Date_Captured])
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_GetDatabaseSize]
GO

CREATE proc [dbo].[uspDBMon_GetDatabaseSize]
AS
	/*
		Author	:	Raghu Gopalakrishnan
		Date	:	30th May 2019
		Purpose	:	This Stored Procedure is used by the DBMon tool
		Version	:	1.0 GDBS
		License:
		This script is provided "AS IS" with no warranties, and confers no rights.
					EXEC [dbo].[uspDBMon_GetDatabaseSize]
					SELECT * FROM [dbo].[tblDBMon_Database_Size]
	
		Modification History
		----------------------
		May	30th, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
	*/

SET NOCOUNT ON

--Variable declarations
DECLARE @varDatabase_ID		SMALLINT
DECLARE @varDatabase_Name	SYSNAME
DECLARE @SQLText			VARCHAR(MAX)

--Loop trough each database to capture the space details
SELECT	@varDatabase_ID = MIN([database_id]) 
FROM	[sys].[databases]
WHERE	[state] = 0
AND		[database_id] <> 2
	
WHILE(@varDatabase_ID IS NOT NULL)
	BEGIN
		SELECT	@varDatabase_Name = [name] 
		FROM	[sys].[databases]  
		WHERE	[database_id] = @varDatabase_ID 
				
		SELECT @SQLText = 
		'USE [' + @varDatabase_Name + '] ' +
		'INSERT INTO [dba_local].[dbo].[tblDBMon_Database_Size]
						([Database_Name]
						,[File_Name]
						,[Filegroup_Name]
						,[Type]
						,[Current_Size_MB]
						,[Used_Space_MB]
						,[Free_Space_MB]
						,[Physical_Name]) 
        SELECT			''' + @varDatabase_Name + ''',
						a.[name],
						ISNULL(b.[name], ''TLOG'') ,
						a.[type] ,
						[size]/128.0,
						([size]/128.0) - ([size]/128.0 - CAST(FILEPROPERTY(a.[name] , ''SpaceUsed'') as int)/128.0),
						[size]/128.0 - CAST(FILEPROPERTY(a.[name] , ''SpaceUsed'') as int)/128.0,
						[physical_Name] 
		FROM			[sys].[database_files] a
		LEFT OUTER JOIN [sys].[filegroups] b
					ON	a.data_space_id = b.data_space_id 
		ORDER BY		a.[type], b.[name]'
			
		EXEC ( @SQLText )
			
		EXEC [dbo].[uspDBMon_GetTableSizes] @Database_Name = @varDatabase_Name

		SELECT	@varDatabase_ID = MIN([database_id]) 
		FROM	[sys].[databases]
		WHERE	[state] = 0
		AND		[database_id] <> 2
		AND		[database_id] > @varDatabase_ID	
	END

--Purge date older than 31 days. We will retain data for Wednesdays and Sundays for date older than 1 month.	
DELETE FROM [dbo].[tblDBMon_Database_Size]
WHERE		Date_Captured < (GETDATE() - 31)
AND			DATEPART(dw, Date_Captured) NOT IN (1,4)

DELETE FROM [dbo].[tblDBMon_Database_Size]
WHERE		Date_Captured < (GETDATE() - 31)
AND			DATEPART(dw, Date_Captured) NOT IN (1,4)

UPDATE	[dbo].[tblDBMon_SP_Version]
SET		Last_Executed = GETDATE()
WHERE	SP_Name = OBJECT_NAME(@@PROCID)
GO

INSERT INTO [dbo].[tblDBMon_SP_Version] (SP_Name, SP_Version, Last_Executed, Date_Modified, Modified_By)
VALUES ('uspDBMon_GetDatabaseSize', '1.0 GDBS', NULL, GETDATE(), SUSER_SNAME())
GO

IF EXISTS (SELECT 1 FROM fn_listextendedproperty('Version','SCHEMA','dbo','PROCEDURE', 'uspDBMon_GetDatabaseSize', NULL, NULL))
	BEGIN
		exec sp_dropextendedproperty 
			@name = 'Version',
			@level0type = 'Schema', @level0name = 'dbo', 
			@level1type = 'PROCEDURE', @level1name = 'uspDBMon_GetDatabaseSize'
			
		exec sp_addextendedproperty 
			@name = 'Version', @value = '1.0 GDBS', 
			@level0type = 'SCHEMA', @level0name = 'dbo', 
			@level1type = 'PROCEDURE', @level1name = 'uspDBMon_GetDatabaseSize'
	END
ELSE
	BEGIN
		exec sp_addextendedproperty 
			@name = 'Version', @value = '1.0 GDBS', 
			@level0type = 'SCHEMA', @level0name = 'dbo', 
			@level1type = 'PROCEDURE', @level1name = 'uspDBMon_GetDatabaseSize'
	END
GO

