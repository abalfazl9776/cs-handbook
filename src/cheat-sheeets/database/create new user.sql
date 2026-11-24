USE [master]
GO
DROP LOGIN [FundShareHoldersDataRW]  ;
Go
CREATE LOGIN [FundShareHoldersDataRW] WITH PASSWORD=N'Krj@ASa@funD123456aA' --MUST_CHANGE,  CHECK_EXPIRATION=ON, CHECK_POLICY=ON
GO
USE [FundShareholders]
GO
CREATE USER [FundShareHoldersDataRW] FOR LOGIN [FundShareHoldersDataRW]
GO
ALTER ROLE [db_datareader] ADD MEMBER [FundShareHoldersDataRW]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [FundShareHoldersDataRW]
GO

-- when user is without login and there is login with same name but not mapped
--exec sp_change_users_login AUTO_FIX, 'FundShareHoldersDataRW'
--Go

CREATE ROLE proc_executor

-- Grant execute rights to the new role
GRANT EXECUTE TO proc_executor
--grant EXECUTE on schema::monitoring TO proc_executor
--revoke execute on schema::monitoring from proc_executor

ALTER ROLE proc_executor ADD MEMBER [FundShareHoldersDataRW]
GO

---- TRUNCATE
GRANT ALTER ON OBJECT::temp.ShareholderFundAssets TO FundShareHoldersDataRW;




---- change password
USE master
GO
ALTER LOGIN [YourLoginName] WITH 
PASSWORD = 'New_Password' 
OLD_PASSWORD = 'OLD_Password';
