USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetMMW_AllData]    Script Date: 05/01/2015 11:07:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[GetMMW_AllData]
@BookingType Varchar(4000) ='3,1,6',
@Tuples Varchar(4000) = '102189',
@GeosetTuples Varchar(4000) = '95602,95656',
@DataType Varchar(10) ='Booked',
@AsOfDate Datetime ='09/01/2014',
@Currency Varchar(10) = 'USD',
@TimePeriod Int = 90,
@YoYDOW int = 1, -- 1 = DOW 0 = DOY
@MMWID Int =3

AS

DECLARE @AsOfBookingMonth DateTime,@AsOfFutureMonth DateTime, @ControlMarketName Varchar(200),@MarketID Varchar(50),@CompMarketID Varchar(50),@BookingTypeIncluded Varchar(500)

SELECT @CompMarketID = @GeosetTuples,@MarketID=@Tuples

SELECT TOP 1 @Tuples = '[Hotel].[Market].&['+marketname+']',@ControlMarketName=MarketName
	FROM [vSIP_Hierarchy ] WHERE MarketID = @Tuples

SELECT @GeosetTuples =
(
SELECT  ',[Hotel].[Market].&['+marketname+']'
	FROM (SELECT DISTINCT MarketID,MarketName FROM [vSIP_Hierarchy ]) s
	JOIN (SELECT [STR] AS MarketID FROM dbo.charlist_to_table(@GeosetTuples ,DEFAULT)) m
	ON s.MarketID = m.MarketID
	FOR XML PATH (''))
SELECT @GeosetTuples =  '{' + stuff(REPLACE(@GeosetTuples, '&amp;','&'),1,1,'') + '}'	

SELECT @BookingTypeIncluded =
(
SELECT ', '+p.BookingType 
FROM (SELECT [STR] AS ID FROM dbo.charlist_to_table(@BookingType ,DEFAULT)) b
INNER JOIN  SSRSAggregate.dbo.DimBookingTypeMapping p
ON b.ID = p.ID
	FOR XML PATH (''))
--SELECT @BookingTypeIncluded =  stuff(REPLACE(@BookingType, '&amp;','&'),1,1,'')
		
SELECT @BookingType =
(
SELECT ',[Booking Type].[Business Model Subtype].&['+p.BookingType+']'
FROM (SELECT [STR] AS ID FROM dbo.charlist_to_table(@BookingType ,DEFAULT)) b
INNER JOIN  SSRSAggregate.dbo.DimBookingTypeMapping p
ON b.ID = p.ID
	FOR XML PATH (''))
SELECT @BookingType =  '{' + stuff(REPLACE(@BookingType, '&amp;','&'),1,1,'') + '}'	

--SELECT @Tuples  as Tuple, @GeosetTuples As GeoSet,@BookingType BookingType

SELECT @AsOfFutureMonth = dbo.GetMonthBegin(@AsOfDate)

IF(DATEADD(d,-1,DATEADD(m,1,dbo.GetMonthBegin(@AsOfDate))) = @AsOfDate )
	SELECT @AsOfBookingMonth = dbo.GetMonthBegin(@AsOfDate)
ELSE 
	SELECT @AsOfBookingMonth = DATEADD(m,-1,dbo.GetMonthBegin(@AsOfDate))

CREATE TABLE #MMW_FutureTrends_PKG
(
BookingTimeFrame Varchar(50),
StayMonth Varchar(10),
TransType Varchar(5),
PkIndicator Varchar(50),
PkIndicatorType Varchar(50),
MarketName Varchar(200),
cyRoomNights Varchar(50),
cyBasePrice Varchar(50),
cyBaseCost Varchar(50),
cyFECOMM Varchar(50),
lyRoomNights Varchar(50),
lyBasePrice Varchar(50),
lyBaseCost Varchar(50),
lyFECOMM Varchar(50)
)

CREATE TABLE #MMW_FutureTrends_POSa
(
BookingTimeFrame Varchar(50),
StayMonth Varchar(10),
TransType Varchar(5),
POSaBrandName Varchar(50),
POSaCountryName Varchar(50),
POSaSR Varchar(10),
MarketName Varchar(200),
cyRoomNights Varchar(50),
cyBasePrice Varchar(50),
cyBaseCost Varchar(50),
cyFECOMM Varchar(50),
lyRoomNights Varchar(50),
lyBasePrice Varchar(50),
lyBaseCost Varchar(50),
lyFECOMM Varchar(50)
)

