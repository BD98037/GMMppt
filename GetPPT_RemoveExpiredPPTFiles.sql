USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[GetPPT_RemoveExpiredPPTFiles]    Script Date: 05/01/2015 11:19:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[GetPPT_RemoveExpiredPPTFiles]
AS

DECLARE
@FileLocationPPT Varchar(500), 
@FileLocationExcel Varchar(500),
@FileName Varchar(500) ='',
@CmdDelete Varchar(500),
@CmdDir Varchar(500),
@Status Int = 1,
@Error Varchar(100),
@PPTID Int,
@Now DateTime ,
@72hoursBefore DateTime 

SET @Now =GETDATE()
SET @72hoursBefore = DATEADD(hour,-50,@Now)

SET @FileLocationPPT = '\\chcxssatech014\c$\PPTfiles\'
SET @FileLocationExcel = '\\chcxssatech014\c$\PPTExcelFiles\'
SET @CmdDir = 'Dir /b /s ' + @FileLocationPPT +'*'

CREATE TABLE #Files(FoundFile Varchar(500))
INSERT INTO #Files
EXEC master..xp_cmdshell @CmdDir
SET @Status = @@ERROR

SET @CmdDir = 'Dir /b /s ' + @FileLocationExcel +'*'
INSERT INTO #Files
EXEC master..xp_cmdshell @CmdDir
SET @Status = @@ERROR

SELECT ppt.*,f.ExportedDT
INTO #Data
FROM
(
SELECT 
REPLACE(REPLACE(SUBSTRING(FoundFile,CHARINDEX('PPTID',FoundFile)+5,LEN(FoundFile)-CHARINDEX('PPTID',FoundFile)),'.pptx',''),'.xlsx','') PPTID,
FoundFile
FROM #Files 
WHERE FoundFile LIKE '%.ppt%' OR FoundFile LIKE '%.xls%'
) ppt
JOIN [CHC-SQLPSG12].ProdReports.dbo.PPTFilters f
ON ppt.PPTID = f.PPTID

SET @PPTID = 0
SELECT @PPTID = MIN(PPTID) FROM #Data WHERE ExportedDT <  @72hoursBefore AND PPTID >@PPTID

WHILE( @PPTID IS NOT NULL)
	BEGIN
	---ppt file
		SELECT @FileName = FoundFile  FROM #Data WHERE ExportedDT <  @72hoursBefore AND PPTID = @PPTID
				
		SET @CmdDelete = 'DEL "' + @FileName +'"'
		EXEC master..xp_cmdshell @CmdDelete , NO_OUTPUT
		SET @Status = @@ERROR
	---excel file
		SELECT @FileName = FoundFile  FROM #Data WHERE ExportedDT <  @72hoursBefore AND PPTID = @PPTID
				
		SET @CmdDelete = 'DEL "' + @FileName +'"'
		EXEC master..xp_cmdshell @CmdDelete , NO_OUTPUT
		SET @Status = @@ERROR
		
		SELECT @PPTID = MIN(PPTID) FROM #Data WHERE ExportedDT <  @72hoursBefore AND PPTID >@PPTID
		
		--SELECT @CmdDelete CmdDelete,@FileName FileName,@Status  Status 
	END
