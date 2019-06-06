SET NOCOUNT ON

USE [dba_local]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_MI_GetFilegroupUtilization]
GO

CREATE PROCEDURE [dbo].[uspDBMon_MI_GetFilegroupUtilization]
AS
	/*
		Author	:	Raghu Gopalakrishnan
		Date	:	31st May 2019
		Purpose	:	This Stored Procedure is used by the DBMon tool
		Version	:	1.0 GFGU
		License:
		This script is provided "AS IS" with no warranties, and confers no rights.
					EXEC [dbo].[uspDBMon_MI_GetFilegroupUtilization]
					Reference:
					https://docs.microsoft.com/en-us/sql/t-sql/functions/fileproperty-transact-sql
					https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-database-files-transact-sql
					https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-filegroups-transact-sql
	
		Modification History
		----------------------
		May	 31st, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
	*/

SET NOCOUNT ON

--Variable declarations
DECLARE @varDatabase_ID		SMALLINT
DECLARE @varDatabase_Name	SYSNAME
DECLARE @SQLText			VARCHAR(MAX)
DECLARE @varThreshold_Filegroup_Space_Utilization_Percentage FLOAT
DECLARE	@varFilegroup_Space_Utilization_Percentage FLOAT
DECLARE @varDatabase_With_Filegroup_Utilization VARCHAR(2000)

DROP TABLE IF EXISTS #tblDBMon_Database_Size
CREATE TABLE #tblDBMon_Database_Size(
	[Database_Name] [nvarchar](128) NULL,
	[Filegroup_Name] [sysname] NOT NULL,
	[Current_Size_MB] [float] NULL,
	[Utilized_Size_MB] [float] NULL)

SELECT	@varThreshold_Filegroup_Space_Utilization_Percentage = [Config_Parameter_Value]
FROM	tblDBMon_Config_Details
WHERE	[Config_Parameter] = 'Threshold_Filegroup_Space_Utilization_Percentage'

--Loop trough each database to capture the space details
SELECT	@varDatabase_ID = MIN([database_id]) 
FROM	[sys].[databases]
WHERE	[state] = 0
AND		[database_id] <> 2
	
WHILE(@varDatabase_ID IS NOT NULL)
	BEGIN
		SELECT	@varDatabase_Name = [name] 
		FROM	[sys].[databases]  
		WHERE	[database_id] = @varDatabase_ID 
				
		SELECT @SQLText = 
		'USE [' + @varDatabase_Name + ']' +
				'
				INSERT INTO #tblDBMon_Database_Size([Database_Name], [Filegroup_Name], [Current_Size_MB], [Utilized_Size_MB])
				SELECT			DB_NAME() AS [Database_Name],
								b.[name] AS [Filegroup_Name],
								CAST((a.[size]/128.0) AS FLOAT) AS [Current_Size_MB],
								CAST((a.[size]/128.0) - (a.[size]/128.0 - CAST(FILEPROPERTY(a.[name] , ''SpaceUsed'') as int)/128.0)  AS FLOAT) AS [Utilized_Size_MB]
				FROM			[sys].[database_files] a
				INNER JOIN		[sys].[filegroups] b
							ON	a.data_space_id = b.data_space_id 
				WHERE			a.[type] <> 1
				AND				a.[size] <> 0'
			
		EXEC ( @SQLText )

		SELECT	@varDatabase_ID = MIN([database_id]) 
		FROM	[sys].[databases]
		WHERE	[state] = 0
		AND		[database_id] <> 2
		AND		[database_id] > @varDatabase_ID	
	END

	/* For Debugging
		SELECT	*, 
				([Utilized_Size_MB]/[Current_Size_MB])*100 AS [Free_%]
		FROM	#tblDBMon_Database_Size
	*/

