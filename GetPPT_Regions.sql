USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetPPT_Regions]    Script Date: 05/01/2015 11:14:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[GetPPT_Regions] @SuperRegionID Int
AS

SELECT DISTINCT 
RegionID ID,RegionName Name
FROM vSIP_Hierarchy
WHERE SuperRegionID = @SuperRegionID AND RegionID>0
UNION ALL
SELECT
-1 ID, ' Select a Region' Name
ORDER BY RegionName

