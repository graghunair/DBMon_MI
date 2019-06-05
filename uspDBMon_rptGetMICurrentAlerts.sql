/*
	Name	:	uspDBMon_rptGetMICurrentAlerts
	Purpose	:	This script includes all the monitoring SPs and code within the DBA_DBMon_AZURE_MI database for reporting issues
	Date	:	June 5th, 2019

*/


SET NOCOUNT ON
GO

USE [DBA_DBMon_AZURE_MI]
GO
DROP TABLE IF EXISTS [load].[tblDBMon_Managed_Instances_Current_Alerts]
DROP TABLE IF EXISTS [dbo].[tblDBMon_Managed_Instances_Current_Alerts]
DROP TABLE IF EXISTS [dbo].[tblDBMon_Managed_Instance_Incident_Tickets]
DROP TABLE IF EXISTS [dbo].[tblDBMon_Managed_Instances_Alert_Category]
GO

CREATE TABLE [dbo].[tblDBMon_Managed_Instances_Alert_Category](
	[Alert_Category_ID] TINYINT IDENTITY(1,1) NOT NULL,
	[Alert_Category_Name] [varchar](50) NOT NULL,
	[Alert_Category_Desc] [varchar](200) NULL,
	[Date_Updated] [datetime] NOT NULL 
	CONSTRAINT [PK_tblDBMon_Managed_Instances_Alert_Category_Alert_Category_ID] PRIMARY KEY CLUSTERED 
(
	[Alert_Category_ID]
))
GO

ALTER TABLE [dbo].[tblDBMon_Managed_Instances_Alert_Category] ADD  CONSTRAINT [DF_tblDBMon_Managed_Instances_Alert_Category_Date_Updated]  DEFAULT (GETDATE()) FOR [Date_Updated]
GO

INSERT INTO [dbo].[tblDBMon_Managed_Instances_Alert_Category]([Alert_Category_Name], [Alert_Category_Desc])
VALUES ('Availability','To track Managed Instance that failed an handshake attempt')
INSERT INTO [dbo].[tblDBMon_Managed_Instances_Alert_Category]([Alert_Category_Name], [Alert_Category_Desc])
VALUES ('CPU','To track CPU Utilization exceeding threshold')
INSERT INTO [dbo].[tblDBMon_Managed_Instances_Alert_Category]([Alert_Category_Name], [Alert_Category_Desc])
VALUES ('Storage','To track MI Storage Utilization exceeding threshold')
INSERT INTO [dbo].[tblDBMon_Managed_Instances_Alert_Category]([Alert_Category_Name], [Alert_Category_Desc])
VALUES ('TLog','To track Transaction Log Utilization exceeding threshold')
INSERT INTO [dbo].[tblDBMon_Managed_Instances_Alert_Category]([Alert_Category_Name], [Alert_Category_Desc])
VALUES ('PLE','Page Life Expectancy to monitor memory')
INSERT INTO [dbo].[tblDBMon_Managed_Instances_Alert_Category]([Alert_Category_Name], [Alert_Category_Desc])
VALUES ('Filegroup','To track Filegroup Utilization exceeding threshold')
GO

DROP FUNCTION IF EXISTS [dbo].[ufnDBMon_GetManagedInstancesAlertCategoryID]
GO
CREATE FUNCTION [dbo].[ufnDBMon_GetManagedInstancesAlertCategoryID]
(
	@Alert_Category_Name VARCHAR(50)
)
RETURNS TINYINT
AS
BEGIN
	DECLARE @varAlert_Category_ID TINYINT

	SELECT	@varAlert_Category_ID = [Alert_Category_ID]
	FROM	[dbo].[tblDBMon_Managed_Instances_Alert_Category]
	WHERE	[Alert_Category_Name] = @Alert_Category_Name

	RETURN	@varAlert_Category_ID
END
GO

