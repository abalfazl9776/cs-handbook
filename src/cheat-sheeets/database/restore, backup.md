SELECT
    name,
    state_desc,
    recovery_model_desc
FROM sys.databases;

if a database was in Restoring state instead of Online:

RESTORE DATABASE YourDatabaseName
WITH RECOVERY;

tells SQL Server:

"There are no more backups coming. Roll back any uncommitted transactions and bring the database online."