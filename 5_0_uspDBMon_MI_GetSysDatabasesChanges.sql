SET NOCOUNT ON

USE [dba_local]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
DROP TABLE IF EXISTS [dbo].[tblDBMon_Sys_Databases]
GO

CREATE TABLE [dbo].[tblDBMon_Sys_Databases](
		[Date_Captured] [datetime] NOT NULL CONSTRAINT [DF_tblDBMon_Sys_Databases_Date_Captured] DEFAULT GETDATE(),
		[name] [sysname] NOT NULL,
		[database_id] [int] NOT NULL,
		[source_database_id] [int] NULL,
		[owner_sid] [varbinary](85) NULL,
		[create_date] [datetime] NOT NULL,
		[compatibility_level] [tinyint] NOT NULL,
		[collation_name] [sysname] NULL,
		[user_access] [tinyint] NULL,
		[user_access_desc] [nvarchar](60) NULL,
		[is_read_only] [bit] NULL,
		[is_auto_close_on] [bit] NOT NULL,
		[is_auto_shrink_on] [bit] NULL,
		[state] [tinyint] NULL,
		[state_desc] [nvarchar](60) NULL,
		[is_in_standby] [bit] NULL,
		[is_cleanly_shutdown] [bit] NULL,
		[is_supplemental_logging_enabled] [bit] NULL,
		[snapshot_isolation_state] [tinyint] NULL,
		[snapshot_isolation_state_desc] [nvarchar](60) NULL,
		[is_read_committed_snapshot_on] [bit] NULL,
		[recovery_model] [tinyint] NULL,
		[recovery_model_desc] [nvarchar](60) NULL,
		[page_verify_option] [tinyint] NULL,
		[page_verify_option_desc] [nvarchar](60) NULL,
		[is_auto_create_stats_on] [bit] NULL,
		[is_auto_create_stats_incremental_on] [bit] NULL,
		[is_auto_update_stats_on] [bit] NULL,
		[is_auto_update_stats_async_on] [bit] NULL,
		[is_ansi_null_default_on] [bit] NULL,
		[is_ansi_nulls_on] [bit] NULL,
		[is_ansi_padding_on] [bit] NULL,
		[is_ansi_warnings_on] [bit] NULL,
		[is_arithabort_on] [bit] NULL,
		[is_concat_null_yields_null_on] [bit] NULL,
		[is_numeric_roundabort_on] [bit] NULL,
		[is_quoted_identifier_on] [bit] NULL,
		[is_recursive_triggers_on] [bit] NULL,
		[is_cursor_close_on_commit_on] [bit] NULL,
		[is_local_cursor_default] [bit] NULL,
		[is_fulltext_enabled] [bit] NULL,
		[is_trustworthy_on] [bit] NULL,
		[is_db_chaining_on] [bit] NULL,
		[is_parameterization_forced] [bit] NULL,
		[is_master_key_encrypted_by_server] [bit] NOT NULL,
		[is_query_store_on] [bit] NULL,
		[is_published] [bit] NOT NULL,
		[is_subscribed] [bit] NOT NULL,
		[is_merge_published] [bit] NOT NULL,
		[is_distributor] [bit] NOT NULL,
		[is_sync_with_backup] [bit] NOT NULL,
		[service_broker_guid] [uniqueidentifier] NOT NULL,
		[is_broker_enabled] [bit] NOT NULL,
		[log_reuse_wait] [tinyint] NULL,
		[log_reuse_wait_desc] [nvarchar](60) NULL,
		[is_date_correlation_on] [bit] NOT NULL,
		[is_cdc_enabled] [bit] NOT NULL,
		[is_encrypted] [bit] NULL,
		[is_honor_broker_priority_on] [bit] NULL,
		[replica_id] [uniqueidentifier] NULL,
		[group_database_id] [uniqueidentifier] NULL,
		[resource_pool_id] [int] NULL,
		[default_language_lcid] [smallint] NULL,
		[default_language_name] [nvarchar](128) NULL,
		[default_fulltext_language_lcid] [int] NULL,
		[default_fulltext_language_name] [nvarchar](128) NULL,
		[is_nested_triggers_on] [bit] NULL,
		[is_transform_noise_words_on] [bit] NULL,
		[two_digit_year_cutoff] [smallint] NULL,
		[containment] [tinyint] NULL,
		[containment_desc] [nvarchar](60) NULL,
		[target_recovery_time_in_seconds] [int] NULL,
		[delayed_durability] [int] NULL,
		[delayed_durability_desc] [nvarchar](60) NULL,
		[is_memory_optimized_elevate_to_snapshot_on] [bit] NULL,
		[is_federation_member] [bit] NULL,
		[is_remote_data_archive_enabled] [bit] NULL,
		[is_mixed_page_allocation_on] [bit] NULL,
		[is_temporal_history_retention_enabled] [bit] NULL,
		[catalog_collation_type] [int],
		[catalog_collation_type_desc] [nvarchar] (120),
		[physical_database_name] [nvarchar] (256),
		[is_result_set_caching_on] [bigint],
		[is_accelerated_database_recovery_on] [bigint],
		[is_tempdb_spill_to_remote_store] [bigint],
		[Updated_By] [nvarchar](128) NOT NULL CONSTRAINT [DF_tblDBMon_Sys_Databases_Updated_By] DEFAULT SUSER_SNAME()
	)

