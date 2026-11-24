CREATE TABLE #Target
(
    Id BIGINT IDENTITY(1,1),
    Name NVARCHAR(100)
);

CREATE TABLE #InsertedRows
(
    Id BIGINT,
    Name NVARCHAR(100)
);

INSERT INTO #Target (Name)
OUTPUT INSERTED.Id, INSERTED.Name
INTO #InsertedRows (Id, Name)
SELECT Name
FROM #Source;


--If you need to capture both the generated identity and additional source columns, you can use:
MERGE INTO #Target AS t
USING #Source AS s
    ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (Name)
    VALUES (s.Name)
OUTPUT
    INSERTED.Id,
    s.Name
INTO #InsertedRows (Id, Name);