DROP FUNCTION IF EXISTS [dbo].[ufnDBMon_GetManagedInstancesAlertCategoryName]
GO
CREATE FUNCTION [dbo].[ufnDBMon_GetManagedInstancesAlertCategoryName]
(
	@Alert_Category_ID TINYINT
)
RETURNS VARCHAR(50)
AS
BEGIN
	DECLARE @varAlert_Category_Name VARCHAR(50)

	SELECT	@varAlert_Category_Name = [Alert_Category_Name]
	FROM	[dbo].[tblDBMon_Managed_Instances_Alert_Category]
	WHERE	[Alert_Category_ID] = @Alert_Category_ID

	RETURN	@varAlert_Category_Name
END
GO

DROP TABLE IF EXISTS [load].[tblDBMon_Managed_Instances_Current_Alerts]
GO

CREATE TABLE [load].[tblDBMon_Managed_Instances_Current_Alerts](
	[Managed_Instance_Name] [nvarchar](256) NOT NULL,
	[Alert_Category_ID] TINYINT NOT NULL,
	[Alert_Parameter_Value] VARCHAR(50) NULL,
	[Alert_Parameter_Value_Desc] VARCHAR(2000) NULL,
	[Date_Captured] [datetime] NOT NULL)
GO

ALTER TABLE		[load].[tblDBMon_Managed_Instances_Current_Alerts] 
ADD CONSTRAINT	[FK_load_Alert_Category_ID] FOREIGN KEY ([Alert_Category_ID]) 
REFERENCES		[dbo].[tblDBMon_Managed_Instances_Alert_Category]([Alert_Category_ID])
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_Managed_Instances_Current_Alerts]
GO

CREATE TABLE [dbo].[tblDBMon_Managed_Instances_Current_Alerts](
	[Managed_Instance_Name] [nvarchar](256) NOT NULL,
	[Alert_Category_ID] TINYINT NOT NULL,
	[Alert_Parameter_Value] VARCHAR(50) NULL,
	[Alert_Parameter_Value_Desc] VARCHAR(2000) NULL,
	[Date_First_Reported] [datetime] NULL,
	[Date_Last_Reported] [datetime] NULL,
	[Date_Last_Alerted] [datetime] NULL
 CONSTRAINT [PK_tblDBMon_Managed_Instances_Current_Alerts_Managed_Instance_Name] PRIMARY KEY CLUSTERED 
(
	[Managed_Instance_Name], [Alert_Category_ID]
))
GO

ALTER TABLE		[dbo].[tblDBMon_Managed_Instances_Current_Alerts] 
ADD CONSTRAINT	[FK_Alert_Category_ID] FOREIGN KEY ([Alert_Category_ID]) 
REFERENCES		[dbo].[tblDBMon_Managed_Instances_Alert_Category]([Alert_Category_ID])
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

INSERT INTO [dbo].[tblDBMon_Config_Details] ([Config_Parameter],[Config_Parameter_Value])
VALUES('uspDBMon_rptGetMICurrentAlerts_TTL','358')
--Strati-AF-SQLServer@email.wal-mart.com;
INSERT INTO [dbo].[tblDBMon_Config_Details] ([Config_Parameter],[Config_Parameter_Value])
VALUES('uspDBMon_rptGetMICurrentAlerts_Mail_Address','Strati-AF-SQLServer@email.wal-mart.com;Raghu.Gopalakrishnan@microsoft.com;vn502i6@wal-mart.com')
INSERT INTO [dbo].[tblDBMon_Config_Details] ([Config_Parameter],[Config_Parameter_Value])
VALUES('uspDBMon_rptGetMICurrentAlerts_Minutes_Down_Threshold','1')

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_rptGetMICurrentAlerts]
GO

CREATE PROCEDURE [dbo].[uspDBMon_rptGetMICurrentAlerts]
	@Mail varchar(max)
