C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\bcp.exe
uses sql server internal TDS (Tabular Data Stream protcol) like SqlBulkCopy (ADO.NET)

save csv as "utf-16 le" (unicode)

bcp dbo.##testtt in "C:\Users\A.Vayani\Documents\csv.csv" -S tcp:beta-ams-db1,1433 -d tempdb -U "sa" -P "1qaz@WSX" -t"," -r"\n" -q -w -F 2


bcp dbo.##testtt in "C:\Users\A.Vayani\Documents\csv.csv" -S tcp:beta-ams-db1,1433 -d tempdb -U "sa" -P "1qaz@WSX" -t"," -r"\n" -q -c -F 2

