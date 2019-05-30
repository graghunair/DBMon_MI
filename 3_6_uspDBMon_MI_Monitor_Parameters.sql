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
		Version	:	1.1 MP
		License:
		This script is provided "AS IS" with no warranties, and confers no rights.
					EXEC [dbo].[uspDBMon_MI_Monitor_Parameters]
	
		Modification History
		----------------------
		May	 6th, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
		May	10th, 2019	:	v1.1	:	Raghu Gopalakrishnan	:	Added Transaction Log Monitoring
		May	24th, 2019	:	v1.2	:	Raghu Gopalakrishnan	:	Added Memory Monitoring
	*/
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_WARNINGS OFF

--Monitor CPU 
EXEC [dbo].[uspDBMon_MI_GetCPUUtilization]

--Monitor Memory
EXEC [dbo].[uspDBMon_MI_GetMemoryUtilization]
--Monitor MI Storage
EXEC [dbo].[uspDBMon_MI_GetMIStorageUtilization]

--Monitor Filegroup Free Space
--Monitor Transaction Log Free Space
EXEC [dbo].[uspDBMon_MI_GetDBTLogUtilization]

UPDATE	[dbo].[tblDBMon_SP_Version]
SET		[Last_Executed] = GETDATE()
WHERE	[SP_Name] = OBJECT_NAME(@@PROCID)
GO

INSERT INTO [dbo].[tblDBMon_SP_Version] ([SP_Name], [SP_Version], [Last_Executed], [Date_Modified], [Modified_By])
VALUES ('uspDBMon_MI_Monitor_Parameters', '1.0 MP', NULL, GETDATE(), SUSER_SNAME())
GO

EXEC sp_addextendedproperty 
	@name = 'Version', @value = '1.2 MP', 
	@level0type = 'SCHEMA', @level0name = 'dbo', 
	@level1type = 'PROCEDURE', @level1name = 'uspDBMon_MI_Monitor_Parameters'
GO
