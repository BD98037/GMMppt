USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetPPT_StarRatings]    Script Date: 05/01/2015 11:15:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[GetPPT_StarRatings] -- dbo.GetPPT_StarRatings 

AS

SELECT DISTINCT 
EXPE_HALF_STAR_RTG ID,
EXPE_HALF_STAR_RTG Name
FROM Mirror.DB2_DM.LODG_PROPERTY_DIM
ORDER BY EXPE_HALF_STAR_RTG

