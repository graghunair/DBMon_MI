SET NOCOUNT ON

USE [dba_local]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_PLE]
GO

CREATE TABLE [dbo].[tblDBMon_PLE](
	[Date_Captured] [DATETIME] NOT NULL,
	[PLE] [BIGINT] NULL,
	[Expected_PLE] [BIGINT] NULL)
GO

CREATE CLUSTERED INDEX IDX_tblDBMon_PLE_Date_Captured ON [dbo].[tblDBMon_PLE]([Date_Captured])
ALTER TABLE [dbo].[tblDBMon_PLE] ADD CONSTRAINT [DF_tblDBMon_Config_Details_Date_Captured]  DEFAULT (GETDATE()) FOR [Date_Captured]
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_MI_GetMemoryUtilization]
GO

CREATE PROCEDURE [dbo].[uspDBMon_MI_GetMemoryUtilization]
AS
	/*
		Author	:	Raghu Gopalakrishnan
		Date	:	24th May 2019
		Purpose	:	This Stored Procedure is used by the DBMon tool
		Version	:	1.1 GMU
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
		Jun  5th, 2019	:	v1.1	:	Raghu Gopalakrishnan	:	Modified logic to monitor PLE. Insted of current PLE, reviewing it over a time threshold
	*/
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF


DECLARE @varPLE			BIGINT
DECLARE @varMinPLE		BIGINT
DECLARE @varText		VARCHAR(2000)
DECLARE @varPLE_Minutes TINYINT

SELECT	@varPLE_Minutes = [Config_Parameter_Value]
FROM	[dbo].[tblDBMon_Config_Details] 
WHERE	[Config_Parameter] = 'Threshold_PLE_Minutes'

--Monitor Memory 
	SELECT		@varPLE = AVG([PLE]),	
				@varMinPLE = AVG([Expected_PLE])
	FROM		[dbo].[tblDBMon_PLE]
	WHERE		[Date_Captured] > DATEADD(mi, -@varPLE_Minutes, GETDATE())

	SELECT	@varText = 'PLE: ' + CAST(@varPLE AS VARCHAR(30)) + '. Expected PLE: ' + CAST(@varMinPLE AS VARCHAR(30)) + '. Time Threshold: ' + CAST(@varPLE_Minutes AS VARCHAR(5)) + ' mins.'

	IF (@varPLE < @varMinPLE)
		BEGIN
			UPDATE	[dbo].[tblDBMon_Parameters_Monitored]
			SET		[Parameter_Value] = CAST(@varPLE AS VARCHAR(30)),
					[Parameter_Threshold] = CAST(@varMinPLE AS VARCHAR(30)),
					[Parameter_Alert_Flag] = 1,
					[Parameter_Value_Desc] = @varText
			WHERE	[Parameter_Name] = 'Memory Utilization'

			INSERT INTO [dbo].[tblDBMon_ERRORLOG]([Timestamp], [Source], [Message],	[Alert_Flag])
			VALUES (GETDATE(), 'Memory', @varText, 1)
		END
	ELSE
		BEGIN
			UPDATE	[dbo].[tblDBMon_Parameters_Monitored]
			SET		[Parameter_Value] = CAST(@varPLE AS VARCHAR(30)),
					[Parameter_Threshold] = CAST(@varMinPLE AS VARCHAR(30)),
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

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[tblDBMon_SP_Version] WHERE [SP_Name] = 'uspDBMon_MI_GetMemoryUtilization')
	BEGIN
		UPDATE	[dbo].[tblDBMon_SP_Version]
		SET		[SP_Version] = '1.1 GMU',
				[Last_Executed] = NULL,
				[Date_Modified] = GETDATE(),
				[Modified_By] = SUSER_SNAME()
		WHERE	[SP_Name] = 'uspDBMon_MI_GetMemoryUtilization'
	END
ELSE
	BEGIN
		INSERT INTO [dbo].[tblDBMon_SP_Version] ([SP_Name], [SP_Version], [Last_Executed], [Date_Modified], [Modified_By])
		VALUES ('uspDBMon_MI_GetMemoryUtilization', '1.1 GMU', NULL, GETDATE(), SUSER_SNAME())
	END
GO

EXEC sp_addextendedproperty 
		@name = 'Version', @value = '1.1 GMU', 
		@level0type = 'SCHEMA', @level0name = 'dbo', 
		@level1type = 'PROCEDURE', @level1name = 'uspDBMon_MI_GetMemoryUtilization'
GO