CREATE TABLE #MMW_HistoricalTrends
(
MonthStart Varchar(10),
TransType Varchar(5),
PkIndicator Varchar(50),
PkIndicatorType Varchar(50),
MarketName Varchar(200),
cyRoomNights Varchar(50),
cyBasePrice Varchar(50),
cyBaseCost Varchar(50),
cyFECOMM Varchar(50),
lyRoomNights Varchar(50),
lyBasePrice Varchar(50),
lyBaseCost Varchar(50),
lyFECOMM Varchar(50)
)

CREATE TABLE #MMW_RecentTrends_BookToStay
(
BookingMonthStart Varchar(10),
StayMonthStart Varchar(10),
TransType Varchar(5),
MarketName Varchar(200),
SubMarketName Varchar(200),
cyRoomNights Varchar(50),
cyBasePrice Varchar(50),
cyBaseCost Varchar(50),
cyFECOMM Varchar(50)
)

CREATE TABLE #MMW_RecentTrends_DRR
(
TimePeriod Varchar(50),
TransType Varchar(5),
PkIndicator Varchar(50),
PkIndicatorType Varchar(50),
RateRuleGroup Varchar(500),
HasDrrFlag Varchar(3),
SubMarketName Varchar(200),
MarketName Varchar(200),
cyRoomNights Varchar(50),
cyBasePrice Varchar(50),
cyBaseCost Varchar(50),
cyFECOMM Varchar(50),
cyTDBA Varchar(50),
cyTrx Varchar(50),
lyRoomNights Varchar(50),
lyBasePrice Varchar(50),
lyBaseCost Varchar(50),
lyFECOMM Varchar(50),
lyTDBA Varchar(50),
lyTrx Varchar(50)
)

CREATE TABLE #MMW_RecentTrends_DRR_BW
(
TimePeriod Varchar(50),
TransType Varchar(5),
PkIndicator Varchar(50),
PkIndicatorType Varchar(50),
RateRuleGroup Varchar(500),
HasDrrFlag Varchar(3),
BW Varchar(20),
MarketName Varchar(200),
cyRoomNights Varchar(50),
cyBasePrice Varchar(50),
cyBaseCost Varchar(50),
cyFECOMM Varchar(50),
cyTDBA Varchar(50),
cyTrx Varchar(50),
lyRoomNights Varchar(50),
lyBasePrice Varchar(50),
lyBaseCost Varchar(50),
lyFECOMM Varchar(50),
lyTDBA Varchar(50),
lyTrx Varchar(50)
)

CREATE TABLE #MMW_RecentTrends_DRR_LOS
(
TimePeriod Varchar(50),
TransType Varchar(5),
PkIndicator Varchar(50),
PkIndicatorType Varchar(50),
RateRuleGroup Varchar(500),
HasDrrFlag Varchar(3),
LOS Varchar(20),
MarketName Varchar(200),
cyRoomNights Varchar(50),
cyBasePrice Varchar(50),
cyBaseCost Varchar(50),
cyFECOMM Varchar(50),
cyTDBA Varchar(50),
cyTrx Varchar(50),
lyRoomNights Varchar(50),
lyBasePrice Varchar(50),
lyBaseCost Varchar(50),
lyFECOMM Varchar(50),
lyTDBA Varchar(50),
lyTrx Varchar(50)
)

CREATE TABLE #MMW_RecentTrends_DRR_POSa
(
TimePeriod Varchar(50),
TransType Varchar(5),
POSaBrandName Varchar(50),
MUName Varchar(50),
POSaCountryName Varchar(50),
RateRuleGroup Varchar(500),
HasDrrFlag Varchar(3),
MarketName Varchar(200),
cyRoomNights Varchar(50),
cyBasePrice Varchar(50),
cyBaseCost Varchar(50),
cyFECOMM Varchar(50),
cyTDBA Varchar(50),
cyTrx Varchar(50),
lyRoomNights Varchar(50),
lyBasePrice Varchar(50),
lyBaseCost Varchar(50),
lyFECOMM Varchar(50),
lyTDBA Varchar(50),
lyTrx Varchar(50)
)

