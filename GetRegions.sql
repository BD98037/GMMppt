USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetRegions]    Script Date: 05/01/2015 11:15:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[GetRegions] @SuperRegionID Varchar(4000)
AS
Select Distinct RegionName Name, RegionID ID
        from dbo.vSIP_Hierarchy h
        Join (SELECT DISTINCT  [str] As SuperRegionID FROM dbo.charlist_to_table(@SuperRegionID,DEFAULT)) r
        On h.SuperRegionID = r.SuperRegionID    AND h.RegionID >0
                order by 1
