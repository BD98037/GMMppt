USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetPPT_CompetingMarkets]    Script Date: 05/01/2015 11:12:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[GetPPT_CompetingMarkets] -- dbo.GetPPT_CompetingMarkets 423
@MarketID Int

AS

DECLARE @SuperRegionID Int

SELECT TOP 1 @SuperRegionID = SuperRegionID FROM vSIP_Hierarchy
	WHERE MarketID = @MarketID

SELECT DISTINCT
MarketID ID,
RegionName + ' - ' + MarketName Name
FROM vSIP_Hierarchy
WHERE SuperRegionID = @SuperRegionID AND MarketID >0
UNION ALL
SELECT
-1 ID, ' Select a Competing Market' Name
ORDER BY 2