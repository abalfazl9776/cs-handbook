-------------------------------------Multi RUN-------------------------------------
--SET STATISTICS IO ON;
----------------------
-- YOUR QUERY STARTS--
----------------------



----------------------
-- YOUR QUERY ENDS  --
----------------------
GO
--Diagnostics cpu time - logical read

IF OBJECT_ID('tempdb..#diagResults') IS NULL
	CREATE TABLE #diagResults(id INT IDENTITY,
	cpu_time INT,
	logical_reads INT,
	total_elapsed_time INT);

INSERT INTO #diagResults
SELECT 
es.cpu_time,
es.logical_reads,
es.total_elapsed_time
FROM sys.dm_exec_sessions AS es
CROSS APPLY sys.dm_exec_input_buffer(es.session_id, NULL) AS ib
WHERE es.session_id = @@SPID;

DECLARE @id INT;
SELECT TOP 1 @id = id FROM #diagResults ORDER BY id DESC;
SELECT cpu_time - (SELECT COALESCE(SUM(cpu_time), 0) FROM #diagResults WHERE id < @id) AS cpu_time,
       logical_reads - (SELECT COALESCE(SUM(logical_reads), 0) FROM #diagResults WHERE id < @id) AS logical_reads,
       total_elapsed_time - (SELECT COALESCE(SUM(total_elapsed_time), 0) FROM #diagResults WHERE id < @id) AS total_elapsed_time
FROM #diagResults
WHERE id = @id;




-------------------------------------Sinle Run---------------------------------------

--SET STATISTICS IO ON;
----------------------
-- YOUR QUERY STARTS--
----------------------


----------------------
-- YOUR QUERY ENDS  --
----------------------
GO
--Diagnostics cpu time - logical read


SELECT 
es.cpu_time,
es.logical_reads,
es.total_elapsed_time
FROM sys.dm_exec_sessions AS es
CROSS APPLY sys.dm_exec_input_buffer(es.session_id, NULL) AS ib
WHERE es.session_id = @@SPID;