AS
	/*
		Author	:	Raghu Gopalakrishnan
		Date	:	6th May 2019
		Purpose	:	This Stored Procedure is used by the DBMon tool
		Version	:	1.2 GDI
		License:
		This script is provided "AS IS" with no warranties, and confers no rights.
					EXEC [dbo].[uspDBMon_rptGetMICurrentAlerts]
								@Mail = 'Raghu.Gopalakrishnan@microsoft.com; vn502i6@wal-mart.com; Kranthi.Manikonda@walmart.com',
								@Minutes_Down_Threshold = 0
	
		Modification History
		----------------------
		May	 6th, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
		May	24th, 2019	:	v1.1	:	Raghu Gopalakrishnan	:	Added logic to report PLE (Memory bottlenecks)
		Jun  5th, 2019	:	v1.2	:	Raghu Gopalakrishnan	:	Added logic to report Filegroup(s) running out of space.
	*/

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

DECLARE @varSubject VARCHAR(200)	
DECLARE @vartableHTML VARCHAR(MAX)
DECLARE @vartableHTML_Good VARCHAR(MAX)
DECLARE @varuspDBMon_rptGetMICurrentAlerts_TTL SMALLINT
DECLARE @varuspDBMon_rptGetMICurrentAlerts_Mail_Address VARCHAR(2000)
DECLARE @varuspDBMon_rptGetMICurrentAlerts_Minutes_Down_Threshold TINYINT

SELECT	@varuspDBMon_rptGetMICurrentAlerts_TTL = [Config_Parameter_Value]
FROM	[dbo].[tblDBMon_Config_Details]
WHERE	[Config_Parameter] = 'uspDBMon_rptGetMICurrentAlerts_TTL'

SELECT	@varuspDBMon_rptGetMICurrentAlerts_Minutes_Down_Threshold = [Config_Parameter_Value]
FROM	[dbo].[tblDBMon_Config_Details]
WHERE	[Config_Parameter] = 'uspDBMon_rptGetMICurrentAlerts_Minutes_Down_Threshold'

IF (@Mail IS NULL)
	BEGIN
		SELECT	@varuspDBMon_rptGetMICurrentAlerts_Mail_Address = [Config_Parameter_Value]
		FROM	[dbo].[tblDBMon_Config_Details]
		WHERE	[Config_Parameter] = 'uspDBMon_rptGetMICurrentAlerts_Mail_Address'
	END
ELSE
	BEGIN
		SELECT	@varuspDBMon_rptGetMICurrentAlerts_Mail_Address = @Mail
	END

TRUNCATE TABLE [load].[tblDBMon_Managed_Instances_Current_Alerts]

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[vwManaged_Instance_Details] WHERE Last_Handshake_Minutes > @varuspDBMon_rptGetMICurrentAlerts_Minutes_Down_Threshold)
	BEGIN
		INSERT INTO [load].[tblDBMon_Managed_Instances_Current_Alerts] ([Managed_Instance_Name], [Alert_Category_ID], [Alert_Parameter_Value], [Date_Captured])
		SELECT	[Managed_Instance_Name],
				[dbo].[ufnDBMon_GetManagedInstancesAlertCategoryID]('Availability'),
				[Last_Handshake_Minutes],
				GETDATE()
		FROM	[dbo].[vwManaged_Instance_Details] 
		WHERE	[Last_Handshake_Minutes] > @varuspDBMon_rptGetMICurrentAlerts_Minutes_Down_Threshold

		SET @vartableHTML =
			N'<H3>Managed Instance(s) Reporting Down</H3>' +
			N'<table border="1" style="margin-left:3em">' +
			N'<tr><th>ID</th>' + 
			N'<th>Managed Instance Name</th>' +
			N'<th>Production</th>' + 
			N'<th>Minutes Down</th>' + 
			N'<th>Handshake Timestamp UTC</th></tr>' +
			CAST ( (	SELECT		td = ROW_NUMBER() OVER(ORDER BY [Last_Handshake_Minutes], [Managed_Instance_Name]), '',
									td = [Managed_Instance_Name], '',
									td = [Is_Production], '',
									td = [Last_Handshake_Minutes], '', 
									td = REPLACE(Handshake_Timestamp_UTC, ' ', '_')  
						FROM		[dbo].[vwManaged_Instance_Details] 
						WHERE		Last_Handshake_Minutes > @varuspDBMon_rptGetMICurrentAlerts_Minutes_Down_Threshold
						ORDER BY	1
						FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) ) +	N'</table>'
	END
