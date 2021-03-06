USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetPPT_AccountGroup]    Script Date: 05/01/2015 11:12:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[GetPPT_AccountGroup]
AS

SELECT DISTINCT 
AccountGroupName ID,AccountGroupName Name
FROM Mirror.Expedient.AccountGroup WHERE ISNULL(AccountGroupName,'') <>''
UNION ALL
SELECT
'-1' ID, ' Select an Account Group' Name
ORDER BY AccountGroupName

