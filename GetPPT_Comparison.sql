USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[GetPPT_Comparison]    Script Date: 05/01/2015 11:17:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[GetPPT_Comparison]
@PPTTypeID INT =0 -- 0= hotel 1 = Market 2 = account group 3 = parent chain
AS

IF( @PPTTypeID = 0)-- OR @PPTTypeID = 2)
	BEGIN
		
		SELECT 1 ID, 'vs Compset only' Name
		UNION
		SELECT 2 ID, 'vs Geo only' Name
		UNION
		SELECT 3 ID, 'vs Geo and Compset' Name
	END
ELSE  
	IF( @PPTTypeID =3)
	BEGIN
		SELECT 1 ID, 'vs Compset only' Name
	END
ELSE IF( @PPTTypeID =2)
		BEGIN
			SELECT 2 ID, 'vs Geo only' Name
		END