CREATE CLUSTERED INDEX IDX_tblDBMon_Sys_Databases_Date_Captured ON [dbo].[tblDBMon_Sys_Databases](Date_Captured)
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_MI_GetSysDatabasesChanges]
GO

CREATE PROCEDURE [dbo].[uspDBMon_MI_GetSysDatabasesChanges]
AS
/*
	Author	:	Raghu Gopalakrishnan
	Date	:	6th June 2019
	Purpose	:	This Stored Procedure is used by the DBMon tool
	Version	:	1.0 RB
	License:
	This script is provided "AS IS" with no warranties, and confers no rights.
				SELECT * FROM [dbo].[tblDBMon_Sys_Databases]
	
	Modification History
	----------------------
	Jun	 6th, 2019	:	v1.0	:	Raghu Gopalakrishnan	:	Inception
*/
SET NOCOUNT ON
DECLARE @varDatabase_Name SYSNAME
DECLARE @varSQLText VARCHAR(MAX)

--Add new databases
INSERT INTO [dbo].[tblDBMon_Sys_Databases](
										[name],
										[database_id],
										[source_database_id],
										[owner_sid],
										[create_date],
										[compatibility_level],
										[collation_name],
										[user_access],
										[user_access_desc],
										[is_read_only],
										[is_auto_close_on],
										[is_auto_shrink_on],
										[state],
										[state_desc],
										[is_in_standby],
										[is_cleanly_shutdown],
										[is_supplemental_logging_enabled],
										[snapshot_isolation_state],
										[snapshot_isolation_state_desc],
										[is_read_committed_snapshot_on],
										[recovery_model],
										[recovery_model_desc],
										[page_verify_option],
										[page_verify_option_desc],
										[is_auto_create_stats_on],
										[is_auto_create_stats_incremental_on],
										[is_auto_update_stats_on],
										[is_auto_update_stats_async_on],
										[is_ansi_null_default_on],
										[is_ansi_nulls_on],
										[is_ansi_padding_on],
										[is_ansi_warnings_on],
										[is_arithabort_on],
										[is_concat_null_yields_null_on],
										[is_numeric_roundabort_on],
										[is_quoted_identifier_on],
										[is_recursive_triggers_on],
										[is_cursor_close_on_commit_on],
										[is_local_cursor_default],
										[is_fulltext_enabled],
										[is_trustworthy_on],
										[is_db_chaining_on],
										[is_parameterization_forced],
										[is_master_key_encrypted_by_server],
										[is_query_store_on],
										[is_published],
										[is_subscribed],
										[is_merge_published],
										[is_distributor],
										[is_sync_with_backup],
										[service_broker_guid],
										[is_broker_enabled],
										[log_reuse_wait],
										[log_reuse_wait_desc],
										[is_date_correlation_on],
										[is_cdc_enabled],
										[is_encrypted],
										[is_honor_broker_priority_on],
										[replica_id],
										[group_database_id],
										[resource_pool_id],
										[default_language_lcid],
										[default_language_name],
										[default_fulltext_language_lcid],
										[default_fulltext_language_name],
										[is_nested_triggers_on],
										[is_transform_noise_words_on],
										[two_digit_year_cutoff],
										[containment],
										[containment_desc],
										[target_recovery_time_in_seconds],
										[delayed_durability],
										[delayed_durability_desc],
										[is_memory_optimized_elevate_to_snapshot_on],
										[is_federation_member],
										[is_remote_data_archive_enabled],
										[is_mixed_page_allocation_on],
										[is_temporal_history_retention_enabled],
										[catalog_collation_type],
										[catalog_collation_type_desc],
										[physical_database_name],
										[is_result_set_caching_on],
										[is_accelerated_database_recovery_on],
										[is_tempdb_spill_to_remote_store]) 
								SELECT	[name],
										[database_id],
										[source_database_id],
										[owner_sid],
										[create_date],
										[compatibility_level],
										[collation_name],
										[user_access],
										[user_access_desc],
										[is_read_only],
										[is_auto_close_on],
										[is_auto_shrink_on],
										[state],
										[state_desc],
										[is_in_standby],
										[is_cleanly_shutdown],
										[is_supplemental_logging_enabled],
										[snapshot_isolation_state],
										[snapshot_isolation_state_desc],
										[is_read_committed_snapshot_on],
										[recovery_model],
										[recovery_model_desc],
										[page_verify_option],
										[page_verify_option_desc],
										[is_auto_create_stats_on],
										[is_auto_create_stats_incremental_on],
										[is_auto_update_stats_on],
										[is_auto_update_stats_async_on],
										[is_ansi_null_default_on],
										[is_ansi_nulls_on],
										[is_ansi_padding_on],
										[is_ansi_warnings_on],
										[is_arithabort_on],
										[is_concat_null_yields_null_on],
										[is_numeric_roundabort_on],
										[is_quoted_identifier_on],
										[is_recursive_triggers_on],
										[is_cursor_close_on_commit_on],
										[is_local_cursor_default],
										[is_fulltext_enabled],
										[is_trustworthy_on],
										[is_db_chaining_on],
										[is_parameterization_forced],
										[is_master_key_encrypted_by_server],
										[is_query_store_on],
										[is_published],
										[is_subscribed],
										[is_merge_published],
										[is_distributor],
										[is_sync_with_backup],
										[service_broker_guid],
										[is_broker_enabled],
										[log_reuse_wait],
										[log_reuse_wait_desc],
										[is_date_correlation_on],
										[is_cdc_enabled],
										[is_encrypted],
										[is_honor_broker_priority_on],
										[replica_id],
										[group_database_id],
										[resource_pool_id],
										[default_language_lcid],
										[default_language_name],
										[default_fulltext_language_lcid],
										[default_fulltext_language_name],
										[is_nested_triggers_on],
										[is_transform_noise_words_on],
										[two_digit_year_cutoff],
										[containment],
										[containment_desc],
										[target_recovery_time_in_seconds],
										[delayed_durability],
										[delayed_durability_desc],
										[is_memory_optimized_elevate_to_snapshot_on],
										[is_federation_member],
										[is_remote_data_archive_enabled],
										[is_mixed_page_allocation_on],
										[is_temporal_history_retention_enabled],
										[catalog_collation_type],
										[catalog_collation_type_desc],
										[physical_database_name],
										[is_result_set_caching_on],
										[is_accelerated_database_recovery_on],
										[is_tempdb_spill_to_remote_store]
								FROM	[sys].[databases]
								WHERE	[name] NOT IN (SELECT DISTINCT [name] FROM [dbo].[tblDBMon_Sys_Databases])