ELSE
	BEGIN
		PRINT 'All Managed Instances have responded in the last ' + CAST(@varuspDBMon_rptGetMICurrentAlerts_Minutes_Down_Threshold AS VARCHAR(5)) + ' minute(s). '
		SET @vartableHTML_Good = N'<p>All Managed Instances have responded in the last ' + CAST(@varuspDBMon_rptGetMICurrentAlerts_Minutes_Down_Threshold AS VARCHAR(5)) + ' minute(s). <p>' 
	END

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[vwManaged_Instance_Parameters_Monitored] WHERE [CPU_Utilization_Flag] = 'TRUE')
	BEGIN
		INSERT INTO [load].[tblDBMon_Managed_Instances_Current_Alerts] ([Managed_Instance_Name], [Alert_Category_ID], [Alert_Parameter_Value], [Date_Captured])
		SELECT	[Managed_Instance_Name],
				[dbo].[ufnDBMon_GetManagedInstancesAlertCategoryID]('CPU'),
				[CPU_Utilization],
				GETDATE()
		FROM	[dbo].[vwManaged_Instance_Parameters_Monitored]
		WHERE	[CPU_Utilization_Flag] = 'TRUE'

		SET @vartableHTML = @vartableHTML +
			N'<H3>Managed Instance(s) Exceeding CPU Utilization Threshold</H3>' +
			N'<table border="1" style="margin-left:3em">' +
			N'<tr><th>ID</th>' +
			N'<th>Managed Instance Name</th>' +
			N'<th>CPU Utilization(%)</th>' + 
			N'<th>CPU Utilization Threshold(%)</th></tr>' +
			CAST ( (	SELECT		td = ROW_NUMBER() OVER(ORDER BY [CPU_Utilization] DESC, [Managed_Instance_Name]), '',
									td = [Managed_Instance_Name], '',
									td = [CPU_Utilization], '',
									td = [CPU_Utilization_Threshold]
						FROM		[dbo].[vwManaged_Instance_Parameters_Monitored] 
						WHERE		[CPU_Utilization_Flag] = 'TRUE'
						ORDER BY	1
						FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) ) +	N'</table>'
	END
ELSE
	BEGIN
		PRINT 'All Managed Instances have CPU utilization less than their threshold.'
		SET @vartableHTML_Good = @vartableHTML_Good + N'<p>All Managed Instances have CPU utilization less than their threshold.</p>' 
	END

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[vwManaged_Instance_Parameters_Monitored] WHERE [PLE_Flag] = 'TRUE')
	BEGIN
  		INSERT INTO [load].[tblDBMon_Managed_Instances_Current_Alerts] ([Managed_Instance_Name], [Alert_Category_ID], [Alert_Parameter_Value], [Alert_Parameter_Value_Desc], [Date_Captured])
		SELECT	[Managed_Instance_Name],
				[dbo].[ufnDBMon_GetManagedInstancesAlertCategoryID]('PLE'),
				[PLE_Value],
				[PLE_Value_Desc],
				GETDATE()
		FROM	[dbo].[vwManaged_Instance_Parameters_Monitored]
		WHERE	[PLE_Flag] = 'TRUE'

		SET @vartableHTML = @vartableHTML +
			N'<H3>Managed Instance(s) Memory Bottlenecks - Page Life Expectancy</H3>' +
			N'<table border="1" style="margin-left:3em">' +
			N'<tr><th>ID</th>' +
			N'<th>Managed Instance Name</th>' +
			N'<th>PLE</th>' + 
			N'<th>PLE Value Desc</th></tr>' +
			CAST ( (	SELECT		td = ROW_NUMBER() OVER(ORDER BY [PLE_Value], [Managed_Instance_Name]), '',
									td = [Managed_Instance_Name], '',
									td = [PLE_Value], '',
									td = [PLE_Value_Desc]
						FROM		[dbo].[vwManaged_Instance_Parameters_Monitored] 
						WHERE		[PLE_Flag] = 'TRUE'
						ORDER BY	1
						FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) ) +	N'</table>'
	END
