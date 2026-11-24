EXEC dbo.MyProcedure
    @CustomerId = 123,
    @Date = '2026-07-20'
WITH RECOMPILE;

-------------------------------




CREATE PROCEDURE dbo.MyProcedure
WITH RECOMPILE
AS
BEGIN
    ...
END



---------------------------------
--marks for recomplie for next execution

EXEC sp_recompile 'dbo.MyProcedure';


---------------------------------


SELECT ...
FROM ...
WHERE ...
OPTION (RECOMPILE);



