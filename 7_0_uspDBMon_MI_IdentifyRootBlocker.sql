SET NOCOUNT ON
GO
USE [dba_local]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT 1 FROM tblDBMon_Config_Details WHERE Config_Parameter = 'Blocking_Mail_Flag')
	BEGIN
		INSERT INTO [tblDBMon_Config_Details] (Config_Parameter, Config_Parameter_Value) VALUES ('Blocking_Mail_Flag', 0) 
	END
IF NOT EXISTS (SELECT 1 FROM tblDBMon_Config_Details WHERE Config_Parameter = 'Blocking_Mail_Recipients')
	BEGIN
		INSERT INTO [tblDBMon_Config_Details] (Config_Parameter, Config_Parameter_Value) VALUES ('Blocking_Mail_Recipients', 'Raghu.Gopalakrishnan@microsoft.com') 
	END
IF NOT EXISTS (SELECT 1 FROM tblDBMon_Config_Details WHERE Config_Parameter = 'Purge_tblDBMon_Root_Blocker_Days')
	BEGIN
		INSERT INTO [tblDBMon_Config_Details] (Config_Parameter, Config_Parameter_Value) VALUES ('Purge_tblDBMon_Root_Blocker_Days', 30) 
	END
IF NOT EXISTS (SELECT 1 FROM tblDBMon_Config_Details WHERE Config_Parameter = 'Blocking_Threshold_Seconds')
	BEGIN
		INSERT INTO [tblDBMon_Config_Details] (Config_Parameter, Config_Parameter_Value) VALUES ('Blocking_Threshold_Seconds', 0) 
	END

DROP TABLE IF EXISTS[dbo].[tblDBMon_Root_Blocker]
GO

CREATE TABLE [dbo].[tblDBMon_Root_Blocker](
	[Date_Captured] [datetime] NULL,
	[Database_Name] [nvarchar](128) NULL,
	[Session_ID] [smallint] NOT NULL,
	[Blocked_Time] [bigint] NOT NULL,
	[Command] [nvarchar](32) NOT NULL,
	[Status] [nvarchar](60) NOT NULL,
	[Login_Name] [nvarchar](128) NULL,
	[Host_Name] [nvarchar](128) NULL,
	[Program_Name] [nvarchar](128) NULL,
	[Login_Time] [datetime] NOT NULL,
	[Last_Batch] [datetime] NOT NULL,
	[Isolation_Level] [smallint] NULL,
	[SQL_handle] [varbinary](64) NOT NULL,
	[Text] [nvarchar](250) NULL,
	[Captured_By] [nvarchar](128) NULL)
GO

ALTER TABLE [dbo].[tblDBMon_Root_Blocker] ADD CONSTRAINT DF_tblDBMon_Root_Blocker_Captured_By DEFAULT (SUSER_SNAME()) FOR [Captured_By]
ALTER TABLE [dbo].[tblDBMon_Root_Blocker] ADD CONSTRAINT DF_tblDBMon_Root_Blocker_Date_Captured DEFAULT (GETDATE()) FOR [Date_Captured]

CREATE CLUSTERED INDEX [IDX_tblDBMon_Root_Blocker] ON [dbo].[tblDBMon_Root_Blocker] ([Date_Captured] ASC)
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_MI_IdentifyRootBlocker]
GO

CREATE PROC [dbo].[uspDBMon_MI_IdentifyRootBlocker]
			@varBlocking_Threshold_Seconds INT = NULL,
			@varBlocking_Mail_Recipients VARCHAR(max) = NULL,
			@varBlocking_Mail_Flag BIT = NULL
AS

/*
	Author	:	Raghu Gopalakrishnan
	Date	:	6th June 2019
	Purpose	:	This Stored Procedure is used by the DBMon tool
	Version	:	1.0 RB
	License:
	This script is provided "AS IS" with no warranties, and confers no rights.
				SELECT * FROM [dbo].[tblDBMon_Root_Blocker]
	
	Modification History
	----------------------
	Jun	 6th, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
*/
		 
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

