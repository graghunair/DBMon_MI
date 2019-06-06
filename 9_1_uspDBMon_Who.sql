SET NOCOUNT ON
GO

USE [dba_local]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_Who]
GO
GO

CREATE PROCEDURE [dbo].[uspDBMon_Who]
@Sort_Order TINYINT = 1,
@Session_ID SMALLINT = NULL,
@Database_Name SYSNAME = NULL,
@Host_Name SYSNAME = NULL,
@Command VARCHAR(50) = NULL
AS
/*
	Author	:	Raghu Gopalakrishnan
	Date	:	18th January 2018
	Purpose	:	Return actively running requets with related data
	Version	:	1.4 W
	License:
	This script is provided "AS IS" with no warranties, and confers no rights.
				EXEC [dbo].[uspDBMon_Who]
				EXEC [dbo].[uspDBMon_Who] @varSort_Order = 1, @varDatabase_Name = NULL, @varHost_Name = NULL

	Modification History
	----------------------
	Jan  18th, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
	Jan	 23rd, 2019	:	v1.1	:	Raghu Gopalakrishnan	:	Added parameter @varCommand
	Jan	 30th, 2019	:	v1.2	:	Raghu Gopalakrishnan	:	Added column estimated_completion_time
																Removed column active_transactions
	Feb	  5th, 2019	:	v1.3	:	Raghu Gopalakrishnan	:	Added logic to filter by Session_id based on parameter input @Session_ID
																For filter based on Database_Name, changed to LIKE operator instead of '='
	Feb	 27th, 2019	:	v1.4	:	Raghu Gopalakrishnan	:	Changed CROSS APPLY to OUTER APPLY for sys.dm_exec_sql_text
																Removed the logic to filter out SQL Text = sp_server_diagnostics
*/

	SET NOCOUNT ON
	SET CONCAT_NULL_YIELDS_NULL OFF

	DECLARE		@varSQL_Text VARCHAR(MAX)

	SELECT		@varSQL_Text = 
	'SELECT		
					[des].[session_id] AS [Session ID], 
					[der].[blocking_session_id] AS [Blocked],
					[der].[percent_complete] AS [Percent Complete],				 
					DB_NAME([der].[database_id]) AS [Database Name],
					[der].[command] AS [Command], 
					[der].[status] AS [Status], 
					[des].[host_name] AS [Host Name],
					[der].[wait_type] AS [Wait Type],
					[der].[wait_time] AS [Wait Time (ms)],
					[des].[program_name] AS [Program Name], 
					CAST([der].[estimated_completion_time]/60000.0 AS INT) AS [Estimated Completion_Time (mins)],
					[der].[start_time] AS [Last Batch],
					DATEDIFF(mi, [der].[start_time], GETDATE()) AS [Duration (mins)],
					[des].[login_time] AS [Login Time], 
					[des].[login_name] AS [Login Name],
					[der].[logical_reads] AS [Logical Reads],
					[dec].[client_net_address] [Host IP Address],
					([der].[granted_query_memory] * 8) AS [Granted Query Memory (kb)],
					[dest].[text] AS [SQL Text]
	FROM			[sys].[dm_exec_requests] [der]
	INNER JOIN		[sys].[dm_exec_sessions] [des]
				ON	[der].[session_id] = [des].[session_id]
	INNER JOIN		[sys].[dm_exec_connections] [dec]
				ON	[dec].session_id = [der].[session_id]
	OUTER APPLY		[sys].[dm_exec_sql_text] ([sql_handle]) [dest]
	WHERE			[der].session_id > 50
	AND				[der].session_id <> @@SPID'


	IF (@Session_ID IS NOT NULL)
		BEGIN
			SELECT		@varSQL_Text = @varSQL_Text + ' AND [des].[session_id] = ' + CAST(@Session_ID AS VARCHAR(6))
		END
	IF (@Database_Name IS NOT NULL)
		BEGIN
			SELECT		@varSQL_Text = @varSQL_Text + ' AND DB_NAME([der].[database_id]) LIKE ''' + @Database_Name + ''''
		END
	IF (@Host_Name IS NOT NULL)
		BEGIN
			SELECT		@varSQL_Text = @varSQL_Text + ' AND [des].[host_name] LIKE ''' + @Host_Name + ''''
		END
	IF (@Command IS NOT NULL)
		BEGIN
			SELECT		@varSQL_Text = @varSQL_Text + ' AND [der].[command] LIKE ''' + @Command + ''''
		END
	IF (@Sort_Order IS NOT NULL)
		BEGIN
			SELECT	@varSQL_Text = @varSQL_Text + ' ORDER BY ' + CAST(@Sort_Order AS VARCHAR(2))
		END

	EXEC	(@varSQL_Text)

	UPDATE	[dbo].[tblDBMon_SP_Version]
	SET		[Last_Executed] = GETDATE()
	WHERE	[SP_Name] = OBJECT_NAME(@@PROCID)
GO

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[tblDBMon_SP_Version] WHERE [SP_Name] = 'uspDBMon_Who')
	BEGIN
		UPDATE	[dbo].[tblDBMon_SP_Version]
		SET		[SP_Version] = '1.4 W',
				[Last_Executed] = NULL,
				[Date_Modified] = GETDATE(),
				[Modified_By] = SUSER_SNAME()
		WHERE	[SP_Name] = 'uspDBMon_Who'
	END
ELSE
	BEGIN
		INSERT INTO [dbo].[tblDBMon_SP_Version] ([SP_Name], [SP_Version], [Last_Executed], [Date_Modified], [Modified_By])
		VALUES ('uspDBMon_Who', '1.4 W', NULL, GETDATE(), SUSER_SNAME())
	END
GO

EXEC sp_addextendedproperty 
	@name = 'Version', @value = '1.4 W', 
	@level0type = 'SCHEMA', @level0name = 'dbo', 
	@level1type = 'PROCEDURE', @level1name = 'uspDBMon_Who'
GO