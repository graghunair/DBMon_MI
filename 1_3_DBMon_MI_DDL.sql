/*
	Author	:	Raghu Gopalakrishnan
	Date	:	10th September 2019
	Purpose	:	This script installs user tables used by the DBMon tool
	Version	:	1.0
	License:
	This script is provided "AS IS" with no warranties, and confers no rights.
	
	Modification History
	----------------------
	Jun	10th, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
*/

SET NOCOUNT ON
GO

USE [dba_local]
GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_Config_Details]
GO

CREATE TABLE [dbo].[tblDBMon_Config_Details](
	[Config_Parameter] [varchar](100) NOT NULL,
	[Config_Parameter_Value] [varchar](400) NOT NULL,
	[Updated_By] [nvarchar](256) NOT NULL,
	[Date_Updated] [datetime] NOT NULL,
 CONSTRAINT [PK_tblDBMon_Config_Details_Config_Parameter] PRIMARY KEY CLUSTERED 
(
	[Config_Parameter] ASC
))
GO

ALTER TABLE [dbo].[tblDBMon_Config_Details] ADD  CONSTRAINT [DF_tblDBMon_Config_Details_Updated_By]  DEFAULT (SUSER_SNAME()) FOR [Updated_By]
ALTER TABLE [dbo].[tblDBMon_Config_Details] ADD  CONSTRAINT [DF_tblDBMon_Config_Details_Date_Updated]  DEFAULT (GETDATE()) FOR [Date_Updated]
GO

INSERT INTO [dbo].[tblDBMon_Config_Details] ([Config_Parameter], [Config_Parameter_Value])
VALUES ('Purge_tblDBMon_ERRORLOG_Days','30')
INSERT INTO [dbo].[tblDBMon_Config_Details] ([Config_Parameter], [Config_Parameter_Value])
VALUES ('Purge_tblDBMon_Managed_Instance_Response_Days','14')
INSERT INTO [dbo].[tblDBMon_Config_Details] ([Config_Parameter], [Config_Parameter_Value])
VALUES ('Purge_tblDBMon_PLE_Days','100')
INSERT INTO [dbo].[tblDBMon_Config_Details] ([Config_Parameter], [Config_Parameter_Value])
VALUES ('Threshold_CPU_Utilization_Percentage','80')
INSERT INTO [dbo].[tblDBMon_Config_Details] ([Config_Parameter], [Config_Parameter_Value])
VALUES ('Threshold_Storage_Utilization_Percentage','80')
INSERT INTO [dbo].[tblDBMon_Config_Details] ([Config_Parameter], [Config_Parameter_Value])
VALUES ('Threshold_CPU_Utilization_Minutes','15')
INSERT INTO [dbo].[tblDBMon_Config_Details] ([Config_Parameter], [Config_Parameter_Value])
VALUES ('Threshold_PLE_Minutes','60')
INSERT INTO [dbo].[tblDBMon_Config_Details] ([Config_Parameter], [Config_Parameter_Value])
VALUES ('Threshold_Filegroup_Space_Utilization_Percentage','80')

INSERT INTO [dbo].[tblDBMon_Config_Details] ([Config_Parameter], [Config_Parameter_Value])
VALUES ('Threshold_Mail_TLog_Utilization_Percentage','80')
INSERT INTO [dbo].[tblDBMon_Config_Details] ([Config_Parameter], [Config_Parameter_Value])
VALUES ('Threshold_Pager_TLog_Utilization_Percentage','95')
INSERT INTO [dbo].[tblDBMon_Config_Details] ([Config_Parameter], [Config_Parameter_Value])
VALUES ('DBA_Mail','Raghu.Gopalakrishnan@microsoft.com; vn502i6@wal-mart.com')
INSERT INTO [dbo].[tblDBMon_Config_Details] ([Config_Parameter], [Config_Parameter_Value])
VALUES ('DBA_Pager','Raghu.Gopalakrishnan@microsoft.com; vn502i6@wal-mart.com')
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_Parameters_Monitored]
GO

