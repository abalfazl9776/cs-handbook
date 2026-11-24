SELECT *
FROM dbo.YourTable
WHERE YourColumn IS NOT NULL
  AND TRY_CONVERT(decimal(18,2), YourColumn) IS NULL;

If this returns zero rows, you can safely alter the column: