--instead of this

select fundorderid, orderstatus, ROW_NUMBER() over(partition by fundorderid order by id desc) rownumber
from new.fundorderstate 
)
update fo set orderstate = fos.orderstatus
from new.fundorder fo
join lastState fos on fos.FundOrderId = fo.Id
  where rownumber = 1

-- we can do this

UPDATE fo 
SET orderstate = fos.orderstatus
FROM new.fundorder fo
CROSS APPLY (
    SELECT TOP 1 orderstatus
    FROM new.fundorderstate fos
    WHERE fos.FundOrderId = fo.Id
    ORDER BY fos.id DESC
) fos;



Key characteristics of CROSS APPLY:
Row-by-row execution: The inner table expression (function, subquery, or derived table) is executed for each row returned by the outer table expression.
Correlation: It allows the inner expression to reference columns from the outer table, enabling dynamic filtering or calculations based on the outer row's values.
Similar to INNER JOIN: CROSS APPLY returns only those rows from the outer table for which the inner expression returns a result. If the inner expression yields no rows for a given outer row, that outer row is excluded from the final result set.
Common use cases:
Applying a table-valued function to each row of a table. 
Retrieving "top N" records per group (e.g., top 3 orders for each customer).
Processing JSON data or other complex data structures within a table.