CREATE TABLE [dbo].[tblDBMon_Parameters_Monitored](
	[Parameter_Name]		[varchar](100) NOT NULL,
	[Parameter_Value]		[VARCHAR](50) NULL,
	[Parameter_Threshold]	[VARCHAR](50) NULL,
	[Parameter_Alert_Flag]	[BIT] NOT NULL,
	[Parameter_Value_Desc]	[VARCHAR](2000) NULL,
	[Is_Active]				[bit] NOT NULL,
	[Is_Active_Desc]		[varchar](2000) NULL,
	[Date_Updated]			[datetime] NOT NULL,
	[Updated_By]			[nvarchar](128) NOT NULL,
 CONSTRAINT [PK_tblDBMon_Parameters_Monitored_Parameter_Name] PRIMARY KEY CLUSTERED 
(
	[Parameter_Name] ASC
))
GO

ALTER TABLE [dbo].[tblDBMon_Parameters_Monitored] ADD  CONSTRAINT [DF_tblDBMon_Parameters_Monitored_Parameter_Alert_Flag]	DEFAULT ((0)) FOR [Parameter_Alert_Flag]
ALTER TABLE [dbo].[tblDBMon_Parameters_Monitored] ADD  CONSTRAINT [DF_tblDBMon_Parameters_Monitored_Is_Active]				DEFAULT ((1)) FOR [Is_Active]
ALTER TABLE [dbo].[tblDBMon_Parameters_Monitored] ADD  CONSTRAINT [DF_tblDBMon_Parameters_Monitored_Date_Captured]			DEFAULT (getdate()) FOR [Date_Updated]
ALTER TABLE [dbo].[tblDBMon_Parameters_Monitored] ADD  CONSTRAINT [DF_tblDBMon_Parameters_Monitored_Updated_By]				DEFAULT (suser_sname()) FOR [Updated_By]
GO

INSERT INTO [dbo].[tblDBMon_Parameters_Monitored]([Parameter_Name]) VALUES ('CPU Utilization')
INSERT INTO [dbo].[tblDBMon_Parameters_Monitored]([Parameter_Name]) VALUES ('Memory Utilization')
INSERT INTO [dbo].[tblDBMon_Parameters_Monitored]([Parameter_Name]) VALUES ('Storage Utilization')
INSERT INTO [dbo].[tblDBMon_Parameters_Monitored]([Parameter_Name]) VALUES ('Filegroup Freespace Percent')
INSERT INTO [dbo].[tblDBMon_Parameters_Monitored]([Parameter_Name]) VALUES ('Transaction Log Freespace Percent')
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_ERRORLOG]
GO
CREATE TABLE [dbo].[tblDBMon_ERRORLOG](
	[Timestamp] [datetime] NOT NULL,
	[Source] [varchar](20) NOT NULL,
	[Message] [varchar](2000) NULL,
	[Alert_Flag] [bit] NOT NULL)
GO

ALTER TABLE [dbo].[tblDBMon_ERRORLOG] ADD  CONSTRAINT [DF_tblDBMon_ERRORLOG_Date]  DEFAULT (GETDATE()) FOR [Timestamp]
ALTER TABLE [dbo].[tblDBMon_ERRORLOG] ADD  CONSTRAINT [DF_tblDBMon_ERRORLOG_Alert_Flag]  DEFAULT ((0)) FOR [Alert_Flag]
CREATE CLUSTERED INDEX IDX_tblDBMon_ERRORLOG ON [dbo].[tblDBMon_ERRORLOG]([Timestamp])
GO

IF NOT EXISTS (SELECT TOP 1 1 FROM sys.tables WHERE [name] = 'tblDBMon_SP_Version' AND SCHEMA_NAME(schema_id) = 'dbo')
	BEGIN
		CREATE TABLE [dbo].[tblDBMon_SP_Version](
				[SP_Name]			SYSNAME,
				[SP_Version]		VARCHAR(15),
				[Last_Executed]		DATETIME,
				[Date_Modified]		DATETIME,
				[Modified_By]		NVARCHAR(128),
			CONSTRAINT [PK_tblDBMon_SP_Version] PRIMARY KEY CLUSTERED 
		(
			[SP_Name] ASC
		))
	END
GO

EXEC [dbo].[uspDBMon_MI_TrackDBAChanges] 'Installed tables: [tblDBMon_Config_Details], [tblDBMon_Parameters_Monitored], [tblDBMon_ERRORLOG], [tblDBMon_SP_Version]'
GO