SET NOCOUNT ON

USE [dba_local]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_MI_GetStorageUtilization]
GO

CREATE PROCEDURE [dbo].[uspDBMon_MI_GetStorageUtilization]
AS
	/*
		Author	:	Raghu Gopalakrishnan
		Date	:	6th May 2019
		Purpose	:	This Stored Procedure is used by the DBMon tool
		Version	:	1.0 GCPUU
		License:
		This script is provided "AS IS" with no warranties, and confers no rights.
					EXEC [dbo].[uspDBMon_MI_GetStorageUtilization]
	
		Modification History
		----------------------
		May	 6th, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
	*/
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_WARNINGS OFF

DECLARE @varThreshold_MI_Storage_Utilization_Percentage TINYINT
DECLARE @varMI_Storage_Utilization_Percentage DECIMAL(5,2)
DECLARE @varText VARCHAR(2000)

SELECT	@varThreshold_MI_Storage_Utilization_Percentage = [Config_Parameter_Value]
FROM	[dbo].[tblDBMon_Config_Details]
WHERE	[Config_Parameter] = 'Threshold_MI_Storage_Utilization_Percentage'

SELECT		TOP 1
			@varMI_Storage_Utilization_Percentage = (([storage_space_used_mb]/[reserved_storage_mb])*100)
FROM		[master].[sys].[server_resource_stats]
ORDER BY	[start_time] DESC

SELECT	@varText = 'MI Storage Utilization Percentage: ' + CAST(@varMI_Storage_Utilization_Percentage AS VARCHAR(7)) + '. Threshold: ' + CAST(@varThreshold_MI_Storage_Utilization_Percentage AS VARCHAR(5)) + '.'
IF (@varMI_Storage_Utilization_Percentage >= @varThreshold_MI_Storage_Utilization_Percentage)
	BEGIN
			UPDATE	[dbo].[tblDBMon_Parameters_Monitored]
			SET		[Parameter_Value] = CAST(@varMI_Storage_Utilization_Percentage AS VARCHAR(7)) + '%',
					[Parameter_Threshold] = CAST(@varThreshold_MI_Storage_Utilization_Percentage AS VARCHAR(5)) + '%',
					[Parameter_Alert_Flag] = 1,
					[Parameter_Value_Desc] = NULL
			WHERE	[Parameter_Name] = 'Storage Utilization'

			INSERT INTO [dbo].[tblDBMon_ERRORLOG]([Timestamp], [Source], [Message],	[Alert_Flag])
			VALUES (GETDATE(), 'Storage', @varText, 1)
	END
ELSE
	BEGIN
			UPDATE	[dbo].[tblDBMon_Parameters_Monitored]
			SET		[Parameter_Value] = CAST(@varMI_Storage_Utilization_Percentage AS VARCHAR(7)) + '%',
					[Parameter_Threshold] = CAST(@varThreshold_MI_Storage_Utilization_Percentage AS VARCHAR(5)) + '%',
					[Parameter_Alert_Flag] = 0,
					[Parameter_Value_Desc] = NULL
			WHERE	[Parameter_Name] = 'Storage Utilization'

			INSERT INTO [dbo].[tblDBMon_ERRORLOG]([Timestamp], [Source], [Message],	[Alert_Flag])
			VALUES (GETDATE(), 'Storage', @varText, 0)
	END

UPDATE	[dbo].[tblDBMon_SP_Version]
SET		[Last_Executed] = GETDATE()
WHERE	[SP_Name] = OBJECT_NAME(@@PROCID)
GO

INSERT INTO [dbo].[tblDBMon_SP_Version] ([SP_Name], [SP_Version], [Last_Executed], [Date_Modified], [Modified_By])
VALUES ('uspDBMon_MI_GetStorageUtilization', '1.0 GSTGU', NULL, GETDATE(), SUSER_SNAME())
GO

EXEC sp_addextendedproperty 
	@name = 'Version', @value = '1.0 GSTGU', 
	@level0type = 'SCHEMA', @level0name = 'dbo', 
	@level1type = 'PROCEDURE', @level1name = 'uspDBMon_MI_GetStorageUtilization'
GO