CREATE TABLE #MMW_RecentTrends_Mobile
(
TimePeriod Varchar(50),
TransType Varchar(5),
POSaBrandName Varchar(50),
MobileIndicator Varchar(50),
SubMarketName Varchar(200),
MarketName Varchar(200),
cyRoomNights Varchar(50),
cyBasePrice Varchar(50),
cyBaseCost Varchar(50),
cyFECOMM Varchar(50),
cyTDBA Varchar(50),
cyTrx Varchar(50),
lyRoomNights Varchar(50),
lyBasePrice Varchar(50),
lyBaseCost Varchar(50),
lyFECOMM Varchar(50),
lyTDBA Varchar(50),
lyTrx Varchar(50)
)

CREATE TABLE #MMW_RecentTrends_Mobile_BW
(
TimePeriod Varchar(50),
TransType Varchar(5),
POSaBrandName Varchar(50),
MobileIndicator Varchar(50),
BW Varchar(20),
MarketName Varchar(200),
cyRoomNights Varchar(50),
cyBasePrice Varchar(50),
cyBaseCost Varchar(50),
cyFECOMM Varchar(50),
cyTDBA Varchar(50),
cyTrx Varchar(50),
lyRoomNights Varchar(50),
lyBasePrice Varchar(50),
lyBaseCost Varchar(50),
lyFECOMM Varchar(50),
lyTDBA Varchar(50),
lyTrx Varchar(50)
)

CREATE TABLE #MMW_RecentTrends_Mobile_DOW
(
TimePeriod Varchar(50),
TransType Varchar(5),
POSaBrandName Varchar(50),
MobileIndicator Varchar(50),
StayDOW Varchar(20),
MarketName Varchar(200),
cyRoomNights Varchar(50),
cyBasePrice Varchar(50),
cyBaseCost Varchar(50),
cyFECOMM Varchar(50),
cyTDBA Varchar(50),
cyTrx Varchar(50),
lyRoomNights Varchar(50),
lyBasePrice Varchar(50),
lyBaseCost Varchar(50),
lyFECOMM Varchar(50),
lyTDBA Varchar(50),
lyTrx Varchar(50)
)

CREATE TABLE #MMW_RecentTrends_Mobile_LOS
(
TimePeriod Varchar(50),
TransType Varchar(5),
POSaBrandName Varchar(50),
MobileIndicator Varchar(50),
LOS Varchar(20),
MarketName Varchar(200),
cyRoomNights Varchar(50),
cyBasePrice Varchar(50),
cyBaseCost Varchar(50),
cyFECOMM Varchar(50),
cyTDBA Varchar(50),
cyTrx Varchar(50),
lyRoomNights Varchar(50),
lyBasePrice Varchar(50),
lyBaseCost Varchar(50),
lyFECOMM Varchar(50),
lyTDBA Varchar(50),
lyTrx Varchar(50)
)

CREATE TABLE #MMW_RecentTrends_Mobile_POSa
(
TimePeriod Varchar(50),
TransType Varchar(5),
POSaBrandName Varchar(50),
MobileIndicator Varchar(50),
POSaCountryName Varchar(50),
MarketName Varchar(200),
cyRoomNights Varchar(50),
cyBasePrice Varchar(50),
cyBaseCost Varchar(50),
cyFECOMM Varchar(50),
cyTDBA Varchar(50),
cyTrx Varchar(50),
lyRoomNights Varchar(50),
lyBasePrice Varchar(50),
lyBaseCost Varchar(50),
lyFECOMM Varchar(50),
lyTDBA Varchar(50),
lyTrx Varchar(50)
)

CREATE TABLE #MMW_RecentTrends_OverAll
(
TimePeriod Varchar(50),
TransType Varchar(5),
StayDOW Varchar(20),
SubMarketName Varchar(200),
StarRatings Varchar(20),
MarketName Varchar(200),
cyRoomNights Varchar(50),
cyBasePrice Varchar(50),
cyBaseCost Varchar(50),
cyFECOMM Varchar(50),
lyRoomNights Varchar(50),
lyBasePrice Varchar(50),
lyBaseCost Varchar(50),
lyFECOMM Varchar(50)
)

CREATE TABLE #MMW_RecentTrends_ParentChain
(
TimePeriod Varchar(50),
TransType Varchar(5),
PkIndicator Varchar(50),
PkIndicatorType Varchar(50),
StayDOW Varchar(20),
ParentChainName Varchar(200),
cyRoomNights Varchar(50),
cyBasePrice Varchar(50),
cyBaseCost Varchar(50),
cyFECOMM Varchar(50),
cyTDBA Varchar(50),
cyTrx Varchar(50),
lyRoomNights Varchar(50),
lyBasePrice Varchar(50),
lyBaseCost Varchar(50),
lyFECOMM Varchar(50),
lyTDBA Varchar(50),
lyTrx Varchar(50)
)

