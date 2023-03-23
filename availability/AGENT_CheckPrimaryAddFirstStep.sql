/* =====================================================================================
////////////////////////////    DESIGNED BY REAMAZ    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
////////////////////////////    === SQLDATA.RU ===    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
 ===================================================================================== */

use master
go
 
-- Create procedure to Add first step to SQL Agent.
 
create procedure dbo.usp_AddAGPrimaryCheckStepToAgentJob
    @jobname nvarchar(128)
as
 
set nocount on;
 
-- AG Group check
IF SERVERPROPERTY ('IsHadrEnabled') = 1
begin
    declare @jobid uniqueidentifier = (select sj.job_id from msdb.dbo.sysjobs sj where sj.name = @jobname)
 
    if not exists(select * from msdb.dbo.sysjobsteps where job_id = @jobid and step_name = 'Check If AG Primary' )
    begin
        -- Add new first step: on success go to next step, on failure quit reporting success
        exec msdb.dbo.sp_add_jobstep 
          @job_id = @jobid
        , @step_id = 1
        , @cmdexec_success_code = 0
        , @step_name = 'Check If AG Primary'
        , @on_success_action = 3  -- On success, go to Next Step
        , @on_success_step_id = 2
        , @on_fail_action = 1     -- On failure, Quit with Success  
        , @on_fail_step_id = 0
        , @retry_attempts = 0
        , @retry_interval = 0
        , @os_run_priority = 0
        , @subsystem = N'TSQL'
        , @command=N'IF (SELECT ars.role_desc
        FROM sys.dm_hadr_availability_replica_states ars
        JOIN sys.availability_groups ag ON ars.group_id = ag.group_id AND ars.is_local = 1) <> ''Primary''
    BEGIN
       -- Secondary node, throw an error
       raiserror (''Not the AG primary'', 2, 1)
    END'
        , @database_name=N'master'
        , @flags=0
    end
end
GO
 
-- =====================================================================================
 
-- Cursor by all Agents Jobs with execute usp_AddAGPrimaryCheckStepToAgentJob
 
DECLARE @jobName NVARCHAR(128)
 
DECLARE jobCursor CURSOR LOCAL FAST_FORWARD
FOR
    SELECT j.name FROM msdb.dbo.sysjobs j
    --WHERE ??? -- filter out any jobs here
 
OPEN jobCursor 
FETCH NEXT FROM jobCursor INTO @jobName
 
WHILE @@FETCH_STATUS = 0
BEGIN
    exec usp_AddAGPrimaryCheckStepToAgentJob @jobName
 
    FETCH NEXT FROM jobCursor INTO @jobName
END
 
CLOSE jobCursor
DEALLOCATE jobCursor
GO
 
/* =====================================================================================
   Remove the first job step ''Check If AG Primary'' added in previous snippet
   Just here should you want to remove the step added in snippet above. 
 ===================================================================================== */
 
DECLARE @jobName NVARCHAR(128)
 
DECLARE jobCursor CURSOR LOCAL FAST_FORWARD
FOR
    SELECT j.name FROM msdb.dbo.sysjobs j
    join msdb.dbo.sysjobsteps js on js.job_id = j.job_id
    where js.step_name = 'Check If AG Primary' and js.step_id = 1
 
OPEN jobCursor 
FETCH NEXT FROM jobCursor INTO @jobName
 
WHILE @@FETCH_STATUS = 0
BEGIN
     
    EXEC msdb.dbo.sp_delete_jobstep  
        @job_name = @jobName,  
        @step_id = 1 ;  
     
    FETCH NEXT FROM jobCursor INTO @jobName
END
 
CLOSE jobCursor
DEALLOCATE jobCursor
GO
