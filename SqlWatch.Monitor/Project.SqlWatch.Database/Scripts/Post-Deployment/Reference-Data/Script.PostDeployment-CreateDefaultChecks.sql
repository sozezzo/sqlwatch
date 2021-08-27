﻿/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/

/* Add check templates first */
declare @check_template table (

	[check_name] [nvarchar](255) NOT NULL,
	[check_description] [nvarchar](2048) NULL,
	[check_query] [nvarchar](max) NOT NULL,
	[check_frequency_minutes] [smallint] NULL,
	[check_threshold_warning] [varchar](100) NULL,
	[check_threshold_critical] [varchar](100) NOT NULL,
	[check_enabled] [bit] NOT NULL,
	[ignore_flapping] [bit] NOT NULL,
	[expand_by] [varchar](50) NULL,
	[use_baseline] bit null
)

insert into @check_template
	values 
	
	--Database {DATABASE} has AUTO_CLOSE Enabled
	(
		--[check_name]
		'Database {DATABASE} AUTO_CLOSE'
	
		--[check_description]
		,'When AUTO_CLOSE is set ON, this option can cause performance degradation on frequently accessed databases because of the increased overhead of opening and closing the database after each connection. AUTO_CLOSE also flushes the procedure cache after each connection.
	https://docs.microsoft.com/en-us/sql/relational-databases/policy-based-management/set-the-auto-close-database-option-to-off
	You can use the below query to see databases with AUTO_CLOSE:
	<code>select * 
	from sys.databases
	where is_auto_close_on = 1</code>'

		--[check_query]
		,'select @output = is_auto_close_on
	from [dbo].[sqlwatch_meta_database]
	where database_name = ''{DATABASE}''
	and sql_instance = ''{SQL_INSTANCE}'''
	
		, 1440 --[check_frequency_minutes]
		, null --[check_threshold_warning]
		,'>0' --[check_threshold_critical]
		,1 --[check_enabled]
		,1 --[ignore_flapping]
		,'Database' --[expand_by]
		,0 -- use_baseline
		),

	--Database page_verify not CHECKSUM
	(
		--[check_name]
		'Database {DATABASE} PAGE_VERIFY'
	
		--[check_description]
		,'When CHECKSUM is enabled for the PAGE_VERIFY database option, the SQL Server Database Engine calculates a checksum over the contents of the whole page, and stores the value in the page header when a page is written to disk. When the page is read from disk, the checksum is recomputed and compared to the checksum value that is stored in the page header. This helps provide a high level of data-file integrity.
https://docs.microsoft.com/en-us/sql/relational-databases/policy-based-management/set-the-page-verify-database-option-to-checksum
<code>page_verify options:
0 = NONE
1 = TORN_PAGE_DETECTION
2 = CHECKSUM
</code>'

		--[check_query]
		,'select @output = page_verify_option
from [dbo].[sqlwatch_meta_database] 
where database_name = ''{DATABASE}''
and sql_instance = ''{SQL_INSTANCE}'''
	
		, 1440 --[check_frequency_minutes]
		, null --[check_threshold_warning]
		,'<>2' --[check_threshold_critical]
		,1 --[check_enabled]
		,1 --[ignore_flapping]
		,'Database' --[expand_by]
		,0 -- use_baseline
		),


	--Databases with Auto Shrink Enabled
	(
		--[check_name]
		'Database {DATABASE} AUTO_SHRINK'
	
		--[check_description]
		,'When you enable this option for a database, this database becomes eligible for shrinking by a background task. This background task evaluates all databases which satisfy the criteria for Shrinking and shrink the data or log files. You have to carefully evaluate setting this option for the databases in a SQL Server instance. Frequent grow and shrink operations can lead to various performance problems and physical fragmentation.
1. If multiple databases undergo frequent shrink and grow operations, then this will easily lead to file system level fragmentation.
2. After AUTO_SHRINK successfully shrinks the data or log file, a subsequent DML or DDL operation can slow down significantly if space is required and the files need to grow.
3. The AUTO_SHRINK background task can take up resources when there are a lot of databases that need shrinking.</p>
4. The AUTO_SHRINK background task will need to acquire locks and other synchronization which can conflict with other regular application activity.

https://docs.microsoft.com/en-us/sql/relational-databases/policy-based-management/set-the-auto-shrink-database-option-to-off
https://support.microsoft.com/en-us/help/2160663/recommendations-and-guidelines-for-setting-the-auto-shrink-database-op

You can use the below query to see databases with AUTO_SHRINK:
<code>select * 
from sys.databases
where is_auto_shrink_on = 1</code>'

		--[check_query]
		,'select @output = is_auto_shrink_on
from [dbo].[sqlwatch_meta_database] 
where sql_instance = ''{SQL_INSTANCE}''
and database_name = ''{DATABASE}'''
	
		, 1440 --[check_frequency_minutes]
		, null --[check_threshold_warning]
		,'>0' --[check_threshold_critical]
		,1 --[check_enabled]
		,1 --[ignore_flapping]
		,'Database' --[expand_by]
		,0 -- use_baseline
		),

	--Databases not ONLINE
	(
		--[check_name]
		'Database {DATABASE} STATE'
	
		--[check_description]
		,'Database State options:
<code>
0 = ONLINE
1 = RESTORING
2 = RECOVERING 1
3 = RECOVERY_PENDING 1
4 = SUSPECT
5 = EMERGENCY 1
6 = OFFLINE 1
7 = COPYING 2
10 = OFFLINE_SECONDARY 2
</code>'

		--[check_query]
		,'select @output = state
from [dbo].[sqlwatch_meta_database]
where sql_instance = ''{SQL_INSTANCE}''
and database_name = ''{DATABASE}'''
	
		, 60 --[check_frequency_minutes]
		, null --[check_threshold_warning]
		,'>0' --[check_threshold_critical]
		,1 --[check_enabled]
		,1 --[ignore_flapping]
		,'Database' --[expand_by]
		,0 -- use_baseline
		),


	--Databases not MULTI_USER
	(
		--[check_name]
		'Database {DATABASE} USER ACCESS'
	
		--[check_description]
		,'Database that is not in MULTI_USER mode, may not be accessible to multiple concurrent users or access is restricted.
user_access setting:
<code>
0 = MULTI_USER
1 = SINGLE_USER
2 = RESTRICTED_USER
</code>'

		--[check_query]
		,'select @output = user_access
from [dbo].[sqlwatch_meta_database]
where sql_instance = ''{SQL_INSTANCE}''
and database_name = ''{DATABASE}'''
	
		, 60 --[check_frequency_minutes]
		, null --[check_threshold_warning]
		,'>0' --[check_threshold_critical]
		,1 --[check_enabled]
		,1 --[ignore_flapping]
		,'Database' --[expand_by]
		,0 -- use_baseline
		),

	--Failed Agent Jobs
	(
		--[check_name]
		'Job {JOB} failure count'
	
		--[check_description]
		,'The number of times that job {JOB} has failed since the last check.
Because we are checking for failure every few minutes, a frequent jobs may fail multiple times.
It would not be enough to just check the last outcome, we have to check the history.'

		--[check_query]
		,'select @output = count(distinct l.sqlwatch_job_id) 
  from [dbo].[sqlwatch_logger_sysjobhistory] l
  inner join sqlwatch_meta_agent_job m
  on m.sql_instance = l.sql_instance
  and m.sqlwatch_job_id = l.sqlwatch_job_id
  where l.run_date_utc >= dateadd(second,-1,''{LAST_CHECK_DATE}'') 
	and l.run_status not in (1,2,4)
	and l.sysjobhistory_step_id > 0
	and m.job_name = ''{JOB}''
	and m.sql_instance = ''{SQL_INSTANCE}''
'
	
		, 10 --[check_frequency_minutes]
		, null --[check_threshold_warning]
		,'>0' --[check_threshold_critical]
		,1 --[check_enabled]
		,1 --[ignore_flapping]
		,'Job' --[expand_by]
		,0 -- use_baseline
		),

	--Disk Free %
	(
		--[check_name]
		'Disk {DISK} free space %'
	
		--[check_description]
		,'The "Free Space %" value is lower than expected. 
This does not mean that the disk will be full soon as it may not grow much. Please check the "days until full" value or the actual growth'

		--[check_query]
		,'select @output=free_space_percentage
from dbo.vw_sqlwatch_report_dim_os_volume
where sql_instance = ''{SQL_INSTANCE}''
and volume_name = ''{DISK}''
and free_space_percentage is not null
'

		, 360 --[check_frequency_minutes]
		,'<0.1' --[check_threshold_warning]
		,'<0.05' --[check_threshold_critical]
		,1 --[check_enabled]
		,1 --[ignore_flapping]
		,'Disk' --[expand_by]
		,0 -- use_baseline
		),

	
	--Days left until disk full
	(
		--[check_name]
		'Disk {DISK} days left until full'
	
		--[check_description]
		,'The "days until full" value is lower than expected. One or more disks will be full in few days.'

		--[check_query]
		,'select @output=days_until_full
from dbo.vw_sqlwatch_report_dim_os_volume
where sql_instance = ''{SQL_INSTANCE}''
and days_until_full is not null
and volume_name = ''{DISK}''
'

		, 1440 --[check_frequency_minutes]
		,'<7' --[check_threshold_warning]
		,'<3' --[check_threshold_critical]
		,1 --[check_enabled]
		,1 --[ignore_flapping]
		,'Disk' --[expand_by]
		,0 -- use_baseline
		),

	--Latest LOG backup age (minutes)
	(
		--[check_name]
		'Database {Database} Log Backup Age'
	
		--[check_description]
		,'The latest log backup is older than expected. 
Databases that are in either FULL or BULK_LOGGED recovery must have frequent Transaction Log backups.
The recovery point will be to the last Transaction Log backup and therefore these must happen often to minimise data loss.
https://docs.microsoft.com/en-us/sql/relational-databases/backup-restore/recovery-models-sql-server

The Script checks if the Database is member of an AVG. Based on the AVG setting the Alarm will Return Last Backup Age only on an expected Node.
Otherwise it will return 0 as Backup age.
HINT for Columns
[msdb].[sys].[availability_replicas].secondary_role_allow_connections
0 NO
1 READ_ONLY
2 ALL

[msdb].[sys].[dm_hadr_availability_replica_states].role
1 Primary Node
2 Secondary Node

[msdb].[sys].[availability_groups].automated_backup_preference
0 Primary
1 Secondary_Only
2 Secondary (Prefer)
3 none (can be done on All)'

		--[check_query]
		,'select @output = isnull(
    min(   case
    when db.recovery_model_desc = ''SIMPLE'' then 0
        -- when DB is in AVG, Current Node is Secondary and Backup Preference is Primary
        when HADR_REP.role = 2
        and AVG_DESC.automated_backup_preference = 0 then 0
    -- when DB is in AVG, Current Node is Secondary and Backup Preference is Prefer Secondary or none (use All) and Secondaries not readable
    when HADR_REP.role = 2
        and AVG_DESC.automated_backup_preference >= 2
        and AVG_REP.secondary_role_allow_connections = 0 then 0
    -- when DB is in AVG, Current Node is Primary and automated_backup_preference on secondary_only and Secondary is Readable -> suggest Backup is done on Secondary,
    when HADR_REP.role = 1
        and AVG_DESC.automated_backup_preference <> 0
        and AVG_REP.secondary_role_allow_connections <> 0 then 0
    else
        datediff(minute, bs.backup_finish_date, getdate())
    end
    )
    , 9999
)
from [msdb].[sys].[databases] as db
    left join [msdb].[sys].[dm_hadr_availability_replica_states] as HADR_REP
        on db.[replica_id] = HADR_REP.[replica_id]
    left join [msdb].[sys].[availability_replicas] as AVG_REP
        on HADR_REP.group_id = AVG_REP.group_id
           and HADR_REP.[replica_id] = AVG_REP.[replica_id]
    left join [msdb].[sys].[availability_groups] as AVG_DESC
        on HADR_REP.[group_id] = AVG_DESC.[group_id]
    left join msdb.dbo.backupset as bs
        on db.name = bs.database_name
           and bs.type = ''L''
where db.name = ''{DATABASE}''
'

		, 10 --[check_frequency_minutes]
		,'>10' --[check_threshold_warning]
		,'>60' --[check_threshold_critical]
		,1 --[check_enabled]
		,1 --[ignore_flapping]
		,'Database' --[expand_by]
		,0 -- use_baseline
		),


	--Latest DATA backup age (days)
	(
		--[check_name]
		'Database {Database} Data Backup Age'
	
		--[check_description]
		,'The Database has no recent backup. The last backup is older than expected.
The Script checks if the Database is member of an AVG. Based on the AVG setting the Alarm will Return Last Backup Age only on an expected Node.
Otherwise it will return 0 as Backup age.
HINT for Columns
[msdb].[sys].[availability_replicas].secondary_role_allow_connections
0 NO
1 READ_ONLY
2 ALL

[msdb].[sys].[dm_hadr_availability_replica_states].role
1 Primary Node
2 Secondary Node

[msdb].[sys].[availability_groups].automated_backup_preference
0 Primary
1 Secondary_Only
2 Secondary (Prefer)
3 none (can be done on All)'

		--[check_query]
		,'select @output = isnull(
    min(   case
    when db.name = ''tempdb'' then 0
    -- when DB is in AVG, Current Node is Secondary and Backup Preference is Primary
    when HADR_REP.role = 2
        and AVG_DESC.automated_backup_preference = 0 then 0
    -- when DB is in AVG, Current Node is Secondary and Backup Preference is Prefer Secondary or none (use All) and Secondaries not readable
    when HADR_REP.role = 2
        and AVG_DESC.automated_backup_preference >= 2
        and AVG_REP.secondary_role_allow_connections = 0 then 0
    -- when DB is in AVG, Current Node is Primary and automated_backup_preference on secondary_only and Secondary is Readable -> suggest Backup is done on Secondary,
    when HADR_REP.role = 1
        and AVG_DESC.automated_backup_preference <> 0
        and AVG_REP.secondary_role_allow_connections <> 0 then 0
    else
        datediff(day, bs.backup_finish_date, getdate())
    end
    )
    , 9999
)
from [msdb].[sys].[databases] as db
    left join [msdb].[sys].[dm_hadr_availability_replica_states] as HADR_REP
        on db.[replica_id] = HADR_REP.[replica_id]
    left join [msdb].[sys].[availability_replicas] as AVG_REP
        on HADR_REP.group_id = AVG_REP.group_id
           and HADR_REP.[replica_id] = AVG_REP.[replica_id]
    left join [msdb].[sys].[availability_groups] as AVG_DESC
        on HADR_REP.[group_id] = AVG_DESC.[group_id]
    left join msdb.dbo.backupset as bs
        on db.name = bs.database_name
           and bs.type <> ''L''
where db.name = ''{DATABASE}''
'

		, 720 --[check_frequency_minutes]
		,'>1' --[check_threshold_warning]
		,'>7' --[check_threshold_critical]
		,1 --[check_enabled]
		,1 --[ignore_flapping]
		,'Database' --[expand_by]
		,0 -- use_baseline
		),

	------------------------------------------------------------------------------------------------------------------------------------
	-- CPU Utilisation
	------------------------------------------------------------------------------------------------------------------------------------
	(
		--[check_name]
		'CPU Utilistaion'
	
		--[check_description]
		,'The average CPU utilistaion is high.
https://docs.microsoft.com/en-us/previous-versions/technet-magazine/cc137784(v=msdn.10)
It is difficult to define what good utilistaion is without knowing the workload and the infrastructure. 
In the Cloud, where CPUs are expesinve we will aim at high utilistaion for BAU workload to save money and with the potential of spinning new instances to handle ad-hoc spikes. 
On-prem utilisation, where adding new nodes is not so easy we must account for spikes and therefore BAU utilisation should be low.'

		--[check_query]
		,'select @output=avg(q.cntr_value_calculated_avg)
from (select pc.snapshot_time, sum(pc.cntr_value_calculated_avg) cntr_value_calculated_avg 
	from  [dbo].[sqlwatch_trend_logger_dm_os_performance_counters] pc
	inner join [dbo].[sqlwatch_meta_dm_os_performance_counters] mpc
		on pc.sql_instance = mpc.sql_instance
		and pc.performance_counter_id = mpc.performance_counter_id
	where mpc.sql_instance = ''{SQL_INSTANCE}''
	  and object_name = ''Win32_PerfFormattedData_PerfOS_Processor''
	  and counter_name = ''Processor Time %''
	  and snapshot_time > ''{LAST_CHECK_DATE}'' 
	  and snapshot_type_id = 33
	group by pc.snapshot_time 
	) q
'

		, 5 --[check_frequency_minutes]
		,'>60' --[check_threshold_warning]
		,'>80' --[check_threshold_critical]
		,1 --[check_enabled]
		,0 --[ignore_flapping]
		,null --[expand_by]
		,1 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- Full Scan Rate
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'Full Scan Rate'
	
		--[check_description]
		,'Monitors the number of full scans on tables or indexes. Ignore unless high CPU coincides with high scan rates. 
High scan rates may be caused by missing indexes, very small tables, or requests for too many records. 
A sudden increase in this value may indicate a statistics threshold has been reached, resulting in an index no longer being used.
The recomended value is 1 Full Scan/sec per 1000 Index Searches/sec or less.'

		--[check_query]
		,'select @output=avg(cntr_value_calculated) 
from [dbo].[vw_sqlwatch_report_fact_perf_os_performance_counters_rate]
where counter_name = ''Full Scan Rate''
and sql_instance = ''{SQL_INSTANCE}''
and snapshot_time > ''{LAST_CHECK_DATE}''
and snapshot_type_id = 33
'

		, 15 --[check_frequency_minutes]
		,'>0.001' --[check_threshold_warning]
		,'>0.01' --[check_threshold_critical]
		,1 --[check_enabled]
		,0 --[ignore_flapping]
		,null --[expand_by]
		,1 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- SQL Compilations Rate
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'SQL Compilations Rate'
	
		--[check_description]
		,'Number of times that Transact-SQL compilations occurred, per second (including recompiles). The lower this value is the better. 
High values often indicate excessive adhoc querying and should be as low as possible. 
If excessive adhoc querying is happening, try rewriting the queries as procedures or invoke the queries using sp_executeSQL. 
When rewriting isn’t possible, consider using a plan guide or setting the database to parameterization forced mode.
The recomended value is < 10% of the number of Batch Requests/Sec'

		--[check_query]
		,'select @output=avg(cntr_value_calculated) 
from [dbo].[vw_sqlwatch_report_fact_perf_os_performance_counters_rate]
where counter_name = ''SQL Compilations Rate''
and sql_instance = ''{SQL_INSTANCE}''
and snapshot_time > ''{LAST_CHECK_DATE}''
and snapshot_type_id = 33
'

		, 15 --[check_frequency_minutes]
		,'>0.10' --[check_threshold_warning]
		,'>0.15' --[check_threshold_critical]
		,1 --[check_enabled]
		,0 --[ignore_flapping]
		,null --[expand_by]
		,1 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- SQL Compilations Rate
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'SQL Re-Compilations Rate'
	
		--[check_description]
		,'Number of times, per second, that Transact-SQL objects attempted to be executed but had to be recompiled before completion. 
This number should be at or near zero, since recompiles can cause deadlocks and exclusive compile locks. 
This counter''s value should follow in proportion to "Batch Requests/sec" and "SQL Compilations/ sec". 
This needs to be nil in your system as much as possible.
The recomended value is < 10% of the number of SQL Compilations/sec'

		--[check_query]
		,'select @output=avg(cntr_value_calculated) 
from [dbo].[vw_sqlwatch_report_fact_perf_os_performance_counters_rate]
where counter_name = ''SQL Re-Compilation Rate''
and sql_instance = ''{SQL_INSTANCE}''
and snapshot_time > ''{LAST_CHECK_DATE}''
and snapshot_type_id = 33
'

		, 15 --[check_frequency_minutes]
		,'>0.10' --[check_threshold_warning]
		,'>0.15' --[check_threshold_critical]
		,1 --[check_enabled]
		,0 --[ignore_flapping]
		,null --[expand_by]
		,1 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- Page Split Rate
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'Page Split Rate'
	
		--[check_description]
		,'Monitors the number of page splits per second which occur due to overflowing index pages and should be as low as possible. 
To avoid page splits, review table and index design to reduce non-sequential inserts or implement fillfactor and pad_index to leave more empty space per page. 
NOTE: A high value for this counter is not bad in situations where many new pages are being created, since it includes new page allocations.
The recomended value is < 20 per 100 Batch Requests/Sec'

		--[check_query]
		,'select @output=avg(cntr_value_calculated) 
from [dbo].[vw_sqlwatch_report_fact_perf_os_performance_counters_rate]
where counter_name = ''Page Split Rate''
and sql_instance = ''{SQL_INSTANCE}''
and snapshot_time > ''{LAST_CHECK_DATE}''
and snapshot_type_id = 33
'

		, 15 --[check_frequency_minutes]
		,'>0.20' --[check_threshold_warning]
		,'>0.25' --[check_threshold_critical]
		,1 --[check_enabled]
		,0 --[ignore_flapping]
		,null --[expand_by]
		,1 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- Free list stalls/sec
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'Free list stalls/sec'
	
		--[check_description]
		,'Monitors the number of requests per second where data requests stall because no buffers are available. 
Any value above 2 means SQL Server needs more memory.number of requests per second where data requests stall because no buffers are available. 
The recomended value is < 2'

		--[check_query]
		,'select @output=avg(pc.cntr_value_calculated_avg)
from [dbo].[sqlwatch_trend_logger_dm_os_performance_counters] pc
inner join [dbo].[sqlwatch_meta_dm_os_performance_counters] mpc
	on pc.sql_instance = mpc.sql_instance
	and pc.performance_counter_id = mpc.performance_counter_id
where mpc.sql_instance = ''{SQL_INSTANCE}''
  and counter_name = ''Free list stalls/sec''
and snapshot_time > ''{LAST_CHECK_DATE}''
and snapshot_type_id = 33
'

		, 15 --[check_frequency_minutes]
		,'>2' --[check_threshold_warning]
		,'>5' --[check_threshold_critical]
		,1 --[check_enabled]
		,0 --[ignore_flapping]
		,null --[expand_by]
		,1 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- Lazy writes/sec
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'Lazy writes/sec'
	
		--[check_description]
		,'Monitors the number of times per second that the Lazy Writer process moves dirty pages from the buffer to disk as it frees up buffer space. 
Lower is better with zero being ideal. When greater than 20, this counter indicates a need for more memory.	
The recomended value is < 20'

		--[check_query]
		,'select @output=avg(pc.cntr_value_calculated_avg)
from [dbo].[sqlwatch_trend_logger_dm_os_performance_counters] pc
inner join [dbo].[sqlwatch_meta_dm_os_performance_counters] mpc
	on pc.sql_instance = mpc.sql_instance
	and pc.performance_counter_id = mpc.performance_counter_id
where mpc.sql_instance = ''{SQL_INSTANCE}''
  and counter_name = ''Lazy writes/sec''
and snapshot_time > ''{LAST_CHECK_DATE}''
and snapshot_type_id = 33
'

		, 15 --[check_frequency_minutes]
		,'>20' --[check_threshold_warning]
		,'>25' --[check_threshold_critical]
		,1 --[check_enabled]
		,0 --[ignore_flapping]
		,null --[expand_by]
		,1 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- Page reads/sec
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'Page reads/sec'
	
		--[check_description]
		,'Number of physical database page reads issued per second. 
Normal OLTP workloads support 80 – 90 per second, but higher values may be a yellow flag for poor indexing or insufficient memory.	
The recomended value is < 90'

		--[check_query]
		,'select @output=avg(pc.cntr_value_calculated_avg)
from [dbo].[sqlwatch_trend_logger_dm_os_performance_counters] pc
inner join [dbo].[sqlwatch_meta_dm_os_performance_counters] mpc
	on pc.sql_instance = mpc.sql_instance
	and pc.performance_counter_id = mpc.performance_counter_id
where mpc.sql_instance = ''{SQL_INSTANCE}''
  and counter_name = ''Page reads/sec''
and snapshot_time > ''{LAST_CHECK_DATE}''
and snapshot_type_id = 33
'

		, 15 --[check_frequency_minutes]
		,'>90' --[check_threshold_warning]
		,'>120' --[check_threshold_critical]
		,1 --[check_enabled]
		,0 --[ignore_flapping]
		,null --[expand_by]
		,1 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- Page Lookups Rate
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'Page Lookups Rate'
	
		--[check_description]
		,'The number of requests to find a page in the buffer pool. 
When the ratio of batch requests to page lookups crests 100, you may have inefficient execution plans or too many adhoc queries.
The recomended value is (Page lookups/ sec) / (Batch Requests/ sec) < 100'

		--[check_query]
		,'select @output=avg(cntr_value_calculated) 
from [dbo].[vw_sqlwatch_report_fact_perf_os_performance_counters_rate]
where counter_name = ''Page Lookups Rate''
and sql_instance = ''{SQL_INSTANCE}''
and snapshot_time > ''{LAST_CHECK_DATE}''
and snapshot_type_id = 33

'

		, 15 --[check_frequency_minutes]
		,'>100' --[check_threshold_warning]
		,'>120' --[check_threshold_critical]
		,1 --[check_enabled]
		,0 --[ignore_flapping]
		,null --[expand_by]
		,1 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- Page writes/sec
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'Page writes/sec'
	
		--[check_description]
		,'Number of database pages physically written to disk per second. 
Normal OLTP workloads support 80 – 90 per second. Values over 90 should be crossed checked with "lazy writer/sec" and "checkpoint" counters. 
If the other counters are also high, then it may indicate insufficient memory.
The recomended value is < 90'

		--[check_query]
		,'select @output=avg(pc.cntr_value_calculated_avg)
from [dbo].[sqlwatch_trend_logger_dm_os_performance_counters] pc
inner join [dbo].[sqlwatch_meta_dm_os_performance_counters] mpc
	on pc.sql_instance = mpc.sql_instance
	and pc.performance_counter_id = mpc.performance_counter_id
where mpc.sql_instance = ''{SQL_INSTANCE}''
  and counter_name in (''Page writes/sec'')
and snapshot_time > ''{LAST_CHECK_DATE}''
and snapshot_type_id = 33
'

		, 15 --[check_frequency_minutes]
		,'>90' --[check_threshold_warning]
		,'>120' --[check_threshold_critical]
		,1 --[check_enabled]
		,0 --[ignore_flapping]
		,null --[expand_by]
		,1 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- Average Wait Time (ms)
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'Average Wait Time (ms)'
	
		--[check_description]
		,'The average wait time, in milliseconds, for each lock request that had to wait. 
An average wait time longer than 500ms may indicate excessive blocking. 
This value should generally correlate to "Lock Waits/sec" and move up or down with it accordingly.
The recomended value is <500'

		--[check_query]
		,'select @output=avg(pc.cntr_value_calculated_avg)
from [dbo].[sqlwatch_trend_logger_dm_os_performance_counters] pc
inner join [dbo].[sqlwatch_meta_dm_os_performance_counters] mpc
	on pc.sql_instance = mpc.sql_instance
	and pc.performance_counter_id = mpc.performance_counter_id
where mpc.sql_instance = ''{SQL_INSTANCE}''
  and counter_name in (''Average Wait Time (ms)'')
and snapshot_time > ''{LAST_CHECK_DATE}''
and snapshot_type_id = 33
'

		, 15 --[check_frequency_minutes]
		,'>500' --[check_threshold_warning]
		,'>1000' --[check_threshold_critical]
		,1 --[check_enabled]
		,0 --[ignore_flapping]
		,null --[expand_by]
		,1 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- Lock Requests/sec
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'Lock Requests/sec'
	
		--[check_description]
		,'The number of new locks and locks converted per second. 
This metric''s value should generally correspond to "Batch Requests/sec". 
Values > 1000 may indicate queries are accessing very large numbers of rows and may benefit from tuning.
The recomended value is < 1000'

		--[check_query]
		,'select @output=avg(pc.cntr_value_calculated_avg)
from [dbo].[sqlwatch_trend_logger_dm_os_performance_counters] pc
inner join [dbo].[sqlwatch_meta_dm_os_performance_counters] mpc
	on pc.sql_instance = mpc.sql_instance
	and pc.performance_counter_id = mpc.performance_counter_id
where mpc.sql_instance = ''{SQL_INSTANCE}''
  and counter_name in (''Lock Requests/sec'')
and snapshot_time > ''{LAST_CHECK_DATE}''
and snapshot_type_id = 33
'

		, 15 --[check_frequency_minutes]
		,'>1000' --[check_threshold_warning]
		,'>1200' --[check_threshold_critical]
		,1 --[check_enabled]	
		,0 --[ignore_flapping]
		,null --[expand_by]
		,1 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- Lock Timeouts/sec
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'Lock Timeouts/sec'
	
		--[check_description]
		,'Shows the number of lock requests per second that timed out, including internal requests for NOWAIT locks. 
A value greater than zero might indicate that user queries are not completing. The lower this value is, the better.
The recomended value is <1'

		--[check_query]
		,'select @output=avg(pc.cntr_value_calculated_avg)
from [dbo].[sqlwatch_trend_logger_dm_os_performance_counters] pc
inner join [dbo].[sqlwatch_meta_dm_os_performance_counters] mpc
	on pc.sql_instance = mpc.sql_instance
	and pc.performance_counter_id = mpc.performance_counter_id
where mpc.sql_instance = ''{SQL_INSTANCE}''
  and counter_name in (''Lock Timeouts/sec'')
and snapshot_time > ''{LAST_CHECK_DATE}''
and snapshot_type_id = 33
'

		, 15 --[check_frequency_minutes]
		,'>0' --[check_threshold_warning]
		,'>1' --[check_threshold_critical]
		,1 --[check_enabled]	
		,0 --[ignore_flapping]
		,null --[expand_by]
		,1 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- Lock Waits/sec
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'Lock Waits/sec'
	
		--[check_description]
		,'How many times users waited to acquire a lock over the past second. 
Values greater than zero indicate at least some blocking is occurring, while a value of zero can quickly eliminate blocking as a potential root-cause problem. 
As with "Lock Wait Time", lock waits are not recorded by PerfMon until after the lock event completes.
The recomended value is 0'

		--[check_query]
		,'select @output=avg(pc.cntr_value_calculated_avg)
from [dbo].[sqlwatch_trend_logger_dm_os_performance_counters] pc
inner join [dbo].[sqlwatch_meta_dm_os_performance_counters] mpc
	on pc.sql_instance = mpc.sql_instance
	and pc.performance_counter_id = mpc.performance_counter_id
where mpc.sql_instance = ''{SQL_INSTANCE}''
  and counter_name in (''Lock Waits/sec'')
and snapshot_time > ''{LAST_CHECK_DATE}''
and snapshot_type_id = 33
'

		, 15 --[check_frequency_minutes]
		,'>0.1' --[check_threshold_warning]
		,'>=1' --[check_threshold_critical]
		,1 --[check_enabled]	
		,0 --[ignore_flapping]
		,null --[expand_by]
		,1 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- Readahead pages/sec
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'Readahead pages/sec'
	
		--[check_description]
		,'Number of data pages read per second in anticipation of their use. 
If this value is makes up even a sizeable minority of total Page Reads/sec (say, greater than 20% of total page reads), you may have too many physical reads occurring.
The recomended value is < 20% of Page Reads/ sec'

		--[check_query]
		,'select @output=case when avg(case when counter_name = ''Page reads/sec'' then pc.cntr_value_calculated_avg else null end) > 0 then 
	avg(case when counter_name = ''Readahead pages/sec'' then pc.cntr_value_calculated_avg else null end) / avg(case when counter_name = ''Page reads/sec'' then pc.cntr_value_calculated_avg else null end) else 0 end
from [dbo].[sqlwatch_trend_logger_dm_os_performance_counters] pc
inner join [dbo].[sqlwatch_meta_dm_os_performance_counters] mpc
	on pc.sql_instance = mpc.sql_instance
	and pc.performance_counter_id = mpc.performance_counter_id
where mpc.sql_instance = ''{SQL_INSTANCE}''
  and counter_name in (''Readahead pages/sec'',''Page reads/sec'')
and snapshot_time > ''{LAST_CHECK_DATE}''
and snapshot_type_id = 33
'

		, 15 --[check_frequency_minutes]
		,'>20' --[check_threshold_warning]
		,'>25' --[check_threshold_critical]
		,1 --[check_enabled]	
		,0 --[ignore_flapping]
		,null --[expand_by]
		,1 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- Number of Deadlocks/sec
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'Number of Deadlocks/sec'
	
		--[check_description]
		,'Number of lock requests, per second, which resulted in a deadlock. 
Since only a COMMIT, ROLLBACK, or deadlock can terminate a transaction (excluding failures or errors), this is an important value to track. 
Excessive deadlocking indicates a table or index design error or bad application design.
The recomended value is <1'

		--[check_query]
		,'select @output=avg(pc.cntr_value_calculated_avg)
from [dbo].[sqlwatch_trend_logger_dm_os_performance_counters] pc
inner join [dbo].[sqlwatch_meta_dm_os_performance_counters] mpc
	on pc.sql_instance = mpc.sql_instance
	and pc.performance_counter_id = mpc.performance_counter_id
where mpc.sql_instance = ''{SQL_INSTANCE}''
  and counter_name in (''Number of Deadlocks/sec'')
and snapshot_time > ''{LAST_CHECK_DATE}''
and snapshot_type_id = 33
'

		, 15 --[check_frequency_minutes]
		,'>0' --[check_threshold_warning]
		,'>1' --[check_threshold_critical]
		,1 --[check_enabled]	
		,0 --[ignore_flapping]
		,null --[expand_by]
		,1 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- Memory Grants Outstanding
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'Memory Grants Outstanding'
	
		--[check_description]
		,'Total number of processes per second that have successfully acquired a workspace memory grant.
The recomended value is < 1'

		--[check_query]
		,'select @output=avg(pc.cntr_value_calculated_avg)
from [dbo].[sqlwatch_trend_logger_dm_os_performance_counters] pc
inner join [dbo].[sqlwatch_meta_dm_os_performance_counters] mpc
	on pc.sql_instance = mpc.sql_instance
	and pc.performance_counter_id = mpc.performance_counter_id
where mpc.sql_instance = ''{SQL_INSTANCE}''
  and counter_name in (''Memory Grants Outstanding'')
and snapshot_time > ''{LAST_CHECK_DATE}''
and snapshot_type_id = 33
'

		, 15 --[check_frequency_minutes]
		,'>0' --[check_threshold_warning]
		,'>1' --[check_threshold_critical]
		,1 --[check_enabled]	
		,0 --[ignore_flapping]
		,null --[expand_by]
		,1 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- Memory Grants Pending
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'Memory Grants Pending'
	
		--[check_description]
		,'Total number of processes per second waiting for a workspace memory grant. Numbers higher than 0 indicate a lack of memory.
The recomended value is < 1'

		--[check_query]
		,'select @output=avg(pc.cntr_value_calculated_avg)
from [dbo].[sqlwatch_trend_logger_dm_os_performance_counters] pc
inner join [dbo].[sqlwatch_meta_dm_os_performance_counters] mpc
	on pc.sql_instance = mpc.sql_instance
	and pc.performance_counter_id = mpc.performance_counter_id
where mpc.sql_instance = ''{SQL_INSTANCE}''
  and counter_name in (''Memory Grants Pending'')
and snapshot_time > ''{LAST_CHECK_DATE}''
and snapshot_type_id = 33
'

		, 15 --[check_frequency_minutes]
		,'>0' --[check_threshold_warning]
		,'>1' --[check_threshold_critical]
		,1 --[check_enabled]	
		,0 --[ignore_flapping]
		,null --[expand_by]
		,1 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- Buffer cache hit ratio
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'Buffer cache hit ratio'
	
		--[check_description]
		,'Long a stalwart counter used by SQL Server DBAs, this counter is no longer very useful. 
It monitors the percentage of data requests answer from the buffer cache since the last reboot. 
However, other counters are much better for showing current memory pressure that this one because it blows the curve. 
For example, PLE (page life expectancy) might suddenly drop from 2000 to 70, while buffer cache hit ration moves only from 98.2 to 98.1. 
Only be concerned by this counter if it''s value is regularly below 90 (for OLTP) or 80 (for very large OLAP).
The recomended value is 100'

		--[check_query]
		,'select @output=avg(pc.cntr_value_calculated_avg)
from [dbo].[sqlwatch_trend_logger_dm_os_performance_counters] pc
inner join [dbo].[sqlwatch_meta_dm_os_performance_counters] mpc
	on pc.sql_instance = mpc.sql_instance
	and pc.performance_counter_id = mpc.performance_counter_id
where mpc.sql_instance = ''{SQL_INSTANCE}''
  and counter_name in (''Buffer cache hit ratio'')
and snapshot_time > ''{LAST_CHECK_DATE}''
and snapshot_type_id = 33
'

		, 15 --[check_frequency_minutes]
		,'<95' --[check_threshold_warning]
		,'<90' --[check_threshold_critical]
		,1 --[check_enabled]	
		,0 --[ignore_flapping]
		,null --[expand_by]
		,1 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- Page life expectancy
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'Page life expectancy'
	
		--[check_description]
		,'Tells, on average, how many seconds SQL Server expects a data page to stay in cache. 
The target on an OLTP system should be at least 300 (5 min). 
When under 300, this may indicate poor index design (leading to increased disk I/O and less effective use of memory) or, simply, a potential shortage of memory.
The recomended value is >300'

		--[check_query]
		,'select @output=avg(pc.cntr_value_calculated_avg)
from [dbo].[sqlwatch_trend_logger_dm_os_performance_counters] pc
inner join [dbo].[sqlwatch_meta_dm_os_performance_counters] mpc
	on pc.sql_instance = mpc.sql_instance
	and pc.performance_counter_id = mpc.performance_counter_id
where mpc.sql_instance = ''{SQL_INSTANCE}''
  and counter_name in (''Page life expectancy'')
and snapshot_time > ''{LAST_CHECK_DATE}''
and snapshot_type_id = 33
'

		, 15 --[check_frequency_minutes]
		,'<300' --[check_threshold_warning]
		,'<200' --[check_threshold_critical]
		,1 --[check_enabled]	
		,0 --[ignore_flapping]
		,null --[expand_by]
		,1 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- Logins/sec
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'Logins/sec'
	
		--[check_description]
		,'The number of user logins per second. Any value over 2 may indicate insufficient connection pooling.
The recomended value is <2'

		--[check_query]
		,'select @output=avg(pc.cntr_value_calculated_avg)
from [dbo].[sqlwatch_trend_logger_dm_os_performance_counters] pc
inner join [dbo].[sqlwatch_meta_dm_os_performance_counters] mpc
	on pc.sql_instance = mpc.sql_instance
	and pc.performance_counter_id = mpc.performance_counter_id
where mpc.sql_instance = ''{SQL_INSTANCE}''
  and counter_name in (''Logins/sec'')
and snapshot_time > ''{LAST_CHECK_DATE}''
and snapshot_type_id = 33
'

		, 15 --[check_frequency_minutes]
		,'>2' --[check_threshold_warning]
		,'>5' --[check_threshold_critical]
		,1 --[check_enabled]	
		,0 --[ignore_flapping]
		,null --[expand_by]
		,1 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- Errors/sec
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'Errors/sec'
	
		--[check_description]
		,'Number of errors per second which takes a database offline or kills a user connection, respectively. 
Since these are severe errors, they should occur very infrequently.
The recomended value is 0'

		--[check_query]
		,'select @output=avg(pc.cntr_value_calculated_avg)
from [dbo].[sqlwatch_trend_logger_dm_os_performance_counters] pc
inner join [dbo].[sqlwatch_meta_dm_os_performance_counters] mpc
	on pc.sql_instance = mpc.sql_instance
	and pc.performance_counter_id = mpc.performance_counter_id
where mpc.sql_instance = ''{SQL_INSTANCE}''
  and counter_name in (''Errors/sec'')
  and instance_name <> ''User Errors''
and snapshot_time > ''{LAST_CHECK_DATE}''
and snapshot_type_id = 33
'

		, 15 --[check_frequency_minutes]
		,'>0' --[check_threshold_warning]
		,'>1' --[check_threshold_critical]
		,1 --[check_enabled]	
		,0 --[ignore_flapping]
		,null --[expand_by]
		,0 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- Log Growths
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'Log Growths'
	
		--[check_description]
		,'Total number of times the transaction log for the database has been expanded. 
Each time the transaction log grows, all user activity must halt until the log growth completes. 
Therefore, you want log growths to occur during predefined maintenance windows rather than during general working hours.
You can ignore and disable this check if you have Instant file Initialisation enabled.
https://docs.microsoft.com/en-us/sql/relational-databases/databases/database-instant-file-initialization
Please note that this performance counter shows a total of log growths in the past, i.e. once the log has grown at least one time, it will always show positive number causing this check to always fail.
To be notified about every grow event, we can set @action_every_failure = 1 but this will also trigger action if the number decreases (ie. database when is removed)
The recomended value is 0'

		--[check_query]
		,'select @output=avg(pc.cntr_value_calculated_avg)
from [dbo].[sqlwatch_trend_logger_dm_os_performance_counters] pc
inner join [dbo].[sqlwatch_meta_dm_os_performance_counters] mpc
	on pc.sql_instance = mpc.sql_instance
	and pc.performance_counter_id = mpc.performance_counter_id
where mpc.sql_instance = ''{SQL_INSTANCE}''
  and counter_name in (''Log Growths'')
and snapshot_time > ''{LAST_CHECK_DATE}''
and snapshot_type_id = 33
'

		, 15 --[check_frequency_minutes]
		,null --[check_threshold_warning]
		,'>{LAST_CHECK_VALUE}'  --[check_threshold_critical]
		,1 --[check_enabled]	
		,0 --[ignore_flapping]
		,null --[expand_by]
		,0 -- use_baseline
		)
	------------------------------------------------------------------------------------------------------------------------------------
	-- dbachecks failed
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'dbachecks failed'
	
		--[check_description]
		,'This check looks up any dbachceks that have a result of failed. Please check the dbachecks dashboard or tables for details.'

		--[check_query]
		,'select @output=count(*)
from [dbo].[dbachecksResults]
where Result = ''Failed'' AND [Date] >= ''{LAST_CHECK_DATE}''
'

		, 60 --[check_frequency_minutes]
		,null --[check_threshold_warning]
		,'>0'  --[check_threshold_critical]
		,1 --[check_enabled]	
		,0 --[ignore_flapping]
		,null --[expand_by]
		,0 -- use_baseline
		)

	------------------------------------------------------------------------------------------------------------------------------------
	-- Check execution time
	------------------------------------------------------------------------------------------------------------------------------------
	,
	(
		--[check_name]
		'Check execution time'
	
		--[check_description]
		,'There are checks that take over 1 second to execute on average. 
Make sure checks tare lightweight and do not use up lots of resources and time. 
Checks are executed in series, in a single threaded cursor and not parralel. 
This means that 10 checks taking 1 second each will in total take 10 seconds to run. 
Each check should not take more than few miliseconds to run.
You can view average check execution time in [dbo].[vw_sqlwatch_report_dim_check] and individual runs in [dbo].[sqlwatch_logger_check]'

		--[check_query]
		,'select @output=max([avg_check_exec_time_ms])
from [dbo].[vw_sqlwatch_report_dim_check]
where target_sql_instance = ''{SQL_INSTANCE}''
'
		, 15 --[check_frequency_minutes]
		,null --[check_threshold_warning]
		,'>1000'  --[check_threshold_critical]
		,1 --[check_enabled]	
		,0 --[ignore_flapping]
		,null --[expand_by]
		,0 -- use_baseline
		)
;
merge [dbo].[sqlwatch_config_check_template] as target
using @check_template as source
on target.[check_name] = source.[check_name]


when matched and target.[user_modified] = 0 then
	update set
		 [check_description] = source.[check_description]
		,[check_query] = source.[check_query]
		,[check_frequency_minutes] = source.[check_frequency_minutes]
		,[check_threshold_warning] = source.[check_threshold_warning]
		,[check_threshold_critical] = source.[check_threshold_critical]
		,[check_enabled] = source.[check_enabled]
		,[ignore_flapping] = source.[ignore_flapping]
		,[expand_by] = source.[expand_by]
		,use_baseline = source.use_baseline

when not matched then
	insert ([check_name],[check_description],[check_query],[check_frequency_minutes],[check_threshold_warning],[check_threshold_critical],
	[check_enabled],[ignore_flapping],[expand_by], [user_modified], [template_enabled], use_baseline)
	values (source.[check_name],source.[check_description],source.[check_query],source.[check_frequency_minutes],source.[check_threshold_warning]
	,source.[check_threshold_critical],source.[check_enabled],source.[ignore_flapping],source.[expand_by],0, 1, source.use_baseline);


--disable trigger dbo.trg_sqlwatch_config_check_U on [dbo].[sqlwatch_config_check];
--disable trigger dbo.trg_sqlwatch_config_check_action_updated_date_U on [dbo].[sqlwatch_config_check_action];
disable trigger dbo.trg_sqlwatch_config_check_negative_id on [dbo].[sqlwatch_config_check];
set identity_insert [dbo].[sqlwatch_config_check] on;

--------------------------------------------------------------------------------------

exec [dbo].[usp_sqlwatch_config_add_check]
	 @check_id = -2
	,@check_name = 'Blocked Process'
	,@check_description = 'One or more blocking chains have been detected.
Blocking means processes are stuck and unable to carry any work, could cause downtime or major outage.
If there is a report assosiated with this check, details of the blocking chain should be included below.'
	,@check_query = 'select @output=count(distinct blocked_spid)
from dbo.sqlwatch_logger_xes_blockers b
where snapshot_time >= ''{LAST_CHECK_DATE}'''
	,@check_frequency_minutes = NULL
	,@check_threshold_warning = NULL
	,@check_threshold_critical = '>0'
	,@check_enabled = 1
	,@check_action_id = -8

	,@action_every_failure = 1
	,@action_recovery = 0
	,@action_repeat_period_minutes = 1
	,@action_hourly_limit = 60
	,@action_template_id = -2

--------------------------------------------------------------------------------------

merge [dbo].[sqlwatch_config_check_template_action] as target
using @check_template as source
on source.[check_name] = target.[check_name]

when not matched then
	insert (
		[check_name]
      ,[action_id]
      ,[action_every_failure]
      ,[action_recovery]
      ,[action_repeat_period_minutes]
      ,[action_hourly_limit]
      ,[action_template_id]
	  )
	values (
		source.check_name,
		-3,
		0,
		1,
		600,
		2,
		-4
	);

set identity_insert [dbo].[sqlwatch_config_check] off;
--enable trigger dbo.trg_sqlwatch_config_check_U on [dbo].[sqlwatch_config_check];
--enable trigger dbo.trg_sqlwatch_config_check_action_updated_date_U on [dbo].[sqlwatch_config_check_action];
enable trigger dbo.trg_sqlwatch_config_check_negative_id on [dbo].[sqlwatch_config_check];
