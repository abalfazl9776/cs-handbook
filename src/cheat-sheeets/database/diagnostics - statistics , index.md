--List statistics for a table

SELECT
    s.name AS StatisticsName,
    s.stats_id,
    s.auto_created,
    s.user_created,
    s.no_recompute,
    s.has_filter,
    s.filter_definition
FROM sys.stats s
WHERE s.object_id = OBJECT_ID('dbo.YourTable');






--See which columns each statistic covers

SELECT
    s.name AS StatisticsName,
    c.name AS ColumnName,
    sc.stats_column_id
FROM sys.stats s
JOIN sys.stats_columns sc
    ON s.object_id = sc.object_id
    AND s.stats_id = sc.stats_id
JOIN sys.columns c
    ON sc.object_id = c.object_id
    AND sc.column_id = c.column_id
WHERE s.object_id = OBJECT_ID('dbo.YourTable')
ORDER BY s.name, sc.stats_column_id;





--See when statistics were last updated

SELECT
    s.name AS StatisticsName,
    sp.last_updated,
    sp.rows,
    sp.rows_sampled,
    sp.modification_counter
FROM sys.stats s
CROSS APPLY sys.dm_db_stats_properties(
    s.object_id,
    s.stats_id
) sp
WHERE s.object_id = OBJECT_ID('dbo.YourTable');





--See the actual histogram

DBCC SHOW_STATISTICS ('dbo.YourTable', 'StatisticsName');
DBCC SHOW_STATISTICS ('dbo.YourTable', 'StatisticsName')  WITH HISTOGRAM;
DBCC SHOW_STATISTICS ('dbo.YourTable', 'StatisticsName')  WITH stat_header;








-- see indexes:
  EXEC sp_helpindex 'base.ShareholderFundAssets';