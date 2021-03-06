USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetPPT_ValidateOnFlyCompset]    Script Date: 05/01/2015 11:15:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[GetPPT_ValidateOnFlyCompset] 
@ControlValue Varchar(100) = null,
@CompsetList varchar(500) = null

/*
dbo.GetPPT_ValidateOnFlyCompset '23799','3844012;3051;4718;906059;4498296'
*/

AS

DECLARE @CompsetCnt Int,@Pass Int,@ControlValueIncluded Int

SELECT @CompsetCnt = COUNT(DISTINCT([STR])) 
	FROM dbo.charlist_to_table(@CompsetList,';')
	WHERE [STR] <> @ControlValue
	
IF(@CompsetCnt>=3)
	BEGIN
		SELECT @Pass = 1
		IF NOT EXISTS(	
		SELECT * 
			FROM dbo.charlist_to_table(@CompsetList,';')
			WHERE [STR] = @ControlValue)
			SELECT @CompsetList = @CompsetList + ';' + @ControlValue

	END
ELSE 
		SELECT @Pass = 0
		

SELECT @CompsetList CompsetList,@Pass Pass


