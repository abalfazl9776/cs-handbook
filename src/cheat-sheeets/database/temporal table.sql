ALTER TABLE [dbo].[ShareholderFundAssets]
SET (SYSTEM_VERSIONING = OFF)
GO


ALTER TABLE [dbo].[ShareholderTypeValue]
SET (SYSTEM_VERSIONING = OFF)
GO



ALTER TABLE [dbo].[ShareholderFundAssets] add
PERIOD FOR SYSTEM_TIME (PeriodStart, PeriodEnd); 


ALTER TABLE [dbo].[ShareholderFundAssets]
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [dbo].[ShareholderFundAssetsHistory]))
GO


ALTER TABLE [dbo].[ShareholderTypeValue]
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [dbo].[ShareholderTypeValueHistory]))
GO


ALTER TABLE [dbo].[ShareholderFundAssets] ALTER COLUMN PeriodEnd ADD hidden