CREATE TABLE #MMW_RecentTrends_PKG
(
TimePeriod Varchar(50),
TransType Varchar(5),
PkIndicator Varchar(50),
PkIndicatorType Varchar(50),
StayDOW Varchar(20),
SubmarketName Varchar(200),
StarRatings Varchar(20),
MarketName Varchar(200),
cyRoomNights Varchar(50),
cyBasePrice Varchar(50),
cyBaseCost Varchar(50),
cyFECOMM Varchar(50),
cyTDBA Varchar(50),
cyTrx Varchar(50),
lyRoomNights Varchar(50),
lyBasePrice Varchar(50),
lyBaseCost Varchar(50),
lyFECOMM Varchar(50),
lyTDBA Varchar(50),
lyTrx Varchar(50)
)

CREATE TABLE #MMW_RecentTrends_POSa
(
TimePeriod Varchar(50),
TransType Varchar(5),
POSaBrandName Varchar(50),
MUName Varchar(50),
POSaCountryName Varchar(50),
PkIndicator Varchar(50),
PkIndicatorType Varchar(50),
MarketName Varchar(200),
cyRoomNights Varchar(50),
cyBasePrice Varchar(50),
cyBaseCost Varchar(50),
cyFECOMM Varchar(50),
cyTDBA Varchar(50),
cyTrx Varchar(50),
lyRoomNights Varchar(50),
lyBasePrice Varchar(50),
lyBaseCost Varchar(50),
lyFECOMM Varchar(50),
lyTDBA Varchar(50),
lyTrx Varchar(50)
)

INSERT INTO #MMW_FutureTrends_PKG
EXEC dbo.GetMMW_FutureTrends_PKG
@BookingType,
@Tuples,
@GeosetTuples,
@AsOfFutureMonth,
@AsOfDate,
@Currency

INSERT INTO #MMW_FutureTrends_POSa
EXEC dbo.GetMMW_FutureTrends_POSa
@BookingType,
@Tuples,
@GeosetTuples,
@AsOfFutureMonth,
@AsOfDate,
@Currency

INSERT INTO #MMW_HistoricalTrends
EXEC [dbo].[GetMMW_HistoricalTrends]
@BookingType,
@Tuples,
@GeosetTuples,
@DataType,
@AsOfBookingMonth,
@Currency

INSERT INTO #MMW_RecentTrends_BookToStay
EXEC [dbo].[GetMMW_RecentTrends_BookToStay]
@BookingType,
@Tuples,
@GeosetTuples,
@DataType,
@AsOfBookingMonth,
@Currency

INSERT INTO #MMW_RecentTrends_DRR
EXEC [dbo].[GetMMW_RecentTrends_DRR]
@BookingType,
@Tuples,
@GeosetTuples,
@DataType,
@AsOfDate,
@Currency,
@TimePeriod,
@YoYDOW

INSERT INTO #MMW_RecentTrends_DRR_BW
EXEC [dbo].[GetMMW_RecentTrends_DRR_BW]
@BookingType,
@Tuples,
@GeosetTuples,
@DataType,
@AsOfDate,
@Currency,
@TimePeriod,
@YoYDOW

INSERT INTO #MMW_RecentTrends_DRR_LOS
EXEC [dbo].[GetMMW_RecentTrends_DRR_LOS]
@BookingType,
@Tuples,
@GeosetTuples,
@DataType,
@AsOfDate,
@Currency,
@TimePeriod,
@YoYDOW

INSERT INTO #MMW_RecentTrends_DRR_POSa
EXEC [dbo].[GetMMW_RecentTrends_DRR_POSa]
@BookingType,
@Tuples,
@DataType,
@AsOfDate,
@Currency,
@TimePeriod,
@YoYDOW

INSERT INTO #MMW_RecentTrends_Mobile
EXEC [dbo].[GetMMW_RecentTrends_Mobile]
@BookingType,
@Tuples,
@GeosetTuples,
@DataType,
@AsOfDate,
@Currency,
@TimePeriod,
@YoYDOW

INSERT INTO #MMW_RecentTrends_Mobile_BW
EXEC [dbo].[GetMMW_RecentTrends_Mobile_BW]
@BookingType,
@Tuples,
@GeosetTuples,
@DataType,
@AsOfDate,
@Currency,
@TimePeriod,
@YoYDOW 