ELSE
	BEGIN
		PRINT 'All Managed Instances have PLE value more than the threshold.'
		SET @vartableHTML_Good = @vartableHTML_Good + N'<p>All Managed Instances have PLE value greater than the threshold.</p>'
	END

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[vwManaged_Instance_Parameters_Monitored] WHERE [Storage_Utilization_Flag] = 'TRUE')
	BEGIN
		INSERT INTO [load].[tblDBMon_Managed_Instances_Current_Alerts] ([Managed_Instance_Name], [Alert_Category_ID], [Alert_Parameter_Value], [Alert_Parameter_Value_Desc], [Date_Captured])
		SELECT	[Managed_Instance_Name],
				[dbo].[ufnDBMon_GetManagedInstancesAlertCategoryID]('Storage'),
				[Storage_Utilization],
				[Storage_Utilization_Desc],
				GETDATE()
		FROM	[dbo].[vwManaged_Instance_Parameters_Monitored]
		WHERE	[Storage_Utilization_Flag] = 'TRUE'

		SET @vartableHTML = @vartableHTML +
			N'<H3>Managed Instance(s) Exceeding Storage Utilization Threshold</H3>' +
			N'<table border="1" style="margin-left:3em">' +
			N'<tr><th>ID</th>' +
			N'<th>Managed Instance Name</th>' +
			N'<th>Storage Utilization(%)</th>' + 
			N'<th>Storage Threshold(%)</th>' +
			N'<th>Storage Utilization Description</th></tr>' +
			CAST ( (	SELECT		td = ROW_NUMBER() OVER(ORDER BY [Storage_Utilization] DESC, [Managed_Instance_Name]), '',
									td = [Managed_Instance_Name], '',
									td = [Storage_Utilization], '',
									td = [Storage_Utilization_Threshold], '',
									td = [Storage_Utilization_Desc]
						FROM		[dbo].[vwManaged_Instance_Parameters_Monitored] 
						WHERE		[Storage_Utilization_Flag] = 'TRUE'
						ORDER BY	1
						FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) ) +	N'</table>'
	END
ELSE
	BEGIN
		PRINT 'All Managed Instances have Storage utilization less than their threshold.'
		SET @vartableHTML_Good = @vartableHTML_Good +	N'<p>All Managed Instances have Storage utilization less than their threshold.</p>'
	END

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[vwManaged_Instance_Parameters_Monitored] WHERE [Database_Filegroup_Utilization_Flag] = 'TRUE')
	BEGIN
		INSERT INTO [load].[tblDBMon_Managed_Instances_Current_Alerts] ([Managed_Instance_Name], [Alert_Category_ID], [Alert_Parameter_Value], [Alert_Parameter_Value_Desc], [Date_Captured])
		SELECT	[Managed_Instance_Name],
				[dbo].[ufnDBMon_GetManagedInstancesAlertCategoryID]('Filegroup'),
				[Database_Filegroup_Utilization],
				[Database_Filegroup_Utilization_Desc],
				GETDATE()
		FROM	[dbo].[vwManaged_Instance_Parameters_Monitored]
		WHERE	[Database_Filegroup_Utilization_Flag] = 'TRUE'

		SET @vartableHTML = @vartableHTML +
			N'<H3>Database(s) Exceeding Filegroup Space Utilization Threshold</H3>' +
			N'<table border="1" style="margin-left:3em">' +
			N'<tr><th>ID</th>' +
			N'<th>Managed Instance Name</th>' +
			N'<th>Filegroup Space Utilization(%)</th>' + 
			N'<th>Filegroup Space Utilization Threshold</th>' + 
			N'<th>Filegroup Space Utilization Desc</th></tr>' +
			CAST ( (	SELECT		td = ROW_NUMBER() OVER(ORDER BY [Database_Filegroup_Utilization] DESC, [Managed_Instance_Name]), '',
									td = [Managed_Instance_Name], '',
									td = [Database_Filegroup_Utilization], '',
									td = [Database_Filegroup_Utilization_Threshold], '',
									td = [Database_Filegroup_Utilization_Desc]
						FROM		[dbo].[vwManaged_Instance_Parameters_Monitored] 
						WHERE		[Database_Filegroup_Utilization_Flag] = 'TRUE'
						ORDER BY	1
						FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) ) +	N'</table>'
	END
