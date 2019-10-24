SET NOCOUNT ON
GO
USE [dba_local]
GO

IF EXISTS (SELECT 1 FROM [dbo].[tblDBMon_Config_Details] WHERE [Config_Parameter] = 'Purge_tblDBMon_DM_HADR_Database_Replica_States_Days')
	BEGIN
		PRINT 'Record found in [tblDBMon_Config_Details] for purge. Updating value.'
		UPDATE [dbo].[tblDBMon_Config_Details]
		SET Config_Parameter_Value = 35
		WHERE Config_Parameter = 'Purge_tblDBMon_DM_HADR_Database_Replica_States_Days'
	END
ELSE
	BEGIN
		PRINT 'Record not found in [tblDBMon_Config_Details] for purge. Inserting value.'
		INSERT INTO tblDBMon_Config_Details(Config_Parameter, Config_Parameter_Value)
		VALUES ('Purge_tblDBMon_DM_HADR_Database_Replica_States_Days','35')
	END
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_DM_HADR_Database_Replica_States]
GO

CREATE TABLE [dbo].[tblDBMon_DM_HADR_Database_Replica_States]
(Date_Captured DATETIME,
[Database_Name] NVARCHAR(128),
is_primary_replica BIT NULL,
synchronization_state TINYINT,
synchronization_health TINYINT,
database_state TINYINT,
is_commit_participant BIT,
is_suspended BIT,
suspend_reason TINYINT,
log_send_queue_size BIGINT,
redo_queue_size BIGINT,
last_sent_time DATETIME,
last_received_time DATETIME,
last_hardened_time DATETIME,
last_redone_time DATETIME,
last_commit_time DATETIME
)
GO
CREATE CLUSTERED INDEX IDX_tblDBMon_DM_HADR_Database_Replica_States ON [dbo].[tblDBMon_DM_HADR_Database_Replica_States]([Date_Captured])
GO

INSERT INTO [dbo].[tblDBMon_DM_HADR_Database_Replica_States](
			[Date_Captured]
			, [Database_Name]
			, is_primary_replica 
			, synchronization_state
			, synchronization_health
			, database_state 
			, is_commit_participant
			, is_suspended
			, suspend_reason
			, log_send_queue_size
			, redo_queue_size
			, last_sent_time
			, last_received_time
			, last_hardened_time
			, last_redone_time
			, last_commit_time)
SELECT		GETDATE() AS [Date_Captured]
			, DB_NAME(database_id) AS [Database_Name]
			, is_primary_replica 
			, synchronization_state
			, synchronization_health
			, database_state 
			, is_commit_participant
			, is_suspended
			, suspend_reason
			, log_send_queue_size
			, redo_queue_size
			, last_sent_time
			, last_received_time
			, last_hardened_time
			, last_redone_time
			, last_commit_time
FROM		[sys].[dm_hadr_database_replica_states]
WHERE		is_local = 1
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_MI_GetDMHADRDatabaseReplicaStates]
GO

USE [dba_local]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[uspDBMon_MI_GetDMHADRDatabaseReplicaStates]
AS

/*
	Author	:	Raghu Gopalakrishnan
	Date	:	15th September 2019
	Purpose	:	This Stored Procedure is used by the DBMon tool to capture details from sys.dm_hadr_database_replica_states
	Version	:	1.0 GDRS
	License:
	This script is provided "AS IS" with no warranties, and confers no rights.
				EXEC [dbo].[uspDBMon_MI_GetDMHADRDatabaseReplicaStates]
				SELECT * FROM [dbo].[tblDBMon_DM_HADR_Database_Replica_States]
	Modification History
	----------------------
	Jul  15th, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
*/

SET NOCOUNT ON

DECLARE @varPurge_tblDBMon_DM_HADR_Database_Replica_States_Days TINYINT

--Capture sys.dm_hadr_database_replica_states 
INSERT INTO [dbo].[tblDBMon_DM_HADR_Database_Replica_States](
				[Date_Captured]
				, [Database_Name]
				, is_primary_replica 
				, synchronization_state
				, synchronization_health
				, database_state 
				, is_commit_participant
				, is_suspended
				, suspend_reason
				, log_send_queue_size
				, redo_queue_size
				, last_sent_time
				, last_received_time
				, last_hardened_time
				, last_redone_time
				, last_commit_time)
SELECT	GETDATE() AS [Date_Captured]
		, DB_NAME(database_id) AS [Database_Name]
		, is_primary_replica 
		, synchronization_state
		, synchronization_health
		, database_state 
		, is_commit_participant
		, is_suspended
		, suspend_reason
		, log_send_queue_size
		, redo_queue_size
		, last_sent_time
		, last_received_time
		, last_hardened_time
		, last_redone_time
		, last_commit_time
FROM	sys.dm_hadr_database_replica_states
WHERE	is_local = 1

SELECT	@varPurge_tblDBMon_DM_HADR_Database_Replica_States_Days = Config_Parameter_Value
FROM	[dbo].[tblDBMon_Config_Details]
WHERE	Config_Parameter like 'Purge_tblDBMon_DM_HADR_Database_Replica_States_Days'

DELETE TOP (10000)
FROM		[dbo].[tblDBMon_DM_HADR_Database_Replica_States]
WHERE		Date_Captured < GETDATE() - @varPurge_tblDBMon_DM_HADR_Database_Replica_States_Days

UPDATE	[dbo].[tblDBMon_SP_Version]
SET		[Last_Executed] = GETDATE()
WHERE	[SP_Name] = OBJECT_NAME(@@PROCID)
GO

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[tblDBMon_SP_Version] WHERE [SP_Name] = 'uspDBMon_MI_GetDMHADRDatabaseReplicaStates')
	BEGIN
		UPDATE	[dbo].[tblDBMon_SP_Version]
		SET		[SP_Version] = '1.0 GDRS',
				[Last_Executed] = NULL,
				[Date_Modified] = GETDATE(),
				[Modified_By] = SUSER_SNAME()
		WHERE	[SP_Name] = 'uspDBMon_MI_GetDMHADRDatabaseReplicaStates'
	END
ELSE
	BEGIN
		INSERT INTO [dbo].[tblDBMon_SP_Version] ([SP_Name], [SP_Version], [Last_Executed], [Date_Modified], [Modified_By])
		VALUES ('uspDBMon_MI_GetDMHADRDatabaseReplicaStates', '1.0 GDRS', NULL, GETDATE(), SUSER_SNAME())
	END
GO

EXEC sp_addextendedproperty 
	@name = 'Version', @value = '1.0 GDRS', 
	@level0type = 'SCHEMA', @level0name = 'dbo', 
	@level1type = 'PROCEDURE', @level1name = 'uspDBMon_MI_GetDMHADRDatabaseReplicaStates'
GO

EXEC [dbo].[uspDBMon_MI_GetDMHADRDatabaseReplicaStates]
GO
SELECT	* 
FROM	[dbo].[tblDBMon_DM_HADR_Database_Replica_States]
GO