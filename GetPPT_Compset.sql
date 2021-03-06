USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[GetPPT_Compset]    Script Date: 05/01/2015 11:19:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[GetPPT_Compset]
@PPTTypeID int,
@ComparisonTypeID int
AS

-- hotel ppt and compset
IF(@PPTTypeID = 0 AND (@ComparisonTypeID = 1 OR @ComparisonTypeID = 3))
	BEGIN
		SELECT 1 ID, 'PPC' Name
		/*UNION
		SELECT 2 ID, 'UDC' Name*/
		UNION
		SELECT 3 ID, 'On Fly Custom' Name
	END
ELSE  -- account group and compset
	IF(@PPTTypeID = 2 AND (@ComparisonTypeID = 1 OR @ComparisonTypeID = 3))
		BEGIN
			SELECT 1 ID, 'PPC' Name
			UNION
			SELECT 2 ID, 'UDC' Name
		END
	ELSE  -- parent chain and compset
	IF(@PPTTypeID = 3 AND @ComparisonTypeID = 1)
	BEGIN
		SELECT 1 ID, 'PPC' Name
	END
