USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetPPT_DelayMsg]    Script Date: 05/01/2015 11:13:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[GetPPT_DelayMsg]
AS

DECLARE @Cnt int

SELECT @Cnt=COUNT(*) FROM PPTFilters
WHERE Processed = 0

IF(@Cnt>450)
SELECT 'Y' DelayMsg


