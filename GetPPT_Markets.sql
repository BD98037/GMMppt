USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetPPT_Markets]    Script Date: 05/01/2015 11:14:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[GetPPT_Markets] -- dbo.GetPPT_Markets 423
@RegionID Int

AS

SELECT DISTINCT
PROPERTY_MKT_ID ID,
PROPERTY_MKT_NAME Name
FROM [chcxsqlpsg014].Mirror.DB2_DM.LODG_PROPERTY_DIM
WHERE PROPERTY_REGN_ID = @RegionID AND PROPERTY_MKT_ID >0
UNION ALL
SELECT
-1 ID, ' Select a Market' Name
ORDER BY 2

