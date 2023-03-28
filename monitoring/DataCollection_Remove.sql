USE msdb;
GO
  
-- Disable constraints
-- this is done to make sure that constraint logic does not interfere with cleanup process
ALTER TABLE dbo.syscollector_collection_sets_internal
  NOCHECK CONSTRAINT FK_syscollector_collection_sets_collection_sysjobs
ALTER TABLE dbo.syscollector_collection_sets_internal  
  NOCHECK CONSTRAINT FK_syscollector_collection_sets_upload_sysjobs
 
  
-- Delete data collector jobs
DECLARE @job_id uniqueidentifier
DECLARE datacollector_jobs_cursor CURSOR LOCAL
FOR
  SELECT collection_job_id AS job_id FROM syscollector_collection_sets
  WHERE collection_job_id IS NOT NULL
  UNION
  SELECT upload_job_id AS job_id FROM syscollector_collection_sets
  WHERE upload_job_id IS NOT NULL
 
  
OPEN datacollector_jobs_cursor
FETCH NEXT FROM datacollector_jobs_cursor INTO @job_id
 
  
WHILE (@@fetch_status = 0)
BEGIN
  IF EXISTS ( SELECT COUNT(job_id) FROM sysjobs WHERE job_id = @job_id )
  BEGIN
    DECLARE @job_name sysname
    SELECT @job_name = name from sysjobs WHERE job_id = @job_id
    PRINT 'Removing job '+ @job_name
    EXEC dbo.sp_delete_job @job_id=@job_id, @delete_unused_schedule=0
  END
  FETCH NEXT FROM datacollector_jobs_cursor INTO @job_id
END
 
  
CLOSE datacollector_jobs_cursor
DEALLOCATE datacollector_jobs_cursor
 
  
-- Enable Constraints back
ALTER TABLE dbo.syscollector_collection_sets_internal
  CHECK CONSTRAINT FK_syscollector_collection_sets_collection_sysjobs
ALTER TABLE dbo.syscollector_collection_sets_internal
  CHECK CONSTRAINT FK_syscollector_collection_sets_upload_sysjobs
 
  
-- Disable trigger on syscollector_collection_sets_internal
-- this is done to make sure that trigger logic does not interfere with cleanup process
EXEC('DISABLE TRIGGER syscollector_collection_set_is_running_update_trigger
     ON syscollector_collection_sets_internal')
 
  
-- Set collection sets as not running state
UPDATE syscollector_collection_sets_internal
SET is_running = 0
 
  
-- Update collect and upload jobs as null
UPDATE syscollector_collection_sets_internal
SET collection_job_id = NULL, upload_job_id = NULL
 
  
-- Enable back trigger on syscollector_collection_sets_internal
EXEC('ENABLE TRIGGER syscollector_collection_set_is_running_update_trigger
     ON syscollector_collection_sets_internal')
 
  
-- re-set collector config store
UPDATE syscollector_config_store_internal
SET parameter_value = 0
WHERE parameter_name IN ('CollectorEnabled')
 
  
UPDATE syscollector_config_store_internal
SET parameter_value = NULL
WHERE parameter_name IN ( 'MDWDatabase', 'MDWInstance' )
 
  
-- Delete collection set logs
DELETE FROM syscollector_execution_log_internal

EXEC msdb.dbo.sp_delete_job @job_name = N'mdw_purge_data_[DataCollection]';
-- replace MDW within the square brackets with the name you gave your MDW database
 
EXEC msdb.dbo.sp_update_job
        @job_name = N'sysutility_get_cache_tables_data_into_aggregate_tables_daily', 
        @enabled  = 0;
 
          
EXEC msdb.dbo.sp_update_job
        @job_name = N'sysutility_get_cache_tables_data_into_aggregate_tables_hourly',
        @enabled  = 0;
 
EXEC msdb.dbo.sp_update_job
        @job_name = N'sysutility_get_views_data_into_cache_tables',                 
        @enabled  = 0;
 
EXEC msdb.dbo.sp_delete_job
        @job_name = N'sysutility_get_cache_tables_data_into_aggregate_tables_daily';
 
  
EXEC msdb.dbo.sp_delete_job
        @job_name = N'sysutility_get_cache_tables_data_into_aggregate_tables_hourly';
 
          
EXEC msdb.dbo.sp_delete_job
        @job_name = N'sysutility_get_views_data_into_cache_tables';
