DECLARE @range_first_value sql_variant, @range_last_value sql_variant;
EXEC sp_sequence_get_range 
    @sequence_name = N'dbo.AsaOrderIdSequence',
    @range_size = 1000,
    @range_first_value = @range_first_value OUTPUT,
    @range_last_value = @range_last_value OUTPUT;
    
SELECT 
    CAST(@range_first_value AS BIGINT) AS FirstValue,
    CAST(@range_last_value AS BIGINT) AS LastValue;





c# code
public (long FirstValue, long LastValue) GetSequenceRange(int rangeSize)
{
    var parameters = new[]
    {
        new SqlParameter("@sequence_name", "dbo.AsaOrderIdSequence"),
        new SqlParameter("@range_size", rangeSize),
        new SqlParameter("@range_first_value", SqlDbType.Variant) { Direction = ParameterDirection.Output },
        new SqlParameter("@range_last_value", SqlDbType.Variant) { Direction = ParameterDirection.Output }
    };

    _context.Database.ExecuteSqlRaw(
        "EXEC sp_sequence_get_range @sequence_name, @range_size, @range_first_value OUTPUT, @range_last_value OUTPUT",
        parameters);

    return (
        (long)parameters[2].Value,
        (long)parameters[3].Value
    );
}

// Usage:
var (firstValue, lastValue) = GetSequenceRange(1000);
for (int i = 0; i < entities.Count; i++)
{
    entities[i].Id = firstValue + i;
}