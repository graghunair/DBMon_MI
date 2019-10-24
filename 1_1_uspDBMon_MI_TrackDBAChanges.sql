SET NOCOUNT ON

USE [master]
GO
IF NOT EXISTS (SELECT TOP 1 1 FROM sys.databases WHERE LOWER([name]) = 'dba_local')
	BEGIN
		CREATE DATABASE [dba_local]
	END
GO

USE [dba_local]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_SP_Version] 
GO

CREATE TABLE [dbo].[tblDBMon_SP_Version](
		[SP_Name]			SYSNAME,
		[SP_Version]		VARCHAR(15),
		[Last_Executed]		DATETIME,
		[Date_Modified]		DATETIME,
		[Modified_By]		NVARCHAR(128),
	CONSTRAINT [PK_tblDBMon_SP_Version] PRIMARY KEY CLUSTERED 
(
	[SP_Name] ASC
))
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_Track_DBA_Changes]
GO

CREATE TABLE [dbo].[tblDBMon_Track_DBA_Changes](
	[Date_Captured] [datetime] NULL,
	[Captured_By] [nvarchar](128) NULL,
	[Change_Text] [varchar](2000) NULL
) 
GO

ALTER TABLE [dbo].[tblDBMon_Track_DBA_Changes] ADD CONSTRAINT DF_tblDBMon_Track_DBA_Changes_Date_Captured DEFAULT (getdate()) FOR [Date_Captured]
ALTER TABLE [dbo].[tblDBMon_Track_DBA_Changes] ADD CONSTRAINT DF_tblDBMon_Track_DBA_Changes_Captured_By DEFAULT (suser_sname()) FOR [Captured_By]

CREATE CLUSTERED INDEX [IDX_tblDBMon_Track_DBA_Changes] ON [dbo].[tblDBMon_Track_DBA_Changes]([Date_Captured] ASC)
GO


DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_MI_TrackDBAChanges]
GO
	
CREATE PROCEDURE [dbo].[uspDBMon_MI_TrackDBAChanges]    
@varChangeText varchar(2000)    
AS  
/*
	Author	:	Raghu Gopalakrishnan
	Date	:	10th September 2019
	Purpose	:	This Stored Procedure is used by the DBA team to manually track changes
	Version	:	1.0 TDC
	License:
	This script is provided "AS IS" with no warranties, and confers no rights.
				SELECT TOP 10 * FROM [dbo].[tblDBMon_Track_DBA_Changes] 
	
	Modification History
	----------------------
	Jun	 10th, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
*/
SET NOCOUNT ON  

INSERT INTO [dbo].[tblDBMon_Track_DBA_Changes](Change_Text) VALUES (@varChangeText)    

UPDATE	[dbo].[tblDBMon_SP_Version]
SET		[Last_Executed] = GETDATE()
WHERE	[SP_Name] = OBJECT_NAME(@@PROCID)
GO

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[tblDBMon_SP_Version] WHERE [SP_Name] = 'uspDBMon_MI_TrackDBAChanges')
	BEGIN
		UPDATE	[dbo].[tblDBMon_SP_Version]
		SET		[SP_Version] = '1.0 TDC',
				[Last_Executed] = NULL,
				[Date_Modified] = GETDATE(),
				[Modified_By] = SUSER_SNAME()
		WHERE	[SP_Name] = 'uspDBMon_MI_TrackDBAChanges'
	END
ELSE
	BEGIN
		INSERT INTO [dbo].[tblDBMon_SP_Version] ([SP_Name], [SP_Version], [Last_Executed], [Date_Modified], [Modified_By])
		VALUES ('uspDBMon_MI_TrackDBAChanges', '1.0 TDC', NULL, GETDATE(), SUSER_SNAME())
	END
GO

EXEC sp_addextendedproperty 
	@name = 'Version', @value = '1.0 TDC', 
	@level0type = 'SCHEMA', @level0name = 'dbo', 
	@level1type = 'PROCEDURE', @level1name = 'uspDBMon_MI_TrackDBAChanges'
GO

EXEC [dbo].[uspDBMon_MI_TrackDBAChanges] 'Installed SP: [dbo].[uspDBMon_MI_TrackDBAChanges].'
GO
SELECT * FROM [dbo].[tblDBMon_Track_DBA_Changes]