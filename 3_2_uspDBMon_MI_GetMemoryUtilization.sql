SET NOCOUNT ON

USE [dba_local]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_MI_GetMemoryUtilization]
GO

CREATE PROCEDURE [dbo].[uspDBMon_MI_GetMemoryUtilization]
AS
	/*
		Author	:	Raghu Gopalakrishnan
		Date	:	24th May 2019
		Purpose	:	This Stored Procedure is used by the DBMon tool
		Version	:	1.0 GMU
		License:
		This script is provided "AS IS" with no warranties, and confers no rights.
					EXEC [dbo].[uspDBMon_MI_GetMemoryUtilization]
					Reference:
						https://blogs.msdn.microsoft.com/mcsukbi/2013/04/11/sql-server-page-life-expectancy/
						https://techcommunity.microsoft.com/t5/Azure-SQL-Database/Do-you-need-to-more-memory-on-Azure-SQL-Managed-Instance/ba-p/563444
						https://www.sqlskills.com/blogs/jonathan/finding-what-queries-in-the-plan-cache-use-a-specific-index/
	
		Modification History
		----------------------
		May	24th, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
	*/
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_WARNINGS OFF

DECLARE @varPLE		VARCHAR(50)
DECLARE @varMinPLE	VARCHAR(50)
DECLARE @varText	VARCHAR(2000)

--Monitor Memory 
	SELECT		@varPLE = v.cntr_value, 
				@varMinPLE = (((l.cntr_value*8/1024)/1024)/4)*300
	FROM		[sys].[dm_os_performance_counters] v
	INNER JOIN	[sys].[dm_os_performance_counters] l 
			ON	v.[object_name] = l.[object_name]
	WHERE		v.[counter_name] = 'Page Life Expectancy'
	AND			l.[counter_name] = 'Database pages'
	AND			l.[object_name] LIKE '%Buffer Node%'

	SELECT	@varText = 'PLE: ' + @varPLE + '. Expected PLE: ' + @varMinPLE + '.'

	IF (@varPLE < @varMinPLE)
		BEGIN
			UPDATE	[dbo].[tblDBMon_Parameters_Monitored]
			SET		[Parameter_Value] = CAST(@varPLE AS VARCHAR(50)),
					[Parameter_Threshold] = CAST(@varMinPLE AS VARCHAR(50)),
					[Parameter_Alert_Flag] = 1,
					[Parameter_Value_Desc] = @varText
			WHERE	[Parameter_Name] = 'Memory Utilization'

			INSERT INTO [dbo].[tblDBMon_ERRORLOG]([Timestamp], [Source], [Message],	[Alert_Flag])
			VALUES (GETDATE(), 'Memory', @varText, 1)
		END
	ELSE
		BEGIN
			UPDATE	[dbo].[tblDBMon_Parameters_Monitored]
			SET		[Parameter_Value] = CAST(@varPLE AS VARCHAR(50)),
					[Parameter_Threshold] = CAST(@varMinPLE AS VARCHAR(50)),
					[Parameter_Alert_Flag] = 0,
					[Parameter_Value_Desc] = @varText
			WHERE	[Parameter_Name] = 'Memory Utilization'	

			INSERT INTO [dbo].[tblDBMon_ERRORLOG]([Timestamp], [Source], [Message],	[Alert_Flag])
			VALUES (GETDATE(), 'Memory', @varText, 0)
		END

UPDATE	[dbo].[tblDBMon_SP_Version]
SET		[Last_Executed] = GETDATE()
WHERE	[SP_Name] = OBJECT_NAME(@@PROCID)
GO

INSERT INTO [dbo].[tblDBMon_SP_Version] ([SP_Name], [SP_Version], [Last_Executed], [Date_Modified], [Modified_By])
VALUES ('uspDBMon_MI_GetMemoryUtilization', '1.0 GMU', NULL, GETDATE(), SUSER_SNAME())
GO

EXEC sp_addextendedproperty 
		@name = 'Version', @value = '1.0 GMU', 
		@level0type = 'SCHEMA', @level0name = 'dbo', 
		@level1type = 'PROCEDURE', @level1name = 'uspDBMon_MI_GetMemoryUtilization'

GO