ELSE
	BEGIN
		PRINT 'All Managed Instances have Databases Filegroup space utilization less than their threshold.'
		SET @vartableHTML_Good = @vartableHTML_Good +	N'<p>All Managed Instances have Databases with Filegroup space utilization less than their threshold.</p>'
	END

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[vwManaged_Instance_Parameters_Monitored] WHERE [Database_TLog_Utilization_Flag] = 'TRUE')
	BEGIN
		INSERT INTO [load].[tblDBMon_Managed_Instances_Current_Alerts] ([Managed_Instance_Name], [Alert_Category_ID], [Alert_Parameter_Value], [Alert_Parameter_Value_Desc], [Date_Captured])
		SELECT	[Managed_Instance_Name],
				[dbo].[ufnDBMon_GetManagedInstancesAlertCategoryID]('TLog'),
				[Database_TLog_Utilization],
				[Database_TLog_Utilization_Desc],
				GETDATE()
		FROM	[dbo].[vwManaged_Instance_Parameters_Monitored]
		WHERE	[Database_TLog_Utilization_Flag] = 'TRUE'

		SET @vartableHTML = @vartableHTML +
			N'<H3>Database(s) Exceeding Transaction Log Utilization Threshold</H3>' +
			N'<table border="1" style="margin-left:3em">' +
			N'<tr><th>ID</th>' +
			N'<th>Managed Instance Name</th>' +
			N'<th>Transaction Log Utilization(%)</th>' + 
			N'<th>Transaction Log Utilization Threshold</th>' + 
			N'<th>Transaction Log Utilization Desc</th></tr>' +
			CAST ( (	SELECT		td = ROW_NUMBER() OVER(ORDER BY [Database_TLog_Utilization] DESC, [Managed_Instance_Name]), '',
									td = [Managed_Instance_Name], '',
									td = [Database_TLog_Utilization], '',
									td = [Database_TLog_Utilization_Threshold], '',
									td = [Database_TLog_Utilization_Desc]
						FROM		[dbo].[vwManaged_Instance_Parameters_Monitored] 
						WHERE		[Database_TLog_Utilization_Flag] = 'TRUE'
						ORDER BY	1
						FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) ) +	N'</table>'
	END
ELSE
	BEGIN
		PRINT 'All Managed Instances have Transaction Log utilization less than their threshold.'
		SET @vartableHTML_Good = @vartableHTML_Good +	N'<p>All Managed Instances have Databases with Transaction Log utilization less than their threshold.</p>'
	END

MERGE	[dbo].[tblDBMon_Managed_Instances_Current_Alerts] AS target
USING	[load].[tblDBMon_Managed_Instances_Current_Alerts] AS source
	ON	((target.[Managed_Instance_Name] = source.[Managed_Instance_Name]) AND (target.[Alert_Category_ID] = source.[Alert_Category_ID]))
WHEN MATCHED THEN
	UPDATE SET	target.Date_Last_Reported = source.Date_Captured,
				target.[Alert_Parameter_Value] = source.[Alert_Parameter_Value],
				target.[Alert_Parameter_Value_Desc] = source.[Alert_Parameter_Value_Desc]
WHEN NOT MATCHED BY target THEN
	INSERT ([Managed_Instance_Name], [Alert_Category_ID], [Alert_Parameter_Value], [Alert_Parameter_Value_Desc], [Date_First_Reported], [Date_Last_Reported])
	VALUES (source.[Managed_Instance_Name], source.[Alert_Category_ID], source.[Alert_Parameter_Value], source.[Alert_Parameter_Value_Desc], source.Date_Captured, source.Date_Captured)
WHEN NOT MATCHED BY source THEN
	DELETE;