SELECT	@varDatabase_Name = MIN([name]) FROM [sys].[databases]

WHILE (@varDatabase_Name IS NOT NULL)
	BEGIN
		WITH cte_tblDBMon_Sys_Databases AS(
			SELECT TOP 1 * 
			FROM	[dbo].[tblDBMon_Sys_Databases]
			WHERE	[name] = @varDatabase_Name
			ORDER BY Date_Captured DESC)

		INSERT INTO		[dbo].[tblDBMon_Sys_Databases]
		SELECT			GETDATE(),
						A.[name],
						A.[database_id],
						A.[source_database_id],
						A.[owner_sid],
						A.[create_date],
						A.[compatibility_level],
						A.[collation_name],
						A.[user_access],
						A.[user_access_desc],
						A.[is_read_only],
						A.[is_auto_close_on],
						A.[is_auto_shrink_on],
						A.[state],
						A.[state_desc],
						A.[is_in_standby],
						A.[is_cleanly_shutdown],
						A.[is_supplemental_logging_enabled],
						A.[snapshot_isolation_state],
						A.[snapshot_isolation_state_desc],
						A.[is_read_committed_snapshot_on],
						A.[recovery_model],
						A.[recovery_model_desc],
						A.[page_verify_option],
						A.[page_verify_option_desc],
						A.[is_auto_create_stats_on],
						A.[is_auto_create_stats_incremental_on],
						A.[is_auto_update_stats_on],
						A.[is_auto_update_stats_async_on],
						A.[is_ansi_null_default_on],
						A.[is_ansi_nulls_on],
						A.[is_ansi_padding_on],
						A.[is_ansi_warnings_on],
						A.[is_arithabort_on],
						A.[is_concat_null_yields_null_on],
						A.[is_numeric_roundabort_on],
						A.[is_quoted_identifier_on],
						A.[is_recursive_triggers_on],
						A.[is_cursor_close_on_commit_on],
						A.[is_local_cursor_default],
						A.[is_fulltext_enabled],
						A.[is_trustworthy_on],
						A.[is_db_chaining_on],
						A.[is_parameterization_forced],
						A.[is_master_key_encrypted_by_server],
						A.[is_query_store_on],
						A.[is_published],
						A.[is_subscribed],
						A.[is_merge_published],
						A.[is_distributor],
						A.[is_sync_with_backup],
						A.[service_broker_guid],
						A.[is_broker_enabled],
						A.[log_reuse_wait],
						A.[log_reuse_wait_desc],
						A.[is_date_correlation_on],
						A.[is_cdc_enabled],
						A.[is_encrypted],
						A.[is_honor_broker_priority_on],
						A.[replica_id],
						A.[group_database_id],
						A.[resource_pool_id],
						A.[default_language_lcid],
						A.[default_language_name],
						A.[default_fulltext_language_lcid],
						A.[default_fulltext_language_name],
						A.[is_nested_triggers_on],
						A.[is_transform_noise_words_on],
						A.[two_digit_year_cutoff],
						A.[containment],
						A.[containment_desc],
						A.[target_recovery_time_in_seconds],
						A.[delayed_durability],
						A.[delayed_durability_desc],
						A.[is_memory_optimized_elevate_to_snapshot_on],
						A.[is_federation_member],
						A.[is_remote_data_archive_enabled],
						A.[is_mixed_page_allocation_on],
						A.[is_temporal_history_retention_enabled],
						A.[catalog_collation_type],
						A.[catalog_collation_type_desc],
						A.[physical_database_name],
						A.[is_result_set_caching_on],
						A.[is_accelerated_database_recovery_on],
						A.[is_tempdb_spill_to_remote_store],
						SUSER_SNAME() 
		FROM			[sys].[databases] A
		LEFT OUTER JOIN cte_tblDBMon_Sys_Databases B
		ON				A.[name] = B.[name] 
		WHERE			(A.database_id <> B.database_id
		OR				A.[source_database_id] <> B.[source_database_id]
		OR				A.[owner_sid] <> B.[owner_sid]
		OR				A.[create_date] <> B.[create_date]
		OR				A.[compatibility_level] <> B.[compatibility_level]
		OR				A.[collation_name] <> B.[collation_name] COLLATE database_default
		OR				A.[user_access] <> B.[user_access]
		OR				A.[user_access_desc] <> B.[user_access_desc] COLLATE database_default
		OR				A.[is_read_only] <> B.[is_read_only]
		OR				A.[is_auto_close_on] <> B.[is_auto_close_on]
		OR				A.[is_auto_shrink_on] <> B.[is_auto_shrink_on]
		OR				A.[state] <> B.[state]
		OR				A.[state_desc] <> B.[state_desc] COLLATE database_default
		OR				A.[is_in_standby] <> B.[is_in_standby]
		OR				A.[is_cleanly_shutdown] <> B.[is_cleanly_shutdown]
		OR				A.[is_supplemental_logging_enabled] <> B.[is_supplemental_logging_enabled]
		OR				A.[snapshot_isolation_state] <> B.[snapshot_isolation_state]
		OR				A.[snapshot_isolation_state_desc] <> B.[snapshot_isolation_state_desc] COLLATE database_default
		OR				A.[is_read_committed_snapshot_on] <> B.[is_read_committed_snapshot_on]
		OR				A.[recovery_model] <> B.[recovery_model]
		OR				A.[recovery_model_desc] <> B.[recovery_model_desc] COLLATE database_default
		OR				A.[page_verify_option] <> B.[page_verify_option]
		OR				A.[page_verify_option_desc] <> B.[page_verify_option_desc] COLLATE database_default
		OR				A.[is_auto_create_stats_on] <> B.[is_auto_create_stats_on]
		OR				A.[is_auto_create_stats_incremental_on] <> B.[is_auto_create_stats_incremental_on]
		OR				A.[is_auto_update_stats_on] <> B.[is_auto_update_stats_on]
		OR				A.[is_auto_update_stats_async_on] <> B.[is_auto_update_stats_async_on]
		OR				A.[is_ansi_null_default_on] <> B.[is_ansi_null_default_on]
		OR				A.[is_ansi_nulls_on] <> B.[is_ansi_nulls_on]
		OR				A.[is_ansi_padding_on] <> B.[is_ansi_padding_on]
		OR				A.[is_ansi_warnings_on] <> B.[is_ansi_warnings_on]
		OR				A.[is_arithabort_on] <> B.[is_arithabort_on]
		OR				A.[is_concat_null_yields_null_on] <> B.[is_concat_null_yields_null_on]
		OR				A.[is_numeric_roundabort_on] <> B.[is_numeric_roundabort_on]
		OR				A.[is_quoted_identifier_on] <> B.[is_quoted_identifier_on]
		OR				A.[is_recursive_triggers_on] <> B.[is_recursive_triggers_on]
		OR				A.[is_cursor_close_on_commit_on] <> B.[is_cursor_close_on_commit_on]
		OR				A.[is_local_cursor_default] <> B.[is_local_cursor_default]
		OR				A.[is_fulltext_enabled] <> B.[is_fulltext_enabled]
		OR				A.[is_trustworthy_on] <> B.[is_trustworthy_on]
		OR				A.[is_db_chaining_on] <> B.[is_db_chaining_on]
		OR				A.[is_parameterization_forced] <> B.[is_parameterization_forced]
		OR				A.[is_master_key_encrypted_by_server] <> B.[is_master_key_encrypted_by_server]
		OR				A.[is_query_store_on] <> B.[is_query_store_on]
		OR				A.[is_published] <> B.[is_published]
		OR				A.[is_subscribed] <> B.[is_subscribed]
		OR				A.[is_merge_published] <> B.[is_merge_published]
		OR				A.[is_distributor] <> B.[is_distributor]
		OR				A.[is_sync_with_backup] <> B.[is_sync_with_backup]
		OR				A.[service_broker_guid] <> B.[service_broker_guid]
		OR				A.[is_broker_enabled] <> B.[is_broker_enabled]
		OR				A.[is_date_correlation_on] <> B.[is_date_correlation_on]
		OR				A.[is_cdc_enabled] <> B.[is_cdc_enabled]
		OR				A.[is_encrypted] <> B.[is_encrypted]
		OR				A.[is_honor_broker_priority_on] <> B.[is_honor_broker_priority_on]
		OR				A.[replica_id] <> B.[replica_id]
		OR				A.[group_database_id] <> B.[group_database_id]
		OR				A.[resource_pool_id] <> B.[resource_pool_id]
		OR				A.[default_language_lcid] <> B.[default_language_lcid]
		OR				A.[default_language_name] <> B.[default_language_name] COLLATE database_default
		OR				A.[default_fulltext_language_lcid] <> B.[default_fulltext_language_lcid]
		OR				A.[default_fulltext_language_name] <> B.[default_fulltext_language_name] COLLATE database_default
		OR				A.[is_nested_triggers_on] <> B.[is_nested_triggers_on]
		OR				A.[is_transform_noise_words_on] <> B.[is_transform_noise_words_on]
		OR				A.[two_digit_year_cutoff] <> B.[two_digit_year_cutoff]
		OR				A.[containment] <> B.[containment]
		OR				A.[containment_desc] <> B.[containment_desc] COLLATE database_default
		OR				A.[target_recovery_time_in_seconds] <> B.[target_recovery_time_in_seconds]
		OR				A.[delayed_durability] <> B.[delayed_durability]
		OR				A.[delayed_durability_desc] <> B.[delayed_durability_desc] COLLATE database_default
		OR				A.[is_memory_optimized_elevate_to_snapshot_on] <> B.[is_memory_optimized_elevate_to_snapshot_on]
		OR				A.[is_federation_member] <> B.[is_federation_member]
		OR				A.[is_remote_data_archive_enabled] <> B.[is_remote_data_archive_enabled]
		OR				A.[is_mixed_page_allocation_on] <> B.[is_mixed_page_allocation_on]
		OR				A.[is_temporal_history_retention_enabled] <> B.[is_temporal_history_retention_enabled]
		OR				A.[catalog_collation_type] <> B.[catalog_collation_type]
		OR				A.[catalog_collation_type_desc] <> B.[catalog_collation_type_desc]
		OR				A.[physical_database_name] <> B.[physical_database_name]
		OR				A.[is_result_set_caching_on] <> B.[is_result_set_caching_on]
		OR				A.[is_accelerated_database_recovery_on] <> B.[is_accelerated_database_recovery_on]
		OR				A.[is_tempdb_spill_to_remote_store] <> B.[is_tempdb_spill_to_remote_store]
		)

		SELECT		@varDatabase_Name = MIN([name]) 
		FROM		sys.databases 
		WHERE		[name] > @varDatabase_Name
