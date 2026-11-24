select id, max(col), sum(col)
from a 
group by id with rollup