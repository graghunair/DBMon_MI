SET NOCOUNT ON
GO
USE [dba_local]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_Managed_Instance_Response]
GO

CREATE TABLE [dbo].[tblDBMon_Managed_Instance_Response](
	[Captured_Timestamp_UTC] DATETIME NOT NULL,
	[Version] [nvarchar](128) NOT NULL,
	[UserDB_Count] [smallint] NULL,
	[SKU] [nvarchar](256) NULL,
	[HW_Generation] [nvarchar](256) NULL,
	[Virtual_Core_Count] [smallint] NULL,
	[Process_Memory_Limit_MB] [bigint] NULL,
	[Non_SOS_Memory_Gap_MB] [bigint] NULL,
	[Reserved_Storage_MB] BIGINT NOT NULL,
	[Storage_Space_Used_MB] BIGINT NOT NULL,
	[Parameters_Monitored] [nvarchar](max) NULL,
	[Script_Version] [nvarchar](max) NULL)
GO

CREATE CLUSTERED INDEX IDX_tblDBMon_Managed_Instance_Response_Captured_Timestamp_UTC ON [dbo].[tblDBMon_Managed_Instance_Response]([Captured_Timestamp_UTC] DESC)
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_MI]
GO

CREATE PROCEDURE [dbo].[uspDBMon_MI]
AS
	/*
		Author	:	Raghu Gopalakrishnan
		Date	:	3rd May 2019
		Purpose	:	This Stored Procedure is used by the DBMon tool
		Version	:	1.1
		License:
		This script is provided "AS IS" with no warranties, and confers no rights.
					EXEC [dbo].[usp_DBMon_MI]
	
		Modification History
		----------------------
		May	 3rd, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
		May  6th, 2019	:	v1.1	:	Raghu Gopalakrishnan	:	Added logic to capture SP output locally in table: [dbo].[tblDBMon_Managed_Instance_Response]
	*/

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_WARNINGS OFF

DECLARE	@varUserDBCount												SMALLINT
DECLARE @varSKU														NVARCHAR(256)
DECLARE @varHWGeneration											NVARCHAR(256)
DECLARE @varVirtual_Core_Count										INT
DECLARE @varProcess_Memory_Limit_MB									BIGINT
DECLARE @varNon_SOS_Memory_Gap_MB									BIGINT
DECLARE @varReserved_Storage_MB										BIGINT
DECLARE @varStorage_Space_Used_MB									BIGINT
DECLARE @varSPVersion												VARCHAR(15)
DECLARE @varScript_Version_JSON										NVARCHAR(MAX)
DECLARE @varParameters_Monitored_JSON								VARCHAR(MAX)
DECLARE @varPurge_tblDBMon_ERRORLOG_Days							TINYINT
DECLARE @varPurge_tblDBMon_Managed_Instance_Response_Days			TINYINT
DECLARE @varThreshold_Sys_Server_Resource_Stats_End_Time_Minutes	TINYINT
DECLARE @varSP_Name													SYSNAME

SELECT	@varPurge_tblDBMon_Managed_Instance_Response_Days = [Config_Parameter_Value]
FROM	[dbo].[tblDBMon_Config_Details] 
WHERE	[Config_Parameter] = 'Purge_tblDBMon_Managed_Instance_Response_Days'

SELECT	@varThreshold_Sys_Server_Resource_Stats_End_Time_Minutes = [Config_Parameter_Value]
FROM	[dbo].[tblDBMon_Config_Details] 
WHERE	[Config_Parameter] = 'Threshold_Sys_Server_Resource_Stats_End_Time_Minutes'

SELECT	@varUserDBCount = COUNT(1)
FROM	sys.databases 
WHERE	database_id > 4

SELECT		TOP 1
			@varSKU = [sku],
			@varHWGeneration = [hardware_generation],
			@varVirtual_Core_Count = [virtual_core_count],
			@varReserved_Storage_MB = [reserved_storage_mb],
			@varStorage_Space_Used_MB = [storage_space_used_mb]
FROM		[master].[sys].[server_resource_stats]
ORDER BY	[start_time] DESC

SELECT	@varProcess_Memory_Limit_MB = process_memory_limit_mb, 
		@varNon_SOS_Memory_Gap_MB = non_sos_mem_gap_mb 
FROM	[master].[sys].[dm_os_job_object]

EXEC [dbo].[uspDBMon_MI_Monitor_Parameters]

SET @varParameters_Monitored_JSON = (SELECT		[Parameter_Name],
												[Parameter_Value],
												[Parameter_Threshold],
												[Parameter_Alert_Flag],
												[Parameter_Value_Desc]
									FROM		[dbo].[tblDBMon_Parameters_Monitored]
									WHERE		[Is_Active] = 1 
									FOR JSON PATH, ROOT('Parameters'))

SELECT	@varSP_Name = MIN([SP_Name])
FROM	[dbo].[tblDBMon_SP_Version]

