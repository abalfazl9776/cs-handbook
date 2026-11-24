DECLARE @receiptNumber AS BIGINT;
DECLARE @CurNo AS BIGINT;

SELECT @receiptNumber = 1400000000000;

DECLARE dep_cursor CURSOR FOR
  SELECT ReceiptNumber
  FROM   tms.Deposit

OPEN dep_cursor;

FETCH NEXT FROM dep_cursor INTO @CurNo

WHILE @@FETCH_STATUS = 0
  BEGIN
      UPDATE tms.Deposit
      SET    ReceiptNumber = @receiptNumber
      WHERE  CURRENT OF dep_cursor;

      SELECT @receiptNumber = @receiptNumber + 1;

      FETCH NEXT FROM dep_cursor INTO @CurNo
  END;

CLOSE dep_cursor;
DEALLOCATE dep_cursor;  




-----------------





  DECLARE @date INT;

DECLARE myCursor CURSOR FOR
  select distinct reportdate from [ShareholderReport2] order by reportdate;

  OPEN myCursor;

  FETCH NEXT FROM myCursor INTO @date;
  WHILE @@FETCH_STATUS = 0
BEGIN
      insert into [ShareholderReport]
  select * from [ShareholderReport2]
  where reportdate = @date
  order by fundid

    FETCH NEXT FROM myCursor INTO @date;
END

CLOSE myCursor;
DEALLOCATE myCursor;



--------------------





CREATE TABLE #status (mindate INT null, maxdate INT null , fundid TINYINT NOT NULL , lastprocessdate INT NOT NULL)

  DECLARE @fundid TinyINT;
  DECLARE @lastProcessDate INT;

DECLARE fundCursor CURSOR FOR
  select fs.FundId , MAX(fs.FileDate) lastProcessDate from base.FileStatus fs WHERE fs.Status = 4 GROUP BY fs.FundId 

  OPEN fundCursor;

  FETCH NEXT FROM fundCursor INTO @fundid , @lastProcessDate ;
  WHILE @@FETCH_STATUS = 0
BEGIN

INSERT INTO #status
SELECT MIN(ReportDate), MAX(ReportDate), @fundid , @lastProcessDate FROM report.ShareholderReport WHERE FundId  = @fundid

    FETCH NEXT FROM fundCursor INTO @fundid , @lastProcessDate;
END

CLOSE fundCursor;

SELECT mindate,
       maxdate,
       fundid,
       lastprocessdate FROM #status
