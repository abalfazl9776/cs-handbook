--Diagnostics cpu time - logical read

SELECT es.session_id,
es.host_name,
es.login_name,
es.nt_domain,
es.nt_user_name,
es.status,
es.program_name,
es.cpu_time,
es.memory_usage,
es.logical_reads,
es.total_elapsed_time,
ib.event_info
FROM sys.dm_exec_sessions AS es
CROSS APPLY sys.dm_exec_input_buffer(es.session_id, NULL) AS ib
WHERE es.session_id = 59;




--check with more filters and columns
SELECT es.session_id,
es.host_name,
es.login_name,
es.nt_domain,
es.nt_user_name,
es.status,
es.program_name,
es.cpu_time,
es.memory_usage,
es.logical_reads,
es.total_elapsed_time,
es.login_time,
ib.event_info
FROM sys.dm_exec_sessions AS es
CROSS APPLY sys.dm_exec_input_buffer(es.session_id, NULL) AS ib
WHERE host_name='KRJ-VAYANI' --and session_id not in (81, 117,77)