WHILE (@varSP_Name IS NOT NULL)
	BEGIN
		UPDATE	[dbo].[tblDBMon_SP_Version]
		SET		[SP_Version] = CAST(value AS VARCHAR(15)),
				[Date_Modified] = GETDATE(),
				[Modified_By] = SUSER_SNAME()
		FROM	sys.fn_listextendedproperty('Version','SCHEMA','dbo','PROCEDURE', @varSP_Name, NULL, NULL)
		WHERE	[dbo].[tblDBMon_SP_Version].[SP_Name] = @varSP_Name

		SELECT	@varSP_Name = MIN([SP_Name])
		FROM	[dbo].[tblDBMon_SP_Version]
		WHERE	@varSP_Name > [SP_Name]
	END

SET @varScript_Version_JSON = (	SELECT	[SP_Name], 
										[SP_Version],
										[Last_Executed]
								FROM	[dbo].[tblDBMon_SP_Version] Script_Version 
								FOR JSON PATH)

INSERT INTO [dbo].[tblDBMon_Managed_Instance_Response]
		([Captured_Timestamp_UTC],
		[Version],
		[UserDB_Count],
		[SKU],
		[HW_Generation],
		[Virtual_Core_Count],
		[Process_Memory_Limit_MB],
		[Non_SOS_Memory_Gap_MB],
		[Reserved_Storage_MB],
		[Storage_Space_Used_MB],
		[Parameters_Monitored],
		[Script_Version])
SELECT	GETUTCDATE() AS [Captured_Timestamp_UTC],
		CAST(SERVERPROPERTY('productversion') AS NVARCHAR(128)) AS [Version],
		@varUserDBCount AS [UserDB_Count],
		@varSKU AS [SKU],
		@varHWGeneration AS [HW_Generation],
		@varVirtual_Core_Count AS [Virtual_Core_Count],
		@varProcess_Memory_Limit_MB AS [Process_Memory_Limit_MB],
		@varNon_SOS_Memory_Gap_MB  AS [Non_SOS_Memory_Gap_MB],
		@varReserved_Storage_MB AS [Reserved_Storage_MB],
		@varStorage_Space_Used_MB AS [Storage_Space_Used_MB],
		@varParameters_Monitored_JSON AS [Parameters_Monitored],
		SUBSTRING(@varScript_Version_JSON, 2, LEN(@varScript_Version_JSON) - 2) AS [Script_Version]

DELETE	TOP (10000)
FROM	[dbo].[tblDBMon_Managed_Instance_Response]
WHERE	[Captured_Timestamp_UTC] < GETUTCDATE() - @varPurge_tblDBMon_Managed_Instance_Response_Days

DELETE	TOP (10000)
FROM	[dbo].[tblDBMon_ERRORLOG]
WHERE	[Timestamp] < GETDATE() - @varPurge_tblDBMon_ERRORLOG_Days

SELECT	TOP 1
		[Captured_Timestamp_UTC],
		CAST(SERVERPROPERTY('servername') AS  NVARCHAR(256)) AS [Managed_Instance_Name],
		[Version],
		[UserDB_Count],
		[SKU],
		[HW_Generation],
		[Virtual_Core_Count],
		[Process_Memory_Limit_MB],
		[Non_SOS_Memory_Gap_MB],
		[Reserved_Storage_MB],
		[Storage_Space_Used_MB],
		[Parameters_Monitored],
		[Script_Version]
FROM	[dbo].[tblDBMon_Managed_Instance_Response]
ORDER BY [Captured_Timestamp_UTC] DESC

UPDATE	[dbo].[tblDBMon_SP_Version]
SET		[Last_Executed] = GETDATE()
WHERE	[SP_Name] = OBJECT_NAME(@@PROCID)
GO

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[tblDBMon_SP_Version] WHERE [SP_Name] = 'uspDBMon_MI')
	BEGIN
		UPDATE	[dbo].[tblDBMon_SP_Version]
		SET		[SP_Version] = '1.1',
				[Last_Executed] = NULL,
				[Date_Modified] = GETDATE(),
				[Modified_By] = SUSER_SNAME()
		WHERE	[SP_Name] = 'uspDBMon_MI'
	END
ELSE
	BEGIN
		INSERT INTO [dbo].[tblDBMon_SP_Version] ([SP_Name], [SP_Version], [Last_Executed], [Date_Modified], [Modified_By])
		VALUES ('uspDBMon_MI', '1.1', NULL, GETDATE(), SUSER_SNAME())
	END
GO

EXEC sp_addextendedproperty 
	@name = 'Version', @value = '1.1', 
	@level0type = 'SCHEMA', @level0name = 'dbo', 
	@level1type = 'PROCEDURE', @level1name = 'uspDBMon_MI'
GO

EXEC [dbo].[uspDBMon_MI]
GO
SELECT * FROM [dbo].[tblDBMon_Parameters_Monitored]
GO
SELECT * FROM [dbo].[tblDBMon_Managed_Instance_Response]
GO