--Variable declarations
DECLARE @varPurge_tblDBMon_Root_Blocker_Days TINYINT
DECLARE @vartableHTML VARCHAR(max)
DECLARE @varServerName NVARCHAR(128) 
DECLARE @varMail_Subject NVARCHAR(255)
DECLARE @varBlocked_Time BIGINT

IF (@varBlocking_Threshold_Seconds IS NULL)
	BEGIN
		SELECT @varBlocking_Threshold_Seconds = [Config_Parameter_Value] FROM [dbo].[tblDBMon_Config_Details] WHERE [Config_Parameter] = 'Blocking_Threshold_Seconds'
	END
  
IF EXISTS (SELECT TOP 1 1 FROM [sys].[sysprocesses] where blocked <> 0)
	BEGIN
		SELECT	@varBlocked_Time = MAX(waittime) FROM [sys].[sysprocesses] WHERE blocked <> 0

		-- INSERT INTO TBLDBMON_ROOT_BLOCKER TABLE THE INFORMATION ABOUT THE ROOT BLOCKER
		INSERT INTO [tblDBMon_Root_Blocker] 
		SELECT	
					getdate()
					,DB_NAME(s1.[dbid])
					,s1.spid
					,@varBlocked_Time
					,s1.cmd 
					,s1.[status]  
					,ltrim (rtrim (s1.loginame) ) login_name
					,ltrim (rtrim (s1.hostname) ) hostname
					,ltrim (rtrim (s1.[program_name]) ) programname
					,s1.login_time 
					,s1.last_batch
					,ss.transaction_isolation_level
					,s1.[sql_handle]
					,CASE txt.[encrypted]
						WHEN 1 THEN 'Encrypted'
						ELSE SUBSTRING(ISNULL(cast([text] AS NVARCHAR(250)), N'empty'), 0,250)
					END AS [text]
					,suser_sname()	
		FROM		sys.sysprocesses s1
		INNER JOIN	sys.sysprocesses s2
				ON	s1.spid = s2.blocked 
		INNER JOIN sys.dm_exec_sessions ss
				ON	s1.spid = ss.session_id 
		OUTER APPLY sys.dm_exec_sql_text (s1.[sql_handle]) txt
		WHERE		s1.blocked = 0
		
		-- INSERT INTO THE ERRORLOG TABLE STATING THAT A ROOT BLOCKER WAS FOUND AT THAT TIME
		INSERT INTO tblDBMon_ERRORLOG ([Source], [Message], Alert_Flag) VALUES ('Root Blocker','Root Blocker information captured in tblDBMon_Root_Blocker' , 1)

		-- SEND EMAIL
		IF EXISTS (SELECT TOP 1 1 FROM [sys].[sysprocesses] WHERE [blocked] <> 0 AND [waittime] >= (@varBlocking_Threshold_Seconds * 1000))
			BEGIN
				IF (@varBlocking_Mail_Flag IS NULL)
					BEGIN
						SELECT @varBlocking_Mail_Flag = [Config_Parameter_Value] FROM [dbo].[tblDBMon_Config_Details] WHERE [Config_Parameter] = 'Blocking_Mail_Flag'	
					END
			
				IF (@varBlocking_Mail_Flag = 1)
					BEGIN
				
						IF (@varBlocking_Mail_Recipients IS NULL)
							BEGIN
								SELECT @varBlocking_Mail_Recipients = Config_Parameter_Value FROM tblDBMon_Config_Details WHERE Config_Parameter = 'Blocking_Mail_Recipients'
							END
						-- Pick the root blocker
						SET @vartableHTML =
							N'<H1>Root Blocker</H1>' +
							N'<table border="1">' +
							N'<tr><th>DBName</th><th>SPID</th><th>CMD</th><th>Status</th>' +
							N'<th>Hostname</th><th>SQL_Text</th></tr>' +
							CAST ( (	SELECT		td = DB_NAME(s1.[dbid]), '' 
													, td = s1.spid, ''
													, td = s1.cmd, ''
													, td = s1.[status] , ''
													, td = ltrim(rtrim(s1.hostname)), ''
													, td = CASE txt.[encrypted]
																WHEN 1 THEN 'Encrypted'
																ELSE SUBSTRING(ISNULL(cast([text] as nvarchar(250)), N'empty'), 0, 250)
															END
										FROM		[sys].[sysprocesses] s1
										INNER JOIN	[sys].[sysprocesses] s2
												ON	s1.spid = s2.blocked 
										INNER JOIN [sys].[dm_exec_sessions] ss
												ON	s1.spid = ss.session_id 
										OUTER APPLY [sys].[dm_exec_sql_text] (s1.[sql_handle]) txt
										WHERE		s1.blocked = 0
										FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) ) +	N'</table>' ;

						SELECT @varServerName = CAST(SERVERPROPERTY('servername') as NVARCHAR(128))
						SELECT @varMail_Subject = '[' + @varServerName + '] Blocking Report' 

						EXEC msdb.dbo.sp_send_dbmail @recipients=@varBlocking_Mail_Recipients,
								@subject = @varMail_Subject,
								@body = @vartableHTML,
								@body_format = 'HTML',
								@exclude_query_output = 1
					END
			END
	END
