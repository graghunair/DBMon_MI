SET NOCOUNT ON
GO
USE [dba_local]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_DM_Exec_Requests_Extended]
GO
CREATE TABLE [dbo].[tblDBMon_DM_Exec_Requests_Extended](
					[session_id] [smallint] NOT NULL,
					[blocking_session_id] [smallint] NOT NULL,
					[Database_Name] [nvarchar](128) NULL,
					[status] [nvarchar](30) NOT NULL,
					[command] [nvarchar](16) NOT NULL,
					[login_time] [datetime] NOT NULL,
					[host_name] [nvarchar](128) NULL,
					[program_name] [nvarchar](128) NULL,
					[login_name] [nvarchar](128) NOT NULL,
					[last_request_start_time] [datetime] NOT NULL,
					[sql_handle] [varbinary](64) NOT NULL,
					[plan_handle] [varbinary](64) NOT NULL,
					[text] [nvarchar](300) NULL,
					[Captured_By] [nvarchar](128) NOT NULL,
					[Date_Captured] [datetime] NOT NULL,
					[wait_time] [int] NULL,
					[wait_type] [nvarchar](120) NULL,
					[percent_complete] [real] NULL)

ALTER TABLE [dbo].[tblDBMon_DM_Exec_Requests_Extended] ADD CONSTRAINT DF_tblDBMon_DM_Exec_Requests_Extended_Captured_By DEFAULT (SUSER_SNAME()) FOR [Captured_By]
ALTER TABLE [dbo].[tblDBMon_DM_Exec_Requests_Extended] ADD CONSTRAINT DF_tblDBMon_DM_Exec_Requests_Extended_Date_Captured DEFAULT (GETDATE()) FOR [Date_Captured]

CREATE CLUSTERED INDEX [IDX_tblDBMon_DM_Exec_Requests_Extended] ON [dbo].[tblDBMon_DM_Exec_Requests_Extended] ([Date_Captured] ASC)

DROP TABLE IF EXISTS [dbo].[tblDBMon_DM_OS_Waiting_Tasks]
GO
CREATE TABLE [dbo].[tblDBMon_DM_OS_Waiting_Tasks](
					[waiting_task_address] [varbinary](8) NOT NULL,
					[session_id] [smallint] NULL,
					[exec_context_id] [int] NULL,
					[wait_duration_ms] [bigint] NULL,
					[wait_type] [nvarchar](120) NULL,
					[resource_address] [varbinary](8) NULL,
					[blocking_task_address] [varbinary](8) NULL,
					[blocking_session_id] [smallint] NULL,
					[blocking_exec_context_id] [int] NULL,
					[resource_description] [nvarchar](2048) NULL,
					[Captured_By] [nvarchar](128) NOT NULL,
					[Date_Captured] [datetime] NOT NULL)

ALTER TABLE [dbo].[tblDBMon_DM_OS_Waiting_Tasks] ADD CONSTRAINT DF_tblDBMon_DM_OS_Waiting_Tasks_Captured_By DEFAULT (SUSER_SNAME()) FOR [Captured_By]
ALTER TABLE [dbo].[tblDBMon_DM_OS_Waiting_Tasks] ADD CONSTRAINT DF_tblDBMon_DM_OS_Waiting_Tasks_Date_Captured DEFAULT (GETDATE()) FOR [Date_Captured]

CREATE CLUSTERED INDEX [IDX_tblDBMon_DM_OS_Waiting_Tasks] ON [dbo].[tblDBMon_DM_OS_Waiting_Tasks] ([Date_Captured] ASC)
GO

INSERT INTO [dbo].[tblDBMon_Config_Details] ([Config_Parameter], [Config_Parameter_Value])
VALUES ('Purge_tblDBMon_DM_Exec_Requests_Extended_Threshold_Days','10')
INSERT INTO [dbo].[tblDBMon_Config_Details] ([Config_Parameter], [Config_Parameter_Value])
VALUES ('Purge_tblDBMon_DM_OS_Waiting_Tasks_Threshold_Days','10')
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_MI_GetDMExecRequestsExtended]
GO

CREATE proc [dbo].[uspDBMon_MI_GetDMExecRequestsExtended]
AS
/*
	Author	:	Raghu Gopalakrishnan
	Date	:	6th June 2019
	Purpose	:	This Stored Procedure is used by the DBMon tool
	Version	:	1.0 GRE
	License:
	This script is provided "AS IS" with no warranties, and confers no rights.
				EXEC [dbo].[uspDBMon_MI_GetDMExecRequestsExtended]
				SELECT TOP 10 * FROM [dbo].[tblDBMon_DM_Exec_Requests_Extended]
				SELECT TOP 10 * FROM [dbo].[tblDBMon_DM_OS_Waiting_Tasks]
	
	Modification History
	----------------------
	Jun	 6th, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
*/

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

