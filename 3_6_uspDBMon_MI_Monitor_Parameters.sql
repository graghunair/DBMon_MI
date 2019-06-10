SET NOCOUNT ON

USE [dba_local]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_MI_Monitor_Parameters]
GO

CREATE PROCEDURE [dbo].[uspDBMon_MI_Monitor_Parameters]
AS
	/*
		Author	:	Raghu Gopalakrishnan
		Date	:	6th May 2019
		Purpose	:	This Stored Procedure is used by the DBMon tool
		Version	:	1.3 MP
		License:
		This script is provided "AS IS" with no warranties, and confers no rights.
					EXEC [dbo].[uspDBMon_MI_Monitor_Parameters]
	
		Modification History
		----------------------
		May	 6th, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
		May	10th, 2019	:	v1.1	:	Raghu Gopalakrishnan	:	Added Transaction Log Monitoring
		May	24th, 2019	:	v1.2	:	Raghu Gopalakrishnan	:	Added Memory Monitoring
		May 31st, 2019	:	v1.3	:	Raghu Gopalakrishnan	:	Added Filegroup Monitoring
	*/
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_WARNINGS OFF

--Monitor CPU 
	EXEC [dbo].[uspDBMon_MI_GetCPUUtilization]
--Monitor Memory
	EXEC [dbo].[uspDBMon_MI_GetMemoryUtilization]
--Monitor MI Storage
	EXEC [dbo].[uspDBMon_MI_GetStorageUtilization]
--Monitor Filegroup Free Space
	EXEC [dbo].[uspDBMon_MI_GetFilegroupUtilization]
--Monitor Transaction Log Free Space
	EXEC [dbo].[uspDBMon_MI_GetTLogUtilization]

UPDATE	[dbo].[tblDBMon_SP_Version]
SET		[Last_Executed] = GETDATE()
WHERE	[SP_Name] = OBJECT_NAME(@@PROCID)
GO

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[tblDBMon_SP_Version] WHERE [SP_Name] = 'uspDBMon_MI_Monitor_Parameters')
	BEGIN
		UPDATE	[dbo].[tblDBMon_SP_Version]
		SET		[SP_Version] = '1.3 MP',
				[Last_Executed] = NULL,
				[Date_Modified] = GETDATE(),
				[Modified_By] = SUSER_SNAME()
		WHERE	[SP_Name] = 'uspDBMon_MI_Monitor_Parameters'
	END
ELSE
	BEGIN
		INSERT INTO [dbo].[tblDBMon_SP_Version] ([SP_Name], [SP_Version], [Last_Executed], [Date_Modified], [Modified_By])
		VALUES ('uspDBMon_MI_Monitor_Parameters', '1.3 MP', NULL, GETDATE(), SUSER_SNAME())
	END
GO

EXEC sp_addextendedproperty 
	@name = 'Version', @value = '1.3 MP', 
	@level0type = 'SCHEMA', @level0name = 'dbo', 
	@level1type = 'PROCEDURE', @level1name = 'uspDBMon_MI_Monitor_Parameters'
GO

EXEC [dbo].[uspDBMon_MI_TrackDBAChanges] 'Installed SP: uspDBMon_MI_Monitor_Parameters'
GO