USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetPPT_DataExport]    Script Date: 05/01/2015 11:13:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[GetPPT_DataExport]
@PPTID int = 1,
@PPTTypeID int = 1

AS

IF(@PPTTypeID <> 1)
	BEGIN
       SELECT
       [TimePeriod]
      ,[MonthStart]
      ,[StayMonth]
      ,[BookingMonth]
      ,[TransType]
      ,[POSaBrandName]
      ,[MUName]
      ,[POSaCountryName]
      ,[POSaSR]
      ,[MobileIndicator]
      ,[PkIndicator]
      ,[PkIndicatorType]
      ,[RateRuleGroup]
      ,[HasDrrFlag]
      ,[BW]
      ,[LOS]
      ,[StayDOW]
      ,[StarRatings]
      ,ISNULL([cyRoomNights],0) [cyRoomNights]
      ,ISNULL([cyBasePrice],0) [cyBasePrice]
      ,ISNULL([cyBaseCost],0) [cyBaseCost]
      ,ISNULL([cyFECOMM],0) [cyFECOMM]
      ,ISNULL([cyTDBA],0) [cyTDBA]
      ,ISNULL([cyTrx],0) [cyTrx]
      ,ISNULL([lyRoomNights],0) [lyRoomNights]
      ,ISNULL([lyBasePrice],0) [lyBasePrice]
      ,ISNULL([lyBaseCost],0) [lyBaseCost]
      ,ISNULL([lyFECOMM],0) [lyFECOMM]
      ,ISNULL([lyTDBA],0) [lyTDBA]
      ,ISNULL([lyTrx],0) [lyTrx]
      ,[ComparisonType]
      ,[ComparisonTypeDesc]
      ,[DataType]
      ,[AsofDate]
      ,[SprocName]
      ,[RunDate]
      ,[Success]
      ,[HVRID]
      ,[InternationalFlag]
      ,[BookingTypeIncluded]
       FROM dbo.HVR_AllData WHERE HVRID = @PPTID
	END
ELSE
	BEGIN
		SELECT 
	   [TimePeriod]
      ,[MonthStart]
      ,[StayMonth]
      ,[BookingMonth]
      ,[TransType]
      ,[POSaBrandName]
      ,[MUName]
      ,[POSaCountryName]
      ,[POSaSR]
      ,[MobileIndicator]
      ,[PkIndicator]
      ,[PkIndicatorType]
      ,[RateRuleGroup]
      ,[HasDrrFlag]
      ,[BW]
      ,[LOS]
      ,[StayDOW]
      ,[StarRatings]
      ,[SubMarketName]
      ,[MarketName]
      ,[ParentChainName]
      ,ISNULL([cyRoomNights],0) [cyRoomNights]
      ,ISNULL([cyBasePrice],0) [cyBasePrice]
      ,ISNULL([cyBaseCost],0) [cyBaseCost]
      ,ISNULL([cyFECOMM],0) [cyFECOMM]
      ,ISNULL([cyTDBA],0) [cyTDBA]
      ,ISNULL([cyTrx],0) [cyTrx]
      ,ISNULL([lyRoomNights],0) [lyRoomNights]
      ,ISNULL([lyBasePrice],0) [lyBasePrice]
      ,ISNULL([lyBaseCost],0) [lyBaseCost]
      ,ISNULL([lyFECOMM],0) [lyFECOMM]
      ,ISNULL([lyTDBA],0) [lyTDBA]
      ,ISNULL([lyTrx],0) [lyTrx]
      ,[MarketType]
      ,[DataType]
      ,[AsofDate]
      ,[SprocName]
      ,[RunDate]
      ,[Success]
      ,[MMWID]
      ,[InternationalFlag]
      ,[BookingTypeIncluded] 
      FROM dbo.MMW_AllData WHERE MMWID = @PPTID
	END