IF EXISTS(SELECT TOP 1 1 FROM [dbo].[tblDBMon_Managed_Instances_Current_Alerts] WHERE Date_Last_Alerted IS NULL)
		BEGIN
			SELECT @varSubject = '[Azure]: Managed Instance(s) Reporting Issues - New Alert!'
			SELECT @vartableHTML = @vartableHTML + @vartableHTML_Good
			EXEC msdb.dbo.sp_send_dbmail 
					@recipients=@varuspDBMon_rptGetMICurrentAlerts_Mail_Address,
					@subject = @varSubject,
					@body = @vartableHTML,
					@body_format = 'HTML'

			IF (@@ERROR = 0)
				BEGIN
					UPDATE	[dbo].[tblDBMon_Managed_Instances_Current_Alerts]
					SET		Date_Last_Alerted = GETDATE()
				END
		END
ELSE IF EXISTS(SELECT TOP 1 1 FROM [dbo].[tblDBMon_Managed_Instances_Current_Alerts] WHERE DATEDIFF(mi, Date_Last_Alerted, GETDATE()) > @varuspDBMon_rptGetMICurrentAlerts_TTL)
	BEGIN
			SELECT @varSubject = '[Azure]: Managed Instance(s) Reporting Issues - Duplicate'
			SELECT @vartableHTML = @vartableHTML + @vartableHTML_Good
			EXEC msdb.dbo.sp_send_dbmail 
					@recipients=@varuspDBMon_rptGetMICurrentAlerts_Mail_Address,
					@subject = @varSubject,
					@body = @vartableHTML,
					@body_format = 'HTML'

			IF (@@ERROR = 0)
				BEGIN
					UPDATE	[dbo].[tblDBMon_Managed_Instances_Current_Alerts]
					SET		Date_Last_Alerted = GETDATE()
				END		
	END

UPDATE	[dbo].[tblDBMon_SP_Version]
SET		[Last_Executed] = GETDATE()
WHERE	[SP_Name] = OBJECT_NAME(@@PROCID)
GO

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[tblDBMon_SP_Version] WHERE [SP_Name] = 'uspDBMon_rptGetMICurrentAlerts')
	BEGIN
		UPDATE	[dbo].[tblDBMon_SP_Version]
		SET		[SP_Version] = '1.2 GCA',
				[Last_Executed] = NULL,
				[Date_Modified] = GETDATE(),
				[Modified_By] = SUSER_SNAME()
		WHERE	[SP_Name] = 'uspDBMon_rptGetMICurrentAlerts'
	END
ELSE
	BEGIN
		INSERT INTO [dbo].[tblDBMon_SP_Version] ([SP_Name], [SP_Version], [Last_Executed], [Date_Modified], [Modified_By])
		VALUES ('uspDBMon_rptGetMICurrentAlerts', '1.2 GCA', NULL, GETDATE(), SUSER_SNAME())
	END
GO

EXEC sp_addextendedproperty 
	@name = 'Version', @value = '1.2 GCA', 
	@level0type = 'SCHEMA', @level0name = 'dbo', 
	@level1type = 'PROCEDURE', @level1name = 'uspDBMon_rptGetMICurrentAlerts'
GO


SELECT	[Managed_Instance_Name], 
		[dbo].[ufnDBMon_GetManagedInstancesAlertCategoryName]([Alert_Category_ID]) AS [Alert_Category_Name],
		[Date_First_Reported],
		[Date_Last_Reported],
		[Date_Last_Alerted]
FROM [dbo].[tblDBMon_Managed_Instances_Current_Alerts]
GO
EXEC [dbo].[uspDBMon_rptGetMICurrentAlerts] @Mail = NULL
GO
SELECT	[Managed_Instance_Name], 
		[dbo].[ufnDBMon_GetManagedInstancesAlertCategoryName]([Alert_Category_ID]) AS [Alert_Category_Name],
		[Alert_Parameter_Value],
		[Alert_Parameter_Value_Desc],
		[Date_First_Reported],
		[Date_Last_Reported],
		[Date_Last_Alerted]
FROM [dbo].[tblDBMon_Managed_Instances_Current_Alerts]
GO