INSERT INTO #MMW_RecentTrends_Mobile_DOW
EXEC [dbo].[GetMMW_RecentTrends_Mobile_DOW]
@BookingType,
@Tuples,
@GeosetTuples,
@DataType,
@AsOfDate,
@Currency,
@TimePeriod,
@YoYDOW

INSERT INTO #MMW_RecentTrends_Mobile_LOS
EXEC [dbo].[GetMMW_RecentTrends_Mobile_LOS]
@BookingType,
@Tuples,
@GeosetTuples,
@DataType,
@AsOfDate,
@Currency,
@TimePeriod,
@YoYDOW

INSERT INTO #MMW_RecentTrends_Mobile_POSa
EXEC [dbo].[GetMMW_RecentTrends_Mobile_POSa]
@BookingType,
@Tuples,
@GeosetTuples,
@DataType,
@AsOfDate,
@Currency,
@TimePeriod,
@YoYDOW

INSERT INTO #MMW_RecentTrends_Overall
EXEC [dbo].[GetMMW_RecentTrends_Overall]
@BookingType,
@Tuples,
@GeosetTuples,
@DataType,
@AsOfDate,
@Currency,
@TimePeriod,
@YoYDOW

/*
INSERT INTO #MMW_RecentTrends_ParentChain
EXEC [dbo].[GetMMW_RecentTrends_ParentChain]
@BookingType,
@Tuples,
@DataType,
@AsOfDate,
@Currency,
@TimePeriod,
@YoYDOW
*/

INSERT INTO #MMW_RecentTrends_PKG
EXEC [dbo].[GetMMW_RecentTrends_PKG]
@BookingType,
@Tuples,
@GeosetTuples,
@DataType,
@AsOfDate,
@Currency,
@TimePeriod,
@YoYDOW

INSERT INTO #MMW_RecentTrends_POSa
EXEC [dbo].[GetMMW_RecentTrends_POSa]
@BookingType,
@Tuples,
@DataType,
@AsOfDate,
@Currency,
@TimePeriod,
@YoYDOW
/*
CREATE TABLE dbo.MMW_AllData
(
TimePeriod Varchar(50),
MonthStart Datetime,
StayMonth DateTime,
BookingMonth DateTime,
TransType Varchar(5),
POSaBrandName Varchar(50),
MUName Varchar(50),
POSaCountryName Varchar(50),
POSaSR Varchar(50),
MobileIndicator Varchar(50),
PkIndicator Varchar(50),
PkIndicatorType Varchar(50),
RateRuleGroup Varchar(500),
HasDrrFlag Varchar(3),
BW Varchar(20),
LOS Varchar(20),
StayDOW Varchar(20),
StarRatings Varchar(20),
SubMarketName Varchar(200),
MarketName Varchar(200),
ParentChainName Varchar(200),
cyRoomNights Int,
cyBasePrice Float,
cyBaseCost Float,
cyFECOMM Float,
cyTDBA Int,
cyTrx Int,
lyRoomNights Int,
lyBasePrice Float,
lyBaseCost Float,
lyFECOMM Float,
lyTDBA Int,
lyTrx Int,
MarketType Varchar(20),
DataType varchar(50),
AsofDate  Datetime,
SprocName Varchar(100),
RunDate DateTime,
Success Int,
MMWID Int
)*/

--SELECT * FROM dbo.MMW_AllData
INSERT INTO dbo.MMW_AllData
(
StayMonth,
TransType,
PkIndicator,
PkIndicatorType,
MarketName,
cyRoomNights,
cyBasePrice,
cyBaseCost ,
cyFECOMM ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM,
SprocName,
RunDate,
Success,
MMWID
)

SELECT 
StayMonth,
TransType,
PkIndicator,
PkIndicatorType,
MarketName,
cyRoomNights,
cyBasePrice,
cyBaseCost ,
cyFECOMM ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM,
'GetMMW_FutureTrends_PKG' SprocName,
GetDate() RunDate,
1 Success,
@MMWID
FROM #MMW_FutureTrends_PKG


