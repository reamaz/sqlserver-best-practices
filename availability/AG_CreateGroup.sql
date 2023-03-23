/* =====================================================================================
////////////////////////////    DESIGNED BY REAMAZ    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
////////////////////////////    === SQLDATA.RU ===    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
 ===================================================================================== */
 
 
-- step 0 - create endpoint for all replicas
CREATE ENDPOINT Hadr_endpoint  
    STATE=STARTED   
    AS TCP (LISTENER_PORT=5022)   
    FOR DATABASE_MIRRORING (ROLE=ALL);  
GO  

-- step 1 - grant connect to endpoint for SQL Service accounts
GRANT CONNECT ON ENDPOINT::Hadr_endpoint   
   TO [domain_name\user_name];  
GO  

-- step 2 - create availability group
CREATE AVAILABILITY GROUP SPARTAN_AG
   WITH
      (
      AUTOMATED_BACKUP_PREFERENCE = PRIMARY, -- { PRIMARY | SECONDARY_ONLY| SECONDARY | NONE }
      FAILURE_CONDITION_LEVEL = 3 -- { 1 | 2 | 3 | 4 | 5 } 
      --HEALTH_CHECK_TIMEOUT = 30000, -- milliseconds, default = 30000
      --DB_FAILOVER = ON, -- { ON | OFF }
      --DTC_SUPPORT = PER_DB, -- { PER_DB | NONE }
      -- type of AG Group [ BASIC | DISTRIBUTED | CONTAINED [ REUSE_SYSTEM_DATABASES ] ]
      --REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT = 0, -- { integer, 0 = all secondary }
      --CLUSTER_TYPE = WSFC -- { WSFC | EXTERNAL | NONE }
      )    
   FOR   
--      DATABASE MyDB1, MyDB2   -- Join Databases if needed   
   REPLICA ON   
      'SPARTAN1' WITH   
         (  
         ENDPOINT_URL = 'TCP://SPARTAN1.local.net:5022',   
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  --{ SYNCHRONOUS_COMMIT | ASYNCHRONOUS_COMMIT | CONFIGURATION_ONLY }
         FAILOVER_MODE = MANUAL  -- { AUTOMATIC | MANUAL | EXTERNAL }
         -- SEEDING_MODE = MANUAL, -- { AUTOMATIC | MANUAL }
         -- BACKUP_PRIORITY = n,
         -- SECONDARY_ROLE (
         --       ALLOW_CONNECTIONS = ALL, -- { NO | READ_ONLY | ALL }   
         --       READ_ONLY_ROUTING_URL = 'TCP://system-address:port' ]  
         --       ),
         -- PRIMARY_ROLE (   
         --       ALLOW_CONNECTIONS = READ_WRITE, { READ_WRITE | ALL }   
         --       READ_ONLY_ROUTING_LIST = (SERVER1),(SERVER2),  
         --       READ_WRITE_ROUTING_URL = 'TCP://system-address:port' 
         --       ), 
         -- SESSION_TIMEOUT = integer 
         ),
      'SPARTAN2' WITH   
         (  
         ENDPOINT_URL = 'TCP://SPARTAN1.local.net:5022',  
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL  
         -- SEEDING_MODE = MANUAL, -- { AUTOMATIC | MANUAL }
         -- BACKUP_PRIORITY = n,
         -- SECONDARY_ROLE (
         --       ALLOW_CONNECTIONS = ALL, -- { NO | READ_ONLY | ALL }   
         --       READ_ONLY_ROUTING_URL = 'TCP://system-address:port' ]  
         --       ),
         -- PRIMARY_ROLE (   
         --       ALLOW_CONNECTIONS = READ_WRITE, { READ_WRITE | ALL }   
         --       READ_ONLY_ROUTING_LIST = (SERVER1),(SERVER2),  
         --       READ_WRITE_ROUTING_URL = 'TCP://system-address:port' 
         --       ), 
         -- SESSION_TIMEOUT = integer 
         ) 
GO

-- step 3 - create listener on primary replica

ALTER AVAILABILITY GROUP [SPARTAN_AG]
  ADD LISTENER 'SPARTAN_LIST' ( WITH IP ((N'192.168.1.5', N'255.255.255.0')), PORT = 1433);   
GO

-- step 3 - join secondary replicas. On the server instance that hosts the secondary replica, run:

ALTER AVAILABILITY GROUP SPARTAN_AG JOIN;  
GO  
