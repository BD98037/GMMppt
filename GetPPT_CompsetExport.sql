USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetPPT_CompsetExport]    Script Date: 05/01/2015 11:13:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[GetPPT_CompsetExport]
@PPTID INT
AS

SELECT * FROM HVR_CompsetList
WHERE HVRID = @PPTID