IF EXISTS (SELECT TOP 1 1 FROM #tblDBMon_Database_Size WHERE CAST((([Utilized_Size_MB]/[Current_Size_MB])*100) AS FLOAT) > @varThreshold_Filegroup_Space_Utilization_Percentage)
	BEGIN
			SELECT		TOP 1 
						@varFilegroup_Space_Utilization_Percentage = (([Utilized_Size_MB]/[Current_Size_MB])*100),
						@varDatabase_With_Filegroup_Utilization = 'DB: ' + [Database_Name] + '; FG:' + [Filegroup_Name] + '; Current_Size_MB:' + CAST([Current_Size_MB] AS VARCHAR(50)) + '; Utilized_Size_MB:' + CAST([Utilized_Size_MB] AS VARCHAR(50))
			FROM		#tblDBMon_Database_Size
			ORDER BY	1 DESC

			UPDATE	[dbo].[tblDBMon_Parameters_Monitored]
			SET		[Parameter_Value] = CAST(@varFilegroup_Space_Utilization_Percentage AS VARCHAR(7)) + '%',
					[Parameter_Threshold] = CAST(@varThreshold_Filegroup_Space_Utilization_Percentage AS VARCHAR(6)) + '%',
					[Parameter_Alert_Flag] = 1,
					[Parameter_Value_Desc] = @varDatabase_With_Filegroup_Utilization
			WHERE	[Parameter_Name] = 'Filegroup Freespace Percent'

			INSERT INTO [dbo].[tblDBMon_ERRORLOG]([Timestamp], [Source], [Message],	[Alert_Flag])
			SELECT	GETDATE(),
					'Filegroup',
					'DB: ' + [Database_Name] + '; FG:' + [Filegroup_Name] + '; Current_Size_MB:' + CAST([Current_Size_MB] AS VARCHAR(50)) + '; Utilized_Size_MB:' + CAST([Utilized_Size_MB] AS VARCHAR(50)),
					1
			FROM	#tblDBMon_Database_Size
			WHERE	(([Utilized_Size_MB]/[Current_Size_MB])*100) > @varThreshold_Filegroup_Space_Utilization_Percentage
	END
ELSE
	BEGIN
			UPDATE	[dbo].[tblDBMon_Parameters_Monitored]
			SET		[Parameter_Value] = NULL,
					[Parameter_Threshold] = CAST(@varThreshold_Filegroup_Space_Utilization_Percentage AS VARCHAR(6)) + '%',
					[Parameter_Alert_Flag] = 0,
					[Parameter_Value_Desc] = NULL
			WHERE	[Parameter_Name] = 'Filegroup Freespace Percent'

			INSERT INTO [dbo].[tblDBMon_ERRORLOG]([Timestamp], [Source], [Message],	[Alert_Flag])
			VALUES (GETDATE(), 'Filegroup', 'Filegroup utilization is less than the threshold specifdied', 0)
	END

UPDATE	[dbo].[tblDBMon_SP_Version]
SET		[Last_Executed] = GETDATE()
WHERE	[SP_Name] = OBJECT_NAME(@@PROCID)
GO

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[tblDBMon_SP_Version] WHERE [SP_Name] = 'uspDBMon_MI_GetFilegroupUtilization')
	BEGIN
		UPDATE	[dbo].[tblDBMon_SP_Version]
		SET		[SP_Version] = '1.0 GFGU',
				[Last_Executed] = NULL,
				[Date_Modified] = GETDATE(),
				[Modified_By] = SUSER_SNAME()
		WHERE	[SP_Name] = 'uspDBMon_MI_GetFilegroupUtilization'
	END
ELSE
	BEGIN
		INSERT INTO [dbo].[tblDBMon_SP_Version] ([SP_Name], [SP_Version], [Last_Executed], [Date_Modified], [Modified_By])
		VALUES ('uspDBMon_MI_GetFilegroupUtilization', '1.0 GFGU', NULL, GETDATE(), SUSER_SNAME())
	END
GO

EXEC sp_addextendedproperty 
	@name = 'Version', @value = '1.0 GFGU', 
	@level0type = 'SCHEMA', @level0name = 'dbo', 
	@level1type = 'PROCEDURE', @level1name = 'uspDBMon_MI_GetFilegroupUtilization'
GO