DECLARE @varPurge_tblDBMon_DM_Exec_Requests_Extended_Threshold_Days TINYINT
DECLARE @varPurge_tblDBMon_DM_OS_Waiting_Tasks_Threshold_Days TINYINT
DECLARE @varSQLText VARCHAR(8000)

SELECT	@varPurge_tblDBMon_DM_Exec_Requests_Extended_Threshold_Days = Config_Parameter_Value
FROM	[dbo].[tblDBMon_Config_Details]
WHERE	Config_Parameter = 'Purge_tblDBMon_DM_Exec_Requests_Extended_Threshold_Days'

SELECT	@varPurge_tblDBMon_DM_OS_Waiting_Tasks_Threshold_Days = Config_Parameter_Value
FROM	[dbo].[tblDBMon_Config_Details]
WHERE	Config_Parameter = 'Purge_tblDBMon_DM_OS_Waiting_Tasks_Threshold_Days'

INSERT INTO [dbo].[tblDBMon_DM_Exec_Requests_Extended]
			([session_id], 
			[blocking_session_id], 
			[Database_Name], 
			[status], 
			[command], 
			[login_time], 
			[host_name], 
			[program_name], 
			[login_name], 
			[last_request_start_time], 
			[sql_handle], 
			[plan_handle], 
			[text], 
			[Captured_By], 
			[Date_Captured], 
			[wait_time], 
			[wait_type], 
			[percent_complete])
SELECT		a.session_id, 
			a.blocking_session_id, 
			DB_NAME(a.database_id) Database_Name,
			a.[status], 
			a.command, 
			b.login_time, 
			b.host_name, 
			b.program_name, 
			b.login_name, 
			b.last_request_start_time, 
			a.[sql_handle], 
			a.plan_handle,
			substring(c.[text], 0,250), 
			suser_sname() Captured_By, 
			getdate() Date_Captured,
			[wait_time], 
			[wait_type], 
			[percent_complete]
FROM		sys.dm_exec_requests a
INNER JOIN	sys.dm_exec_sessions b
		ON	a.session_id = b.session_id
CROSS APPLY sys.dm_exec_sql_text([sql_handle]) c
WHERE		a.session_id <> @@SPID
AND			a.session_id > 50
AND			DB_NAME(a.database_id) <> 'dba_local'

DELETE TOP (10000) [dbo].[tblDBMon_DM_Exec_Requests_Extended]
WHERE Date_Captured < GETDATE() - @varPurge_tblDBMon_DM_Exec_Requests_Extended_Threshold_Days

INSERT INTO [dbo].[tblDBMon_DM_OS_Waiting_Tasks]
SELECT	waiting_task_address, 
		session_id,
		exec_context_id, 
		wait_duration_ms,
		wait_type, 
		resource_address,
		blocking_task_address, 
		blocking_session_id,
		blocking_exec_context_id, 
		resource_description,
		suser_sname() Captured_By, 
		getdate() Date_Captured
FROM	sys.dm_os_waiting_tasks
WHERE	session_id > 50 and session_ID <> @@SPID

DELETE TOP (10000) [dbo].[tblDBMon_DM_OS_Waiting_Tasks]
WHERE Date_Captured < GETDATE() - @varPurge_tblDBMon_DM_OS_Waiting_Tasks_Threshold_Days

UPDATE	[dbo].[tblDBMon_SP_Version]
SET		[Last_Executed] = GETDATE()
WHERE	[SP_Name] = OBJECT_NAME(@@PROCID)
GO

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[tblDBMon_SP_Version] WHERE [SP_Name] = 'uspDBMon_MI_GetDMExecRequestsExtended')
	BEGIN
		UPDATE	[dbo].[tblDBMon_SP_Version]
		SET		[SP_Version] = '1.0 GRE',
				[Last_Executed] = NULL,
				[Date_Modified] = GETDATE(),
				[Modified_By] = SUSER_SNAME()
		WHERE	[SP_Name] = 'uspDBMon_MI_GetDMExecRequestsExtended'
	END
ELSE
	BEGIN
		INSERT INTO [dbo].[tblDBMon_SP_Version] ([SP_Name], [SP_Version], [Last_Executed], [Date_Modified], [Modified_By])
		VALUES ('uspDBMon_MI_GetDMExecRequestsExtended', '1.0 GRE', NULL, GETDATE(), SUSER_SNAME())
	END
GO

EXEC sp_addextendedproperty 
	@name = 'Version', @value = '1.0 GRE', 
	@level0type = 'SCHEMA', @level0name = 'dbo', 
	@level1type = 'PROCEDURE', @level1name = 'uspDBMon_MI_GetDMExecRequestsExtended'
GO

USE [dba_local]
GO
EXEC [dbo].[uspDBMon_MI_TrackDBAChanges] 'Installed SP: uspDBMon_MI_GetDMExecRequestsExtended'
GO