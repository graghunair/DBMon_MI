SET NOCOUNT ON

USE [dba_local]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_MI_GetDBTLogUtilization]
GO

CREATE PROCEDURE [dbo].[uspDBMon_MI_GetDBTLogUtilization]
AS
	/*
		Author	:	Raghu Gopalakrishnan
		Date	:	10th May 2019
		Purpose	:	This Stored Procedure is used by the DBMon tool
		Version	:	1.0 GTLU
		License:
		This script is provided "AS IS" with no warranties, and confers no rights.
					EXEC [dbo].[uspDBMon_MI_GetDBTLogUtilization]
	
		Modification History
		----------------------
		May	 10th, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
	*/
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_WARNINGS OFF

DECLARE	@varThreshold_Mail_TLog_Utilization_Percentage	TINYINT
DECLARE	@varThreshold_Pager_TLog_Utilization_Percentage	TINYINT
DECLARE @varMail_Recepients VARCHAR(MAX)
DECLARE @varCounter	SMALLINT
DECLARE @varDatabase_Name SYSNAME
DECLARE @varSPID SMALLINT
DECLARE @varTableHTML VARCHAR(MAX)
DECLARE @varMailSubject NVARCHAR(255)
DECLARE @varTLog_Utilization_Percentage VARCHAR(6)
DECLARE @varDatabase_With_TLog_Utilization SYSNAME

--Table variable to store the output of DBCC SQLPERF(LOGSPACE)
DECLARE	@tblSQLPerf TABLE	(
	[ID]				SMALLINT,
	[Database_Name]		SYSNAME,
	[Log_Size_MB]		DECIMAL(12,2), 
	[Log_Space_Used%]	DECIMAL(10,2), 
	[Status]			BIT)
		
DECLARE  @tblOpenTran TABLE ( 
	C1 VARCHAR(200),
	C2 VARCHAR(2000) )
		
DECLARE @tblTranInfo TABLE (
	[SPID]			SMALLINT,
	[Database_Name]	SYSNAME, 
	[Host_Name]		VARCHAR(128),
	[Login_Name]	VARCHAR(128), 
	[Last_Batch]	DATETIME,
	[CMD]			VARCHAR(16),
	[SQLText]		VARCHAR(2000))

--Use the configuration value stored in the table dba_local.dbo.tblDBMon_Config_Details
--Pick threshold for Transaction log monitoring
SELECT	@varThreshold_Mail_TLog_Utilization_Percentage = CAST([Config_Parameter_Value] AS TINYINT)
FROM	[dbo].[tblDBMon_Config_Details]
WHERE	[Config_Parameter] = 'Threshold_Mail_TLog_Utilization_Percentage'

SELECT	@varThreshold_Pager_TLog_Utilization_Percentage = CAST([Config_Parameter_Value] AS TINYINT)
FROM	[dbo].[tblDBMon_Config_Details]
WHERE	[Config_Parameter] = 'Threshold_Pager_TLog_Utilization_Percentage'

--Capture the value of Transaction Log usage
INSERT INTO @tblSQLPerf([Database_Name], [Log_Size_MB], [Log_Space_Used%], [Status])
EXEC('dbcc sqlperf(logspace) with no_infomsgs')

--Pick the smaller value of the 2 thresholds
IF (@varThreshold_Pager_TLog_Utilization_Percentage < @varThreshold_Mail_TLog_Utilization_Percentage)
	BEGIN
		SET @varThreshold_Mail_TLog_Utilization_Percentage = @varThreshold_Pager_TLog_Utilization_Percentage
	END
		
SELECT		TOP 1
			@varTLog_Utilization_Percentage = [Log_Space_Used%],
			@varDatabase_With_TLog_Utilization = 'DB:' + [Database_Name]
					+ '; Log_Size_MB:' + CAST([Log_Size_MB] as varchar(20))  
					+ '; Log_Space_Used%:' + CAST([Log_Space_Used%] as varchar(7)) 
					+ '; Log Reuse Wait Desc:' + [log_reuse_wait_desc] 
					+ '; Recovery Model:' + [recovery_model_desc] COLLATE database_default
FROM		@tblSQLPerf a
INNER JOIN	[sys].[databases] b
		ON	a.[Database_Name] = b.[name] COLLATE database_default
WHERE		[Log_Space_Used%] >= @varThreshold_Mail_TLog_Utilization_Percentage  
ORDER BY	[Log_Space_Used%] DESC

