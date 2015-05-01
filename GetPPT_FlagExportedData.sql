USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetPPT_FlagExportedData]    Script Date: 05/01/2015 11:14:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[GetPPT_FlagExportedData]
@PPTID int

AS

UPDATE PPTFilters 
SET Exported = 1,
	ExportedDt = GETDATE()
WHERE PPTID = @PPTID 


