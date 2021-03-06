USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetPPT_CheckForMoreDataExport]    Script Date: 05/01/2015 11:12:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[GetPPT_CheckForMoreDataExport]

AS

SELECT TOP 1  PPTID,PPTTypeID,ControlValue,Convert(Varchar(12),ProcessedBeginDt,0) ProcessDt,
	RequestedBy,ISNULL(hvr.ComparisonTypeDesc,mmw.MarketName) ControlName
FROM PPTFilters f
LEFT JOIN HVR_AllData hvr ON f.PPTID = hvr.HVRID AND hvr.ComparisonType ='ControlSetTotal'
LEFT JOIN MMW_AllData mmw ON f.PPTID = mmw.MMWID AND mmw.MarketType ='Control'
	WHERE ISNULL(Processed,0) = 1 AND ISNULL(Exported,0) = 0
	ORDER BY PPTID ASC
 

