USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[GETPPT_AdjustValuesFieldPOS]    Script Date: 05/01/2015 11:16:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[GETPPT_AdjustValuesFieldPOS]
@TabName Varchar(100),
@PivotName Varchar(100),
@PPTTypeID Int
AS

DECLARE @PPTTypeName Varchar(100)

SELECT @PPTTypeName = CASE @PPTTypeID WHEN 1 THEN 'MMW' ELSE 'HVR' END

SELECT 
 [TabName]
,[PivotName]
,[ValuesFieldPOS]
,[PPTType] 
FROM PivotList
WHERE TabName = @TabName AND PivotName =@PivotName AND PPTType = @PPTTypeName 