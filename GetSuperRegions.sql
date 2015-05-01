USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetSuperRegions]    Script Date: 05/01/2015 11:16:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[GetSuperRegions]
AS
select distinct SuperRegionName as Name ,SuperRegionID as ID
from dbo.vSIP_Hierarchy
ORDER by SuperRegionID ASC