INSERT INTO dbo.MMW_AllData
(
StayMonth,
TransType,
POSaBrandName ,
POSaCountryName ,
POSaSR,
MarketName,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM,
SprocName,
RunDate,
Success,
MMWID
)
SELECT 
StayMonth,
TransType,
POSaBrandName ,
POSaCountryName ,
POSaSR,
MarketName,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM,
'GetMMW_FutureTrends_POSa' SprocName,
GetDate() RunDate,
1 Success,
@MMWID
FROM #MMW_FutureTrends_POSa

INSERT INTO dbo.MMW_AllData
(
MonthStart ,
TransType ,
PkIndicator ,
PkIndicatorType ,
MarketName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM,
SprocName,
RunDate,
Success,
MMWID 
)
SELECT 
MonthStart ,
TransType ,
PkIndicator ,
PkIndicatorType ,
MarketName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM,
'GetMMW_HistoricalTrends' SprocName,
GetDate() RunDate,
1 Success,
@MMWID 
FROM #MMW_HistoricalTrends

INSERT INTO dbo.MMW_AllData
(
BookingMonth ,
StayMonth ,
TransType ,
MarketName ,
SubMarketName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM,
SprocName,
RunDate,
Success,
MMWID 
)
SELECT 
BookingMonthStart ,
StayMonthStart ,
TransType ,
MarketName ,
SubMarketName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM,
'GetMMW_RecentTrends_BookToStay' SprocName,
GetDate() RunDate,
1 Success,
@MMWID
 FROM #MMW_RecentTrends_BookToStay

INSERT INTO dbo.MMW_AllData
(
TimePeriod ,
TransType ,
PkIndicator ,
PkIndicatorType ,
RateRuleGroup ,
HasDrrFlag ,
SubMarketName ,
MarketName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
SprocName,
RunDate,
Success,
MMWID 
)
SELECT 
TimePeriod ,
TransType ,
PkIndicator ,
PkIndicatorType ,
RateRuleGroup ,
HasDrrFlag ,
SubMarketName ,
MarketName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
'GetMMW_RecentTrends_DRR' SprocName,
GetDate() RunDate,
1 Success,
@MMWID  
FROM #MMW_RecentTrends_DRR

INSERT INTO dbo.MMW_AllData
(
TimePeriod ,
TransType ,
PkIndicator ,
PkIndicatorType ,
RateRuleGroup ,
HasDrrFlag ,
BW ,
MarketName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
SprocName,
RunDate,
Success,
MMWID 
)
SELECT 
TimePeriod ,
TransType ,
PkIndicator ,
PkIndicatorType ,
RateRuleGroup ,
HasDrrFlag ,
BW ,
MarketName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
'GetMMW_RecentTrends_DRR_BW' SprocName,
GetDate() RunDate,
1 Success,
@MMWID 
FROM #MMW_RecentTrends_DRR_BW

INSERT INTO dbo.MMW_AllData
(
TimePeriod ,
TransType ,
PkIndicator ,
PkIndicatorType ,
RateRuleGroup ,
HasDrrFlag ,
LOS ,
MarketName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
SprocName,
RunDate,
Success,
MMWID 
)
SELECT 
TimePeriod ,
TransType ,
PkIndicator ,
PkIndicatorType ,
RateRuleGroup ,
HasDrrFlag ,
LOS ,
MarketName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx ,
'GetMMW_RecentTrends_DRR_LOS' SprocName,
GetDate() RunDate,
1 Success,
@MMWID 
FROM #MMW_RecentTrends_DRR_LOS

INSERT INTO dbo.MMW_AllData
(
TimePeriod ,
TransType ,
POSaBrandName ,
MUName ,
POSaCountryName ,
RateRuleGroup ,
HasDrrFlag ,
MarketName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
SprocName,
RunDate,
Success,
MMWID 
)
SELECT 
TimePeriod ,
TransType ,
POSaBrandName ,
MUName ,
POSaCountryName ,
RateRuleGroup ,
HasDrrFlag ,
MarketName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
'GetMMW_RecentTrends_DRR_POSa' SprocName,
GetDate() RunDate,
1 Success,
@MMWID  
FROM #MMW_RecentTrends_DRR_POSa

INSERT INTO dbo.MMW_AllData
(
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
SubMarketName ,
MarketName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
SprocName,
RunDate,
Success,
MMWID 
)
SELECT 
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
SubMarketName ,
MarketName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
'GetMMW_RecentTrends_Mobile' SprocName,
GetDate() RunDate,
1 Success,
@MMWID  
FROM #MMW_RecentTrends_Mobile

