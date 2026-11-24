



ALTER DATABASE RiskAssessment SET SINGLE_USER WITH ROLLBACK IMMEDIATE
ALTER DATABASE FundRiskAssessment SET Multi_User




--check recovery model
SELECT name, log_reuse_wait_desc, recovery_model_desc,create_date,compatibility_level,collation_name
FROM sys.databases WHERE NAME = db_name()

SELECT DB_NAME(database_id) [DatabaseName],
name [FileName],
physical_name [FilePath]
FROM sys.master_files
WHERE DB_NAME(database_id) = db_name()



-- to shrink log file
-- if recovery model is full a backuo should be taken
-- if recovery model is simple we can shrink

-- change recovery model
ALTER DATABASE FundShareholders_hesari SET RECOVERY SIMPLE

DBCC SHRINKFILE(FundShareholders_hesari_log, 1024)







-- Remove chached plans

-- First, find the plan handle for your SP
DECLARE @PlanHandle VARBINARY(64);

SELECT @PlanHandle = cp.plan_handle
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
WHERE cp.objtype = 'Proc'
  AND st.dbid = DB_ID()  -- Current database
  AND OBJECT_NAME(st.objectid, st.dbid) = 'SpGetFunds'
  AND OBJECT_SCHEMA_NAME(st.objectid, st.dbid) = 'Common';  -- Your SP name


-- Free that specific plan
IF @PlanHandle IS NOT NULL
    DBCC FREEPROCCACHE(@PlanHandle);







-- This doesn't immediately remove from cache, but marks for recompile
EXEC sp_recompile 'my_sp';  -- Your SP name





-- Declare sp in a way that it recompiles with every execution:

ALTER PROCEDURE [common].[SpGetFunds] 
-- parameteres
with recompile
AS
BEGIN
-- body
END;






-- or recompile just the moment you want execute:
exec [SpGetFunds] with recompile




SELECT TOP 20
	DB_NAME(CONVERT(INT,pa.value)) DbName,
	qs.sql_handle , qs.query_hash,
	OBJECT_NAME(qt.objectid,qt.dbid) ObjectName ,
	SUBSTRING(qt.TEXT, (qs.statement_start_offset/2)+1,((CASE qs.statement_end_offset WHEN -1 THEN DATALENGTH(qt.TEXT) ELSE qs.statement_end_offset END - qs.statement_start_offset)/2)+1) StatementText,
	qt.text , 
	qs.creation_time , qs.last_execution_time , qs.execution_count , DATEDIFF(SECOND,qs.creation_time,GETDATE()) StatDuration_Second ,
	CEILING(qs.total_worker_time /1000 / 1000.0) TotalWorkerTime_Second,qs.last_worker_time /1000 LastWorkerTime_MS,
	qs.total_elapsed_time   / qs.execution_count / 1000 AS Avg_ElapsedTime_MS,
	qs.total_logical_reads  / qs.execution_count AS Avg_LogicalReads,
	qs.total_worker_time    / qs.execution_count / 1000 AS Avg_WorkerTime_MS,
	qs.total_grant_kb / qs.execution_count AS Avg_Memory_Grant_KB ,
	qs.total_used_grant_kb / qs.execution_count AS Avg_Memory_Used_Grant_KB	,
	qs.total_physical_reads / qs.execution_count AS Avg_Read,
	qs.total_logical_writes / qs.execution_count AS Avg_Write
	,qs.total_logical_reads, qs.last_logical_reads,qs.total_logical_writes, qs.last_logical_writes,qs.total_elapsed_time/1000 TotalElapsedTime_MS,qs.last_elapsed_time /1000 LastElapsedTime_MS
	,qs.total_grant_kb , qs.last_grant_kb , qs.total_used_grant_kb , qs.last_used_grant_kb
	,qp.query_plan
FROM sys.dm_exec_query_stats qs
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
	CROSS APPLY sys.dm_exec_plan_attributes(qs.plan_handle) pa
	CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE (DATEDIFF(MINUTE,qs.creation_time,GETDATE()) > 30 OR qs.execution_count > 10) AND pa.attribute = 'dbid' 
	  AND DB_NAME(CONVERT(INT,pa.value)) = 'FundShareholders'
	  --AND qt.text LIKE '%SpGetFunds%'
ORDER BY qs.total_worker_time / CASE WHEN ISNULL(DATEDIFF(SECOND,qs.creation_time,GETDATE()),1) = 0 THEN 1 ELSE ISNULL(DATEDIFF(SECOND,qs.creation_time,GETDATE()),1) END DESC 