IF EXISTS (SELECT 1 FROM @tblSQLPerf WHERE [Log_Space_Used%] >= @varThreshold_Mail_TLog_Utilization_Percentage)
	BEGIN
		--Database(s) exceed the threshold. Need to Alert!.
		-- Get the Pager/Mail recepient details
		IF EXISTS (SELECT 1 FROM @tblSQLPerf WHERE [Log_Space_Used%] >= @varThreshold_Mail_TLog_Utilization_Percentage)
			BEGIN
				SELECT	@varMail_Recepients = Config_Parameter_Value
				FROM	[dbo].[tblDBMon_Config_Details]
				WHERE	[Config_Parameter] = 'DBA_Mail'
			END
						
		IF EXISTS (SELECT 1 FROM @tblSQLPerf WHERE [Log_Space_Used%] >= @varThreshold_Pager_TLog_Utilization_Percentage)
			BEGIN
				SELECT	@varMail_Recepients = @varMail_Recepients + ';' + Config_Parameter_Value
				FROM	[dbo].[tblDBMon_Config_Details]
				WHERE	[Config_Parameter] = 'DBA_Pager'
			END
					
		SELECT		@varCounter = MIN(b.database_id)
		FROM		@tblSQLPerf a
		INNER JOIN	[sys].[databases] b
				ON	a.[Database_Name] = b.[name] COLLATE database_default
		WHERE		[Log_Space_Used%] >= @varThreshold_Mail_TLog_Utilization_Percentage  
		AND			b.[log_reuse_wait_desc] = 'ACTIVE_TRANSACTION'
					
		WHILE (@varCounter IS NOT NULL)
			BEGIN
				SELECT	@varDatabase_Name = [name]
				FROM	[sys].[databases]
				WHERE	database_id = @varCounter 
							
				DELETE FROM @tblOpenTran
	
				INSERT INTO @tblOpenTran 
				EXEC ('dbcc opentran(''' + @varDatabase_Name + ''') WITH TABLERESULTS, NO_INFOMSGS')
							
				SELECT	@varSPID = C2  
				FROM	@tblOpenTran 
				WHERE	C1 = 'OLDACT_SPID'
							
				INSERT INTO @tblTranInfo ([SPID], [Database_Name], [Host_Name],[Login_Name], [Last_Batch], [CMD], [SQLText])
				SELECT		a.spid, DB_NAME(a.[dbid]), a.hostname, a.loginame, a.last_batch , a.cmd, SUBSTRING(b.[text],0,2000)
				FROM		[sys].[sysprocesses] a
				CROSS APPLY	[sys].[dm_exec_sql_text]([sql_handle]) b
				WHERE		spid = @varSPID
							
				SELECT		@varCounter = MIN(b.database_id)
				FROM		@tblSQLPerf a
				INNER JOIN	[sys].[databases] b
						ON	a.[Database_Name] = b.[name] COLLATE database_default
				WHERE		[Log_Space_Used%] >= @varThreshold_Mail_TLog_Utilization_Percentage  
				AND			b.[log_reuse_wait_desc] = 'ACTIVE_TRANSACTION'
				AND			b.database_id > @varCounter 
			END

		INSERT INTO [dbo].[tblDBMon_ERRORLOG] ([Source], [Message], [Alert_Flag] ) 
		SELECT		'TLog', 'DB:' + [Database_Name]
					+ '; Log_Size_MB:' + CAST([Log_Size_MB] as varchar(20))  
					+ '; Log_Space_Used%:' + CAST([Log_Space_Used%] as varchar(7)) 
					+ '; Log Reuse Wait Desc:' + [log_reuse_wait_desc] 
					+ '; Recovery Model:' + [recovery_model_desc] COLLATE database_default,
					1
		FROM		@tblSQLPerf a
		INNER JOIN	[sys].[databases] b
				ON	a.[Database_Name] = b.[name] COLLATE database_default
		WHERE		[Log_Space_Used%] >= @varThreshold_Mail_TLog_Utilization_Percentage  
		ORDER BY	[Log_Space_Used%] DESC
					
		UPDATE	[dbo].[tblDBMon_Parameters_Monitored]
		SET		[Parameter_Value] = @varTLog_Utilization_Percentage,
				[Parameter_Threshold] = CAST(@varThreshold_Mail_TLog_Utilization_Percentage AS VARCHAR(5)) + '%',
				[Parameter_Alert_Flag] = 1,
				[Parameter_Value_Desc] = @varDatabase_With_TLog_Utilization
		WHERE	[Parameter_Name] = 'Transaction Log Freespace Percent'

		--Build HTML string to send mail
		SET @varTableHTML =
			N'<H1>Monitor Transaction Log</H1>' +
			N'<table border="1">' +
			N'<tr><th>Server_Name</th><th>DB_Name</th>' +
			N'<th>Log_Size_MB</th><th>Log_Space_Used%</th>' +
			N'<th>Log_Reuse_Wait_Desc</th><th>Recovery_Model</th></tr>' +
			CAST ( (	SELECT		td = SERVERPROPERTY('servername'), ''
									, td = [Database_Name], '' 
									, td = [Log_Size_MB], ''
									, td = [Log_Space_Used%], ''
									, td = [log_reuse_wait_desc], ''
									, td = [recovery_model_desc] 
						FROM		@tblSQLPerf a
						INNER JOIN	[sys].[databases] b
								ON	a.[Database_Name] = b.[name] COLLATE database_default
						WHERE		[Log_Space_Used%] >= @varThreshold_Mail_TLog_Utilization_Percentage
						ORDER BY	[Log_Size_MB] DESC
						FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) ) +	N'</table>' 
						
		IF EXISTS (SELECT TOP 1 1 FROM @tblTranInfo)
			BEGIN
				SET @varTableHTML = @varTableHTML + 
					N'<H2>Active Transaction Details</H2>' +
					N'<table border="1">' +
					N'<tr><th>SPID</th><th>DB_Name</th>' +
					N'<th>Host_Name</th><th>Login_Name</th>' +
					N'<th>Last_Batch</th><th>Command</th><th>SQLText</th></tr>' +
					CAST ( (	SELECT		td = [SPID], ''
											, td = [Database_Name], '' 
											, td = [Host_Name], ''
											, td = [Login_Name], ''
											, td = REPLACE([Last_Batch],' ','_'), ''
											, td = [CMD], ''
											, td = [SQLText] 
								FROM		@tblTranInfo
								ORDER BY	[Database_Name]
								FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) ) +	N'</table>' 
				END

		SELECT @varMailSubject = '[TLog_SpaceUsage]: ' + CAST(SERVERPROPERTY('servername') as varchar(255)) + ' Transaction Log utilization exceeds threshold of ' + CAST(@varThreshold_Mail_TLog_Utilization_Percentage AS VARCHAR(5)) + '%'
		--EXEC msdb.dbo.sp_send_dbmail @recipients=@varMail_Recepients,
			--@subject = @varMailSubject,
			--@body = @varTableHTML,
			--@body_format = 'HTML',
			--@exclude_query_output = 1
	END
ELSE
	BEGIN
		--All Databases within the threshold. No Alert to be sent.
		--PRINT 'Transaction log usage of all database within threshold specified.'
		INSERT INTO [dbo].[tblDBMon_ERRORLOG]
		([Source], [Message] )
		VALUES ('TLog', 'Transaction log usage of all databases are within threshold specified') 

		UPDATE	[dbo].[tblDBMon_Parameters_Monitored]
		SET		[Parameter_Value] = @varTLog_Utilization_Percentage,
				[Parameter_Threshold] = CAST(@varThreshold_Mail_TLog_Utilization_Percentage AS VARCHAR(5)) + '%',
				[Parameter_Alert_Flag] = 0,
				[Parameter_Value_Desc] = @varDatabase_With_TLog_Utilization
		WHERE	[Parameter_Name] = 'Transaction Log Freespace Percent'
	END

UPDATE	[dbo].[tblDBMon_SP_Version]
SET		[Last_Executed] = GETDATE()
WHERE	[SP_Name] = OBJECT_NAME(@@PROCID)
GO

INSERT INTO [dbo].[tblDBMon_SP_Version] ([SP_Name], [SP_Version], [Last_Executed], [Date_Modified], [Modified_By])
VALUES ('uspDBMon_MI_GetDBTLogUtilization', '1.0 GTLU', NULL, GETDATE(), SUSER_SNAME())
GO

EXEC sp_addextendedproperty 
	@name = 'Version', @value = '1.0 GTLU', 
	@level0type = 'SCHEMA', @level0name = 'dbo', 
	@level1type = 'PROCEDURE', @level1name = 'uspDBMon_MI_GetDBTLogUtilization'
GO