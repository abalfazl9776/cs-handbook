-- Fragmentation, page count

SELECT
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    i.index_id,
    ips.partition_number,
    ips.index_level,
    ips.index_type_desc,
    ips.page_count,
    ips.avg_page_space_used_in_percent,
    ips.avg_fragmentation_in_percent,
    ips.record_count,
    ips.fragment_count
FROM sys.dm_db_index_physical_stats(
         DB_ID(),        -- current database
         NULL,           -- object_id, NULL = all tables
         NULL,           -- index_id, NULL = all indexes
         NULL,           -- partition_number
         'DETAILED'      -- mode: LIMITED | SAMPLED | DETAILED
     ) AS ips
JOIN sys.indexes AS i
    ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.database_id = DB_ID()
ORDER BY tablename
    

GO

-- Cost Monitoring

SET STATISTICS IO ON;
SET STATISTICS TIME ON;







-- Page and record counts
SELECT
    s.name  AS schema_name,
    t.name  AS table_name,
    SUM(p.rows) AS row_count,
    SUM(a.total_pages) AS total_pages,
    SUM(a.used_pages)  AS used_pages,
    SUM(a.data_pages)  AS data_pages
FROM sys.tables t
JOIN sys.schemas s
    ON t.schema_id = s.schema_id
JOIN sys.indexes i
    ON t.object_id = i.object_id
JOIN sys.partitions p
    ON i.object_id = p.object_id
   AND i.index_id  = p.index_id
JOIN sys.allocation_units a
    ON p.partition_id = a.container_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name
ORDER BY total_pages DESC;



-- Table size and record counts
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS row_count,

    -- Page counts
    SUM(a.total_pages) AS total_pages,
    SUM(a.used_pages) AS used_pages,
    SUM(a.data_pages) AS data_pages,

    -- Size in KB
    SUM(a.total_pages) * 8 AS total_size_kb,
    SUM(a.used_pages) * 8 AS used_size_kb,
    SUM(a.data_pages) * 8 AS data_size_kb,

    -- Size in MB
    CAST(SUM(a.total_pages) * 8.0 / 1024 AS DECIMAL(18, 2)) AS total_size_mb,
    CAST(SUM(a.used_pages) * 8.0 / 1024 AS DECIMAL(18, 2)) AS used_size_mb,
    CAST(SUM(a.data_pages) * 8.0 / 1024 AS DECIMAL(18, 2)) AS data_size_mb,

    -- Size in GB
    CAST(SUM(a.total_pages) * 8.0 / 1024 / 1024 AS DECIMAL(18, 3)) AS total_size_gb

FROM sys.tables t
JOIN sys.schemas s
    ON t.schema_id = s.schema_id
JOIN sys.indexes i
    ON t.object_id = i.object_id
JOIN sys.partitions p
    ON i.object_id = p.object_id
   AND i.index_id = p.index_id
JOIN sys.allocation_units a
    ON p.partition_id = a.container_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name
ORDER BY total_size_mb DESC;



-- checking locks happend during a TRANSACTION
    SELECT OBJECT_NAME(p.object_id) AS table_name,
           tl.request_mode,
           COUNT(*) AS row_lock_count
    FROM sys.dm_tran_locks tl
        JOIN sys.partitions p
            ON tl.resource_associated_entity_id = p.hobt_id
    WHERE tl.request_session_id = <session_id>
          AND tl.resource_type IN ( 'KEY', 'RID' )
    GROUP BY OBJECT_NAME(p.object_id),
             tl.request_mode;
			 
	-- with lock status and resource type
	SELECT
		tl.request_session_id AS session_id,
		OBJECT_NAME(p.object_id) AS table_name,
		tl.resource_type,
		tl.request_mode,
		tl.request_status,
		COUNT(*) AS lock_count
	FROM sys.dm_tran_locks tl
	LEFT JOIN sys.partitions p
		ON tl.resource_associated_entity_id = p.hobt_id
	WHERE tl.request_session_id = <session_id>
	GROUP BY
		tl.request_session_id,
		OBJECT_NAME(p.object_id),
		tl.resource_type,
		tl.request_mode,
		tl.request_status
	ORDER BY lock_count DESC;