INSERT INTO dbo.MMW_AllData
(
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
MarketName ,
BW ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
SprocName,
RunDate,
Success,
MMWID 
)
SELECT 
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
MarketName ,
BW ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
'GetMMW_RecentTrends_Mobile_BW' SprocName,
GetDate() RunDate,
1 Success,
@MMWID  
FROM #MMW_RecentTrends_Mobile_BW

INSERT INTO dbo.MMW_AllData
(
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
MarketName ,
StayDOW ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
SprocName,
RunDate,
Success,
MMWID 
)
SELECT 
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
MarketName ,
StayDOW ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
'GetMMW_RecentTrends_Mobile_DOW' SprocName,
GetDate() RunDate,
1 Success,
@MMWID  
FROM #MMW_RecentTrends_Mobile_DOW

INSERT INTO dbo.MMW_AllData
(
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
MarketName ,
LOS ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
SprocName,
RunDate,
Success,
MMWID 
)
SELECT 
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
MarketName ,
LOS ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
'GetMMW_RecentTrends_Mobile_LOS' SprocName,
GetDate() RunDate,
1 Success,
@MMWID 
FROM #MMW_RecentTrends_Mobile_LOS

INSERT INTO dbo.MMW_AllData
(
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
POSaCountryName ,
MarketName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
SprocName,
RunDate,
Success,
MMWID 
)
SELECT 
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
POSaCountryName ,
MarketName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
'GetMMW_RecentTrends_Mobile_POSa' SprocName,
GetDate() RunDate,
1 Success,
@MMWID  
FROM #MMW_RecentTrends_Mobile_POSa

INSERT INTO dbo.MMW_AllData
(
TimePeriod ,
TransType ,
StayDOW ,
SubMarketName ,
StarRatings ,
MarketName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM,
SprocName,
RunDate,
Success,
MMWID 
)
SELECT 
TimePeriod ,
TransType ,
StayDOW ,
SubMarketName ,
StarRatings ,
MarketName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM,
'GetMMW_RecentTrends_OverAll' SprocName,
GetDate() RunDate,
1 Success,
@MMWID  
FROM #MMW_RecentTrends_OverAll

INSERT INTO dbo.MMW_AllData
(
TimePeriod ,
TransType ,
PkIndicator ,
PkIndicatorType ,
StayDOW ,
ParentChainName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
SprocName,
RunDate,
Success,
MMWID 
)
SELECT 
TimePeriod ,
TransType ,
PkIndicator ,
PkIndicatorType ,
StayDOW ,
ParentChainName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
'GetMMW_RecentTrends_ParentChain' SprocName,
GetDate() RunDate,
1 Success,
@MMWID  
FROM #MMW_RecentTrends_ParentChain

INSERT INTO dbo.MMW_AllData
(
TimePeriod ,
TransType ,
PkIndicator ,
PkIndicatorType ,
StayDOW ,
SubmarketName ,
StarRatings ,
MarketName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
SprocName,
RunDate,
Success,
MMWID 
)
SELECT 
TimePeriod ,
TransType ,
PkIndicator ,
PkIndicatorType ,
StayDOW ,
SubmarketName ,
StarRatings ,
MarketName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
'GetMMW_RecentTrends_PKG' SprocName,
GetDate() RunDate,
1 Success,
@MMWID  
FROM #MMW_RecentTrends_PKG

INSERT INTO dbo.MMW_AllData
(
TimePeriod ,
TransType ,
POSaBrandName ,
MUName ,
POSaCountryName ,
PkIndicator ,
PkIndicatorType ,
MarketName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
SprocName,
RunDate,
Success,
MMWID 
)
SELECT 
TimePeriod ,
TransType ,
POSaBrandName ,
MUName ,
POSaCountryName ,
PkIndicator ,
PkIndicatorType ,
MarketName ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
cyTDBA ,
cyTrx ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
lyTDBA ,
lyTrx,
'GetMMW_RecentTrends_POSa' SprocName,
GetDate() RunDate,
1 Success,
@MMWID  
FROM #MMW_RecentTrends_POSa

