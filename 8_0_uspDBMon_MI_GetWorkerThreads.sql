SET NOCOUNT ON

USE [dba_local]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_DM_OS_WorkerThreads]
GO

CREATE TABLE [dbo].[tblDBMon_DM_OS_WorkerThreads](
	[Date_Captured] [datetime] NOT NULL,
	[Threads_Count] [INT] NULL,
	[Workers_Count] [SMALLINT] NULL,
	[Tasks_Count] [SMALLINT] NULL,
	[Captured_By] [SYSNAME] NOT NULL
)
GO

ALTER TABLE [dbo].[tblDBMon_DM_OS_WorkerThreads] ADD CONSTRAINT DF_tblDBMon_DM_OS_WorkerThreads_Captured_By DEFAULT (SUSER_SNAME()) FOR [Captured_By]
ALTER TABLE [dbo].[tblDBMon_DM_OS_WorkerThreads] ADD CONSTRAINT DF_tblDBMon_DM_OS_WorkerThreads_Date_Captured DEFAULT (GETDATE()) FOR [Date_Captured]

CREATE CLUSTERED INDEX [IDX_tblDBMon_DM_OS_WorkerThreads] ON [dbo].[tblDBMon_DM_OS_WorkerThreads]([Date_Captured] ASC)
GO

IF EXISTS (SELECT 1 FROM [dbo].[tblDBMon_Config_Details] WHERE Config_Parameter = 'Purge_tblDBMon_DM_OS_WorkerThreads_Days')
	BEGIN
		UPDATE [dbo].[tblDBMon_Config_Details] SET [Config_Parameter_Value] = 30 WHERE [Config_Parameter] = 'Purge_tblDBMon_DM_OS_WorkerThreads_Days'
	END
ELSE	
	BEGIN
		INSERT INTO [dbo].[tblDBMon_Config_Details] ([Config_Parameter], [Config_Parameter_Value]) VALUES ('Purge_tblDBMon_DM_OS_WorkerThreads_Days', 30)
	END
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_MI_GetWorkerThreads]
GO

CREATE PROCEDURE [dbo].[uspDBMon_MI_GetWorkerThreads]
AS
/*
	Author	:	Raghu Gopalakrishnan
	Date	:	6th June 2019
	Purpose	:	This Stored Procedure is used by the DBMon tool
	Version	:	1.0 GWT
	License:
	This script is provided "AS IS" with no warranties, and confers no rights.
				EXEC [dbo].[uspDBMon_MI_GetWorkerThreads]
				SELECT TOP 10 * FROM [dbo].[tblDBMon_DM_OS_WorkerThreads]
	
	Modification History
	----------------------
	Jun	 6th, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
*/
	
SET NOCOUNT ON

DECLARE @varPurge_tblDBMon_DM_OS_WorkerThreads_Days SMALLINT

INSERT INTO [dbo].[tblDBMon_DM_OS_WorkerThreads] ([Threads_Count], [Workers_Count], [Tasks_Count])
SELECT	
			(SELECT COUNT(1) AS [Threads_Count] FROM sys.dm_os_threads) AS [Threads_Count],
			(SELECT COUNT(1) AS [Threads_Count] FROM sys.dm_os_workers) AS [Workers_Count],
			(SELECT COUNT(1) AS [Threads_Count] FROM sys.dm_os_tasks) AS [Tasks_Count]

SELECT	@varPurge_tblDBMon_DM_OS_WorkerThreads_Days = [Config_Parameter_Value] 
FROM	[dbo].[tblDBMon_Config_Details] 
WHERE	[Config_Parameter] = 'Purge_tblDBMon_DM_OS_WorkerThreads_Days'

DELETE	TOP (10000) 
FROM	[dbo].[tblDBMon_DM_OS_WorkerThreads]
WHERE	[Date_Captured] < (GETDATE() - @varPurge_tblDBMon_DM_OS_WorkerThreads_Days)

UPDATE	[dbo].[tblDBMon_SP_Version]
SET		[Last_Executed] = GETDATE()
WHERE	[SP_Name] = OBJECT_NAME(@@PROCID)
GO

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[tblDBMon_SP_Version] WHERE [SP_Name] = 'uspDBMon_MI_GetWorkerThreads')
	BEGIN
		UPDATE	[dbo].[tblDBMon_SP_Version]
		SET		[SP_Version] = 'GWT',
				[Last_Executed] = NULL,
				[Date_Modified] = GETDATE(),
				[Modified_By] = SUSER_SNAME()
		WHERE	[SP_Name] = 'uspDBMon_MI_GetWorkerThreads'
	END
ELSE
	BEGIN
		INSERT INTO [dbo].[tblDBMon_SP_Version] ([SP_Name], [SP_Version], [Last_Executed], [Date_Modified], [Modified_By])
		VALUES ('uspDBMon_MI_GetWorkerThreads', 'GWT', NULL, GETDATE(), SUSER_SNAME())
	END
GO

EXEC sp_addextendedproperty 
	@name = 'Version', @value = 'GWT', 
	@level0type = 'SCHEMA', @level0name = 'dbo', 
	@level1type = 'PROCEDURE', @level1name = 'uspDBMon_MI_GetWorkerThreads'
GO
