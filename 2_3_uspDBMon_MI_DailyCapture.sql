SET NOCOUNT ON

USE [dba_local]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_MI_DailyCapture]
GO

CREATE proc [dbo].[uspDBMon_MI_DailyCapture]
AS
	/*
		Author	:	Raghu Gopalakrishnan
		Date	:	30th May 2019
		Purpose	:	This Stored Procedure is used by the DBMon tool
		Version	:	1.0 DC		
		License:
		This script is provided "AS IS" with no warranties, and confers no rights.
					EXEC [dbo].[uspDBMon_MI_DailyCapture]
	
		Modification History
		----------------------
		May	30th, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
	*/

SET NOCOUNT ON

EXEC [dbo].[uspDBMon_MI_GetDatabaseSize]

UPDATE	[dbo].[tblDBMon_SP_Version]
SET		[Last_Executed] = GETDATE()
WHERE	[SP_Name] = OBJECT_NAME(@@PROCID)
GO

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[tblDBMon_SP_Version] WHERE [SP_Name] = 'uspDBMon_MI_DailyCapture')
	BEGIN
		UPDATE	[dbo].[tblDBMon_SP_Version]
		SET		[SP_Version] = '1.0 DC',
				[Last_Executed] = NULL,
				[Date_Modified] = GETDATE(),
				[Modified_By] = SUSER_SNAME()
		WHERE	[SP_Name] = 'uspDBMon_MI_DailyCapture'
	END
ELSE
	BEGIN
		INSERT INTO [dbo].[tblDBMon_SP_Version] ([SP_Name], [SP_Version], [Last_Executed], [Date_Modified], [Modified_By])
		VALUES ('uspDBMon_MI_DailyCapture', '1.0 DC', NULL, GETDATE(), SUSER_SNAME())
	END
GO

EXEC sp_addextendedproperty 
		@name = 'Version', @value = '1.0 DC', 
		@level0type = 'SCHEMA', @level0name = 'dbo', 
		@level1type = 'PROCEDURE', @level1name = 'uspDBMon_MI_DailyCapture'
GO
