SET NOCOUNT ON
GO
USE [dba_local]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_Sys_Configurations]
GO

CREATE TABLE [dbo].[tblDBMon_Sys_Configurations](
	[Date_Captured]	[datetime] NOT NULL,
	[Config_Name]	[nvarchar](35) NOT NULL,
	[Value]			[varchar](1000) NULL,
	[Value_in_Use]	[varchar](1000) NULL
)
GO

ALTER TABLE [dbo].[tblDBMon_Sys_Configurations] ADD  CONSTRAINT [DF_tblDBMon_Sys_Configurations_Date_Captured]  DEFAULT (getdate()) FOR [Date_Captured]
CREATE CLUSTERED INDEX IDX_tblDBMon_Sys_Configurations ON [dbo].[tblDBMon_Sys_Configurations]([Date_Captured])
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_MI_GetSysConfigurationsChanges]
GO

CREATE PROCEDURE [dbo].[uspDBMon_MI_GetSysConfigurationsChanges]
AS
/*
	Author	:	Raghu Gopalakrishnan
	Date	:	6th June 2019
	Purpose	:	This Stored Procedure is used by the DBMon tool
	Version	:	1.0 RB
	License:
	This script is provided "AS IS" with no warranties, and confers no rights.
				EXEC [dbo].[uspDBMon_GetSysConfigurations]
				SELECT * FROM [dbo].[tblDBMon_Sys_Configurations]
	
	Modification History
	----------------------
	Jun	 6th, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
*/
	SET NOCOUNT ON
	DECLARE @varConfig_Name NVARCHAR(35)
	DECLARE @varDate_Captured DATETIME

	--Capture config names if newly added or if we dont have history information
	INSERT INTO [dbo].[tblDBMon_Sys_Configurations](Date_Captured, Config_Name, [Value], Value_in_Use)
	SELECT	GETDATE() AS Date_Captured, 
			[name] Config_Name, 
			CAST([value] AS VARCHAR(1000)) [Value], 
			CAST(value_in_use  AS VARCHAR(1000)) Value_in_Use
	FROM	sys.configurations
	WHERE	[name] NOT IN (SELECT DISTINCT Config_Name FROM [dbo].[tblDBMon_SYS_Configurations])

	--Loop through each config to check if the value has changed since last capture
	SELECT  @varConfig_Name = MIN ([name])
	FROM	[sys].[configurations]

	WHILE (@varConfig_Name IS NOT NULL)
		BEGIN
			SELECT  @varDate_Captured = MAX(Date_Captured)
			FROM	[dbo].[tblDBMon_SYS_Configurations]
			WHERE	Config_Name = @varConfig_Name

			INSERT INTO		[dbo].[tblDBMon_Sys_Configurations](Date_Captured, Config_Name, [Value], Value_in_Use)
			SELECT			GETDATE(),
							A.[name],
							CAST(A.[value] AS VARCHAR(1000)),
							CAST(A.value_in_use AS VARCHAR(1000))
			FROM			[sys].[configurations] A
			LEFT OUTER JOIN [dbo].[tblDBMon_SYS_Configurations] B
			ON				A.[name] = B.Config_Name
			WHERE			A.[name] = @varConfig_Name
			AND				B.Date_Captured = @varDate_Captured
			AND				(CAST(A.value AS VARCHAR(1000)) <> B.Value OR CAST(A.value_in_use AS VARCHAR(1000)) <> B.Value_in_Use)

			SELECT  @varConfig_Name = MIN ([name])
			FROM	[sys].[configurations]
			WHERE	[name] > @varConfig_Name
		END

UPDATE	[dbo].[tblDBMon_SP_Version]
SET		[Last_Executed] = GETDATE()
WHERE	[SP_Name] = OBJECT_NAME(@@PROCID)
GO

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[tblDBMon_SP_Version] WHERE [SP_Name] = 'uspDBMon_MI_GetSysConfigurationsChanges')
	BEGIN
		UPDATE	[dbo].[tblDBMon_SP_Version]
		SET		[SP_Version] = '1.0 SC',
				[Last_Executed] = NULL,
				[Date_Modified] = GETDATE(),
				[Modified_By] = SUSER_SNAME()
		WHERE	[SP_Name] = 'uspDBMon_MI_GetSysConfigurationsChanges'
	END
ELSE
	BEGIN
		INSERT INTO [dbo].[tblDBMon_SP_Version] ([SP_Name], [SP_Version], [Last_Executed], [Date_Modified], [Modified_By])
		VALUES ('uspDBMon_MI_GetSysConfigurationsChanges', '1.0 SC', NULL, GETDATE(), SUSER_SNAME())
	END
GO

EXEC sp_addextendedproperty 
	@name = 'Version', @value = '1.0 SC', 
	@level0type = 'SCHEMA', @level0name = 'dbo', 
	@level1type = 'PROCEDURE', @level1name = 'uspDBMon_MI_GetSysConfigurationsChanges'
GO

USE [dba_local]
GO
EXEC [dbo].[uspDBMon_MI_TrackDBAChanges] 'Installed SP: uspDBMon_MI_GetSysConfigurationsChanges'
GO