SELECT RANK() OVER(PARTITION BY c.MarketID ORDER BY HotelCnt DESC) MarketRank,c.MarketID,c.MarketName,c.POSuCountry,c.POSuSR
INTO #Markets
FROM
(
SELECT COUNT(LODG_PROPERTY_KEY) HotelCnt, PROPERTY_MKT_NAME MarketName,PROPERTY_MKT_ID MarketID, PROPERTY_CNTRY_NAME POSuCountry,PROPERTY_SUPER_REGN_NAME POSuSR FROM Mirror.DB2_DM.LODG_PROPERTY_DIM
	WHERE PROPERTY_MKT_ID >0 AND PROPERTY_SUPER_REGN_ID>0
	GROUP BY PROPERTY_MKT_NAME,PROPERTY_MKT_ID, PROPERTY_CNTRY_NAME,PROPERTY_SUPER_REGN_NAME
) c
JOIN
(
(SELECT [STR] AS MarketID FROM dbo.charlist_to_table(@MarketID ,DEFAULT)) 
UNION
(SELECT [STR] AS MarketID FROM dbo.charlist_to_table(@CompMarketID ,DEFAULT)) 
) c2
ON c.MarketID = c2.MarketID



SELECT DISTINCT [POS_CNTRY_NAME] POSaCountryName,[LPS_POS_SUPER_REGN_NAME] POSaSR
INTO #POSa
  FROM [Mirror].[DB2_DM].[POS_DIM]

UPDATE mmw
SET DataType = @DataType,
	BookingTypeIncluded = Substring(@BookingTypeIncluded,2,LEN(@BookingTypeIncluded)-1),
	--MMWID = @MMWID,
	AsofDate = @AsOfDate,
	POSaSR = pos.POSaSR,
	MarketType = CASE WHEN mmw.MarketName =@ControlMarketName THEN 'Control' ELSE 'Compete' END,
	InternationalFlag = CASE WHEN ISNULL(mmw.POSaCountryName,'') <> '' THEN 
									CASE WHEN ISNULL(mmw.POSaCountryName,'') = m.POSuCountry THEN 'Domestic'
										--ELSE CASE WHEN RIGHT(pos.POSaSR,4) = m.POSuSR THEN 'Domestic'
												ELSE 'International' END END --END
	
FROM dbo.MMW_AllData mmw 
LEFT JOIN ( SELECT * FROM #Markets WHERE MarketRank =1) m
ON mmw.MarketName = m.MarketName
LEFT JOIN #POSa pos
ON mmw.POSaCountryName = pos.POSaCountryName
WHERE ISNULL(MMWID,'') = @MMWID

--check for logic #2 to make sure if only internaltional POSales
IF((SELECT COUNT(*) FROM dbo.MMW_AllData WHERE MMWID = @MMWID AND InternationalFlag ='Domestic') < 1)
UPDATE mmw
SET InternationalFlag = 'Domestic'											
FROM dbo.MMW_AllData mmw 
JOIN ( SELECT * FROM #Markets WHERE MarketRank =1) m
ON mmw.MarketName = m.MarketName AND RIGHT(POSaSR,4) = RIGHT(m.POSuSR,4)
WHERE ISNULL(MMWID,'') = @MMWID

DECLARE @TimePeriodName Varchar(50),@NumOfDays Int
SET @NumOfDays = @TimePeriod
SELECT @TimePeriodName = ShortName,@TimePeriod = TimePeriodID
	FROM dbo.PPTFilters f
	JOIN dbo.TimePeriod t
	ON f.TimePeriodID = t.ID 
	WHERE f.PPTID = @MMWID
	
IF(ISNULL(@TimePeriodName,'') ='')
	BEGIN
		IF(@TimePeriod IN (0,-7))
			SELECT @TimePeriodName = Convert(Varchar(10),DATEADD(d,-@NumOfDays+1,@AsOfDate),120) + ' to ' +   Convert(Varchar(10),@AsOfDate,120)
		ELSE IF(@TimePeriod = 30)
				SELECT @TimePeriodName = MONTH(@AsOfDate)
			ELSE IF(@TimePeriod = 91)
				SELECT @TimePeriodName = CASE WHEN MONTH(@AsOfDate) BETWEEN 1 and 3 THEN 'Q1'
												WHEN MONTH(@AsOfDate) BETWEEN 4 and 6 THEN 'Q2'
													WHEN MONTH(@AsOfDate) BETWEEN 7 and 9 THEN 'Q3'
														WHEN MONTH(@AsOfDate) BETWEEN 10 and 12 THEN 'Q4' END
				
	END

UPDATE dbo.MMW_AllData
SET TimePeriod = @TimePeriodName
WHERE MMWID = @MMWID AND ISNULL(TimePeriod,'') <> ''

--SELECT * into ##Markets FROM #Markets