END

UPDATE	[dbo].[tblDBMon_SP_Version]
SET		[Last_Executed] = GETDATE()
WHERE	[SP_Name] = OBJECT_NAME(@@PROCID)
GO

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[tblDBMon_SP_Version] WHERE [SP_Name] = 'uspDBMon_MI_GetSysDatabasesChanges')
	BEGIN
		UPDATE	[dbo].[tblDBMon_SP_Version]
		SET		[SP_Version] = '1.0 SD',
				[Last_Executed] = NULL,
				[Date_Modified] = GETDATE(),
				[Modified_By] = SUSER_SNAME()
		WHERE	[SP_Name] = 'uspDBMon_MI_GetSysDatabasesChanges'
	END
ELSE
	BEGIN
		INSERT INTO [dbo].[tblDBMon_SP_Version] ([SP_Name], [SP_Version], [Last_Executed], [Date_Modified], [Modified_By])
		VALUES ('uspDBMon_MI_GetSysDatabasesChanges', '1.0 SD', NULL, GETDATE(), SUSER_SNAME())
	END
GO

EXEC sp_addextendedproperty 
	@name = 'Version', @value = '1.0 SD', 
	@level0type = 'SCHEMA', @level0name = 'dbo', 
	@level1type = 'PROCEDURE', @level1name = 'uspDBMon_MI_GetSysDatabasesChanges'
GO

USE [dba_local]
GO
EXEC [dbo].[uspDBMon_MI_TrackDBAChanges] 'Installed SP: uspDBMon_MI_GetSysDatabasesChanges'
GO