ELSE
	BEGIN
		INSERT INTO tblDBMon_ERRORLOG ([Source],[Message]) VALUES ('Root Blocker','No sessions found blocked for more than ' + CAST(@varBlocking_Threshold_Seconds as varchar) + ' seconds')
	END

SELECT	@varPurge_tblDBMon_Root_Blocker_Days = [Config_Parameter_Value] 
FROM	[dbo].[tblDBMon_Config_Details]
WHERE	[Config_Parameter] = 'Purge_tblDBMon_Root_Blocker_Days'

DELETE	TOP (10000) 
FROM	[dbo].[tblDBMon_Root_Blocker] 
WHERE	Date_Captured < GETDATE() - @varPurge_tblDBMon_Root_Blocker_Days

DELETE	TOP (10000) 
FROM	[dbo].[tblDBMon_ERRORLOG] 
WHERE	[Timestamp] < GETDATE() - @varPurge_tblDBMon_Root_Blocker_Days 
AND		[Source] = 'Root Blocker'

UPDATE	[dbo].[tblDBMon_SP_Version]
SET		[Last_Executed] = GETDATE()
WHERE	[SP_Name] = OBJECT_NAME(@@PROCID)
GO

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[tblDBMon_SP_Version] WHERE [SP_Name] = 'uspDBMon_MI_IdentifyRootBlocker')
	BEGIN
		UPDATE	[dbo].[tblDBMon_SP_Version]
		SET		[SP_Version] = '1.0 RB',
				[Last_Executed] = NULL,
				[Date_Modified] = GETDATE(),
				[Modified_By] = SUSER_SNAME()
		WHERE	[SP_Name] = 'uspDBMon_MI_IdentifyRootBlocker'
	END
ELSE
	BEGIN
		INSERT INTO [dbo].[tblDBMon_SP_Version] ([SP_Name], [SP_Version], [Last_Executed], [Date_Modified], [Modified_By])
		VALUES ('uspDBMon_MI_IdentifyRootBlocker', '1.0 RB', NULL, GETDATE(), SUSER_SNAME())
	END
GO

EXEC sp_addextendedproperty 
	@name = 'Version', @value = '1.0 RB', 
	@level0type = 'SCHEMA', @level0name = 'dbo', 
	@level1type = 'PROCEDURE', @level1name = 'uspDBMon_MI_IdentifyRootBlocker'
GO
