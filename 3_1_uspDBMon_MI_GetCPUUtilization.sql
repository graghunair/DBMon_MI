SET NOCOUNT ON

USE [dba_local]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_MI_GetCPUUtilization]
GO

CREATE PROCEDURE [dbo].[uspDBMon_MI_GetCPUUtilization]
AS
	/*
		Author	:	Raghu Gopalakrishnan
		Date	:	6th May 2019
		Purpose	:	This Stored Procedure is used by the DBMon tool
		Version	:	1.0 GCPUU
		License:
		This script is provided "AS IS" with no warranties, and confers no rights.
					EXEC [dbo].[uspDBMon_MI_GetCPUUtilization]
	
		Modification History
		----------------------
		May	 6th, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
	*/
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_WARNINGS OFF

DECLARE @varThreshold_CPU_Utilization_Percentage	TINYINT
DECLARE @varCPU_Utilization_Percentage				DECIMAL(5,2)
DECLARE @varThreshold_CPU_Utilization_Minutes		TINYINT
DECLARE @varText									VARCHAR(2000)

--Monitor CPU 
	SELECT	@varThreshold_CPU_Utilization_Percentage = [Config_Parameter_Value]
	FROM	[dbo].[tblDBMon_Config_Details]
	WHERE	[Config_Parameter] = 'Threshold_CPU_Utilization_Percentage'

	SELECT	@varThreshold_CPU_Utilization_Minutes = [Config_Parameter_Value]
	FROM	[dbo].[tblDBMon_Config_Details]
	WHERE	[Config_Parameter] = 'Threshold_CPU_Utilization_Minutes'

	SELECT		@varCPU_Utilization_Percentage = AVG([avg_cpu_percent])
	FROM		[master].[sys].[server_resource_stats]
	WHERE		[end_time] > DATEADD(mi, -@varThreshold_CPU_Utilization_Minutes, GETUTCDATE()) 

	SELECT	@varText = 'CPU Utilization: ' + CAST(@varCPU_Utilization_Percentage AS VARCHAR(7)) + '%. Threshold: ' + CAST(@varThreshold_CPU_Utilization_Percentage AS VARCHAR(5)) + '%. Time Duration: ' + CAST(@varThreshold_CPU_Utilization_Minutes AS VARCHAR(5)) + ' mins.'

	IF (@varCPU_Utilization_Percentage >= @varThreshold_CPU_Utilization_Percentage)
		BEGIN
			UPDATE	[dbo].[tblDBMon_Parameters_Monitored]
			SET		[Parameter_Value] = CAST(@varCPU_Utilization_Percentage AS VARCHAR(7)) + '%',
					[Parameter_Threshold] = CAST(@varThreshold_CPU_Utilization_Percentage AS VARCHAR(5)) + '%',
					[Parameter_Alert_Flag] = 1,
					[Parameter_Value_Desc] = @varText
			WHERE	[Parameter_Name] = 'CPU Utilization'

			INSERT INTO [dbo].[tblDBMon_ERRORLOG]([Timestamp], [Source], [Message],	[Alert_Flag])
			VALUES (GETDATE(), 'CPU', @varText, 1)
		END
	ELSE
		BEGIN
			UPDATE	[dbo].[tblDBMon_Parameters_Monitored]
			SET		[Parameter_Value] = CAST(@varCPU_Utilization_Percentage AS VARCHAR(7)) + '%',
					[Parameter_Threshold] = CAST(@varThreshold_CPU_Utilization_Percentage AS VARCHAR(5)) + '%',
					[Parameter_Alert_Flag] = 0,
					[Parameter_Value_Desc] = @varText
			WHERE	[Parameter_Name] = 'CPU Utilization'	

			INSERT INTO [dbo].[tblDBMon_ERRORLOG]([Timestamp], [Source], [Message],	[Alert_Flag])
			VALUES (GETDATE(), 'CPU', @varText, 0)
		END
UPDATE	[dbo].[tblDBMon_SP_Version]
SET		[Last_Executed] = GETDATE()
WHERE	[SP_Name] = OBJECT_NAME(@@PROCID)
GO

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[tblDBMon_SP_Version] WHERE [SP_Name] = 'uspDBMon_MI_GetCPUUtilization')
	BEGIN
		UPDATE	[dbo].[tblDBMon_SP_Version]
		SET		[SP_Version] = '1.0 GCPUU',
				[Last_Executed] = NULL,
				[Date_Modified] = GETDATE(),
				[Modified_By] = SUSER_SNAME()
		WHERE	[SP_Name] = 'uspDBMon_MI_GetCPUUtilization'
	END
ELSE
	BEGIN
		INSERT INTO [dbo].[tblDBMon_SP_Version] ([SP_Name], [SP_Version], [Last_Executed], [Date_Modified], [Modified_By])
		VALUES ('uspDBMon_MI_GetCPUUtilization', '1.0 GCPUU', NULL, GETDATE(), SUSER_SNAME())
	END
GO

EXEC sp_addextendedproperty 
	@name = 'Version', @value = '1.0 GCPUU', 
	@level0type = 'SCHEMA', @level0name = 'dbo', 
	@level1type = 'PROCEDURE', @level1name = 'uspDBMon_MI_GetCPUUtilization'
GO
