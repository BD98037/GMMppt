USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[GetPPT_GeoComp]    Script Date: 05/01/2015 11:19:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[GetPPT_GeoComp]
@PPTTypeID int =0,
@ComparisonTypeID int =2
AS

-- hotel ppt and compset
IF(@PPTTypeID = 0 AND (@ComparisonTypeID = 2 OR @ComparisonTypeID = 3 ))
	BEGIN
		SELECT 1 ID, 'Market' Name
		UNION
		SELECT 2 ID, 'Submarket' Name
	END
ELSE  -- account group and compset
	IF(@PPTTypeID = 2 AND (@ComparisonTypeID = 2 OR @ComparisonTypeID = 3))
		BEGIN
			SELECT 1 ID, 'Market' Name
		END
