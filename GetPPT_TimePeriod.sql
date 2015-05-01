USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[GetPPT_TimePeriod]    Script Date: 05/01/2015 11:19:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[GetPPT_TimePeriod]
AS

SELECT
		Name
      ,[ID]
      ,[SortOrder]
  FROM [dbo].[TimePeriod] WHERE ID < 366
UNION
SELECT 'Select a Time Period' Name, -2 ID, -1 SortOrder
  ORDER BY [SortOrder]