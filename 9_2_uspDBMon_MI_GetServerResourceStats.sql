SET NOCOUNT ON
GO

USE [dba_local]
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_Server_Resource_Stats]
GO

CREATE TABLE [dbo].[tblDBMon_Server_Resource_Stats](
		[Start_Time] DATETIME,
		[End_Time] DATETIME,
		[Resource_Type] NVARCHAR(128),
		[Resource_Name] NVARCHAR(128),
		[SKU] NVARCHAR(128),
		[Hardware_Generation] NVARCHAR(128),
		[CPU_Count] INT,
		[Avg_CPU_Percent] DECIMAL(5,2),
		[Total_Storage_GB] BIGINT,
		[Used_Storage_GB] DECIMAL(20,2),
		[IOPS] BIGINT,
		[IO_Bytes_Read] BIGINT,
		[IO_Bytes_Written] BIGINT,
		[Date_Captured] DATETIME)
GO

CREATE CLUSTERED INDEX [IDX_tblDBMon_Server_Resource_Stats] ON [dbo].[tblDBMon_Server_Resource_Stats]([Start_Time])
ALTER TABLE [dbo].[tblDBMon_Server_Resource_Stats] ADD CONSTRAINT DF_tblDBMon_Server_Resource_Stats_Date_Captured DEFAULT (GETDATE()) FOR [Date_Captured]
GO

DROP PROC IF EXISTS [dbo].[uspDBMon_MI_GetServerResourceStats]
GO
CREATE PROC [dbo].[uspDBMon_MI_GetServerResourceStats]
AS
/*
	License:
	This script is provided "AS IS" with no warranties, and confers no rights.
				EXEC [dbo].[uspDBMon_MI_GetServerResourceStats]
				SELECT TOP 10 * FROM [dbo].[tblDBMon_Server_Resource_Stats]
*/

SET NOCOUNT ON

INSERT INTO [dbo].[tblDBMon_Server_Resource_Stats](
				[Start_Time],
				[End_Time],
				[Resource_Type],
				[Resource_Name],
				[SKU],
				[Hardware_Generation],
				[CPU_Count],
				[Avg_CPU_Percent],
				[Total_Storage_GB],
				[Used_Storage_GB],
				[IOPS],
				[IO_Bytes_Read],
				[IO_Bytes_Written],
				[Date_Captured])
SELECT			srs.[start_time] AS [Start_Time],
				srs.[end_time] AS [End_Time],
				srs.[resource_type] AS [Resource_Type],
				srs.[resource_name] AS [Resource_Name],
				srs.[sku] AS [SKU],
				srs.[hardware_generation] AS [Hardware_Generation],
				srs.[virtual_core_count] AS [CPU_Count],
				srs.[avg_cpu_percent] AS [Avg_CPU_Percent],
				CAST(srs.[reserved_storage_mb]/1024. AS DECIMAL(20,2)) AS [Total_Storage_GB],
				CAST(srs.[storage_space_used_mb]/1024. AS DECIMAL(20,2)) AS [Used_Storage_GB],
				srs.[io_requests] AS [IOPS],
				srs.[io_bytes_read] AS [IO_Bytes_Read],
				srs.[io_bytes_written] AS [IO_Bytes_Written],
				GETDATE()
FROM			[sys].[server_resource_stats] srs
LEFT OUTER JOIN [dbo].[tblDBMon_Server_Resource_Stats] dsrs
		ON		(srs.start_time = dsrs.Start_Time AND srs.end_time = dsrs.End_Time)
WHERE			dsrs.Start_Time IS NULL
ORDER BY		1

DELETE TOP (10000) [dbo].[tblDBMon_Server_Resource_Stats]
WHERE Date_Captured < GETDATE() - 100
GO

EXEC [dbo].[uspDBMon_MI_GetServerResourceStats]
GO

SELECT TOP 10 * FROM [dbo].[tblDBMon_Server_Resource_Stats] ORDER BY 1 DESC
SELECT TOP 10 * FROM [sys].[server_resource_stats] ORDER BY 1 DESC
GO
