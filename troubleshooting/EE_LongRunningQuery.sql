/* =====================================================================================
////////////////////////////    DESIGNED BY REAMAZ    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
////////////////////////////    === SQLDATA.RU ===    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
 ===================================================================================== */

CREATE EVENT SESSION [Long-Running Queries] ON SERVER
ADD EVENT sqlserver.rpc_completed (
    ACTION ( sqlserver.client_app_name, sqlserver.client_hostname,
    sqlserver.database_id, sqlserver.database_name, sqlserver.nt_username,
    sqlserver.query_hash, sqlserver.server_principal_name,
    sqlserver.session_id, sqlserver.sql_text )
    WHERE ( ( ( package0.greater_than_uint64(sqlserver.database_id, ( 4 )) )
              AND ( package0.equal_boolean(sqlserver.is_system, ( 0 )) ) )
            AND ( duration >= ( 20000000 ) )  -- equals 20 sec
          ) ),
ADD EVENT sqlserver.sql_batch_completed (SET collect_batch_text = ( 1 )
    ACTION ( sqlserver.client_app_name, sqlserver.database_id,
    sqlserver.query_hash, sqlserver.session_id )
    WHERE ( ( ( package0.greater_than_uint64(sqlserver.database_id, ( 4 )) )
              AND ( package0.equal_boolean(sqlserver.is_system, ( 0 )) ) )
            AND ( duration >= ( 20000000 ) )  -- equals 20 sec
          ) )
ADD TARGET package0.event_file
(SET filename = N'C:\MyFolder\Long-Running Queries'
, max_file_size = ( 100 ) ),
ADD TARGET package0.ring_buffer
WITH ( MAX_MEMORY = 4096 KB
      , EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS
      , MAX_DISPATCH_LATENCY = 30 SECONDS
      , MAX_EVENT_SIZE = 0 KB
      , MEMORY_PARTITION_MODE = NONE
      , TRACK_CAUSALITY = ON
      , STARTUP_STATE = ON );
GO
ALTER EVENT SESSION [Long-Running Queries] ON SERVER STATE=START;
GO 
