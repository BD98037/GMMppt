USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetHVR_AccountGroup]    Script Date: 05/01/2015 11:01:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[GetHVR_AccountGroup]
@BookingType Varchar(4000) ='3,1',
@Tuples Varchar(4000) = '',
@DataType Varchar(6) ='Stayed',
@AsOfDate Datetime ='09/25/2014',
@Currency Varchar(10) = 'USD',
@ReportView Int = 2,  -- 0 = hotel, 2 = account group, 3 = parent chain
@StarRatings Varchar(4000) = '3,4',
@ComparisonType Int = 2, -- 1 = compset, 2 = geo only, 3 = geo & compset 
@CompsetType Int = 1, -- 1 = PPC , 2 = UDC,3 =enter own compset
@GeoType Int = 1, -- 1 = market, 2 = submarket
@CompsetTuples Varchar(4000) = '{[Hotel].[Hotel Name].&[292812],[Hotel].[Hotel Name].&[556051],[Hotel].[Hotel Name].&[2214943],[Hotel].[Hotel Name].&[3283497],[Hotel].[Hotel Name].&[253790],[Hotel].[Hotel Name].&[3816287],[Hotel].[Hotel Name].&[249748],[Hotel].[Hotel Name].&[260924],[Hotel].[Hotel Name].&[246283],[Hotel].[Hotel Name].&[241295],[Hotel].[Hotel Name].&[594905],[Hotel].[Hotel Name].&[3083966],[Hotel].[Hotel Name].&[415674],[Hotel].[Hotel Name].&[243088],[Hotel].[Hotel Name].&[3894720],[Hotel].[Hotel Name].&[3354567],[Hotel].[Hotel Name].&[263260],[Hotel].[Hotel Name].&[3940802],[Hotel].[Hotel Name].&[246147],[Hotel].[Hotel Name].&[250553],[Hotel].[Hotel Name].&[258068],[Hotel].[Hotel Name].&[271234],[Hotel].[Hotel Name].&[243425],[Hotel].[Hotel Name].&[254651],[Hotel].[Hotel Name].&[3890482],[Hotel].[Hotel Name].&[257087],[Hotel].[Hotel Name].&[3817118],[Hotel].[Hotel Name].&[246276],[Hotel].[Hotel Name].&[272312],[Hotel].[Hotel Name].&[3881942],[Hotel].[Hotel Name].&[263860],[Hotel].[Hotel Name].&[270743],[Hotel].[Hotel Name].&[252623],[Hotel].[Hotel Name].&[285238],[Hotel].[Hotel Name].&[253323],[Hotel].[Hotel Name].&[482730],[Hotel].[Hotel Name].&[262397],[Hotel].[Hotel Name].&[3893158],[Hotel].[Hotel Name].&[2816150],[Hotel].[Hotel Name].&[268122],[Hotel].[Hotel Name].&[383853],[Hotel].[Hotel Name].&[3351698],[Hotel].[Hotel Name].&[3405235],[Hotel].[Hotel Name].&[3213239],[Hotel].[Hotel Name].&[3209308],[Hotel].[Hotel Name].&[304565],[Hotel].[Hotel Name].&[245196],[Hotel].[Hotel Name].&[3906593],[Hotel].[Hotel Name].&[3893317],[Hotel].[Hotel Name].&[576979],[Hotel].[Hotel Name].&[255326],[Hotel].[Hotel Name].&[263312],[Hotel].[Hotel Name].&[3247767],[Hotel].[Hotel Name].&[3942824],[Hotel].[Hotel Name].&[259221],[Hotel].[Hotel Name].&[3061037],[Hotel].[Hotel Name].&[519017],[Hotel].[Hotel Name].&[254367],[Hotel].[Hotel Name].&[512551],[Hotel].[Hotel Name].&[3357567],[Hotel].[Hotel Name].&[492585],[Hotel].[Hotel Name].&[254103],[Hotel].[Hotel Name].&[293281],[Hotel].[Hotel Name].&[243816],[Hotel].[Hotel Name].&[3888769],[Hotel].[Hotel Name].&[240800],[Hotel].[Hotel Name].&[259584],[Hotel].[Hotel Name].&[291998],[Hotel].[Hotel Name].&[376229],[Hotel].[Hotel Name].&[3302537],[Hotel].[Hotel Name].&[263410],[Hotel].[Hotel Name].&[255982],[Hotel].[Hotel Name].&[3231492]}', 
@GeosetTuples Varchar(4000) = '',
@TimePeriod Int = 7,
@YoYDOW int = 1, -- 1 = DOW 0 = DOY
@HVRID Int =4

AS

DECLARE @AsOfBookingMonth DateTime,@AsOfFutureMonth DateTime, @ControlName Varchar(200),@GeoName Varchar(200),@MarketCnt Int,@POSuCountry Varchar(500),@POSuSR Varchar(10)

SELECT @AsOfFutureMonth = dbo.GetMonthBegin(@AsOfDate)

IF(DATEADD(d,-1,DATEADD(m,1,dbo.GetMonthBegin(@AsOfDate))) = @AsOfDate )
	SELECT @AsOfBookingMonth = dbo.GetMonthBegin(@AsOfDate)
ELSE 
	SELECT @AsOfBookingMonth = DATEADD(m,-1,dbo.GetMonthBegin(@AsOfDate))

--SELECT @Tuples  as Tuple, @GeosetTuples As GeoSet,@BookingType BookingType,@CompsetTuples

CREATE TABLE #HVR_FutureTrends_PK_DOW
(
TimePeriod Varchar(50),
StayMonth Varchar(10),
TransType Varchar(5),
PkIndicator Varchar(50),
PkIndicatorType Varchar(50),
StayDOW Varchar(20),
StarRatings Varchar(20),
ComparisonType Varchar(100),
ComparisonTypeDesc Varchar(200),
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
 

CREATE TABLE #HVR_HistoricalTrends
(
MonthStart Varchar(10),
TransType Varchar(5),
PkIndicator Varchar(50),
PkIndicatorType Varchar(50),
cyRoomNights Varchar(50),
cyBasePrice Varchar(50),
cyBaseCost Varchar(50),
cyFECOMM Varchar(50),
lyRoomNights Varchar(50),
lyBasePrice Varchar(50),
lyBaseCost Varchar(50),
lyFECOMM Varchar(50)
)

CREATE TABLE #HVR_HistoricalTrends_BookToStay
(
BookingMonth Varchar(10),
StayMonth Varchar(10),
TransType Varchar(5),
cyRoomNights Varchar(50),
cyBasePrice Varchar(50),
cyBaseCost Varchar(50),
cyFECOMM Varchar(50)
)

CREATE TABLE #HVR_HistoricalTrends_PK
(
MonthStart Varchar(10),
TransType Varchar(5),
PkIndicator Varchar(50),
PkIndicatorType Varchar(50),
StayDOW Varchar(20),
StarRatings Varchar(20),
ComparisonType Varchar(100),
ComparisonTypeDesc Varchar(200),
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

CREATE TABLE #HVR_RecentTrends_BookToStay
(
BookingMonth Varchar(10),
StayMonth Varchar(10),
TransType Varchar(5),
ComparisonType Varchar(100),
ComparisonTypeDesc Varchar(200),
cyRoomNights Varchar(50),
cyBasePrice Varchar(50),
cyBaseCost Varchar(50),
cyFECOMM Varchar(50)
)

CREATE TABLE #HVR_RecentTrends_DRR_LOS
(
TimePeriod Varchar(50),
TransType Varchar(5),
HasDrrFlag Varchar(3),
LOS Varchar(20),
ComparisonType Varchar(100),
ComparisonTypeDesc Varchar(200),
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

CREATE TABLE #HVR_RecentTrends_DRR_Mobile
(
TimePeriod Varchar(50),
TransType Varchar(5),
POSaBrandName Varchar(50),
MobileIndicator Varchar(50),
RateRuleGroup Varchar(500),
HasDrrFlag Varchar(3),
ComparisonType Varchar(100),
ComparisonTypeDesc Varchar(200),
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


CREATE TABLE #HVR_RecentTrends_DRR_PK
(
TimePeriod Varchar(50),
TransType Varchar(5),
PkIndicator Varchar(50),
PkIndicatorType Varchar(50),
RateRuleGroup Varchar(500),
HasDrrFlag Varchar(3),
BW Varchar(20),
ComparisonType Varchar(100),
ComparisonTypeDesc Varchar(200),
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

CREATE TABLE #HVR_RecentTrends_DRR_POSa
(
TimePeriod Varchar(50),
TransType Varchar(5),
PkIndicator Varchar(50),
PkIndicatorType Varchar(50),
HasDrrFlag Varchar(3),
POSaBrandName Varchar(50),
MobileIndicator Varchar(50),
POSaCountryName Varchar(50),
ComparisonType Varchar(100),
ComparisonTypeDesc Varchar(200),
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

CREATE TABLE #HVR_RecentTrends_Mobile_BW
(
TimePeriod Varchar(50),
TransType Varchar(5),
POSaBrandName Varchar(50),
MobileIndicator Varchar(50),
BW Varchar(20),
ComparisonType Varchar(100),
ComparisonTypeDesc Varchar(200),
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

CREATE TABLE #HVR_RecentTrends_Mobile_DOW
(
TimePeriod Varchar(50),
TransType Varchar(5),
POSaBrandName Varchar(50),
MobileIndicator Varchar(50),
StayDOW Varchar(20),
ComparisonType Varchar(100),
ComparisonTypeDesc Varchar(200),
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

CREATE TABLE #HVR_RecentTrends_Mobile_PK
(
TimePeriod Varchar(50),
TransType Varchar(5),
POSaBrandName Varchar(50),
MobileIndicator Varchar(50),
PkIndicator Varchar(50),
PkIndicatorType Varchar(50),
ComparisonType Varchar(100),
ComparisonTypeDesc Varchar(200),
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
CREATE TABLE #HVR_RecentTrends_Mobile_POSa
(
TimePeriod Varchar(50),
TransType Varchar(5),
POSaBrandName Varchar(50),
MobileIndicator Varchar(50),
POSaCountryName Varchar(50),
ComparisonType Varchar(100),
ComparisonTypeDesc Varchar(200),
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

Print('Begin HVR_FutureTrends_PK_DOW:' + Convert(Varchar(20),GETDATE(),113))

INSERT INTO #HVR_FutureTrends_PK_DOW
(
TimePeriod ,
StayMonth ,
TransType ,
PkIndicator ,
PkIndicatorType ,
StayDOW ,
ComparisonType ,
ComparisonTypeDesc,
StarRatings ,
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
lyTrx 
)
EXEC dbo.GetHVR_FutureTrends_PK_DOW
@BookingType,
@Tuples,
@DataType,
@AsOfFutureMonth,
@AsOfDate,
@Currency,
@StarRatings,
@ReportView,
@CompsetTuples,
@GeosetTuples

Print('Begin HVR_HistoricalTrends:' + Convert(Varchar(20),GETDATE(),113))

INSERT INTO #HVR_HistoricalTrends
(
MonthStart ,
TransType ,
PkIndicator ,
PkIndicatorType ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM 
)
EXEC dbo.GetHVR_HistoricalTrends
@BookingType,
@Tuples,
@DataType,
@AsOfBookingMonth,
@Currency,
@ReportView

Print('Begin HVR_HistoricalTrends_BookToStay:' + Convert(Varchar(20),GETDATE(),113))

INSERT INTO #HVR_HistoricalTrends_BookToStay
(
BookingMonth ,
StayMonth ,
TransType ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM 
)
EXEC dbo.GetHVR_HistoricalTrends_BookToStay
@BookingType,
@Tuples,
@DataType,
@AsOfBookingMonth,
@Currency,
@ReportView

Print('Begin HVR_HistoricalTrends_PK:' + Convert(Varchar(20),GETDATE(),113))

INSERT INTO #HVR_HistoricalTrends_PK
(
MonthStart ,
TransType ,
PkIndicator ,
PkIndicatorType ,
StayDOW ,
Comparisontype ,
ComparisonTypeDesc,
StarRatings ,
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
lyTrx 
)
EXEC dbo.GetHVR_HistoricalTrends_PK
@BookingType,
@Tuples,
@DataType,
@AsOfBookingMonth,
@Currency,
@StarRatings,
@ReportView,
@CompsetTuples, 
@GeosetTuples

Print('Begin HVR_RecentTrends_BookToStay:' + Convert(Varchar(20),GETDATE(),113))

INSERT INTO #HVR_RecentTrends_BookToStay
(
BookingMonth ,
StayMonth ,
TransType ,
Comparisontype ,
ComparisonTypeDesc,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM 
)
EXEC dbo.GetHVR_RecentTrends_BookToStay
@BookingType,
@Tuples,
@DataType,
@AsOfBookingMonth,
@Currency,
@ReportView,
@CompsetTuples, 
@GeosetTuples

Print('Begin HVR_RecentTrends_DRR_LOS:' + Convert(Varchar(20),GETDATE(),113))

INSERT INTO #HVR_RecentTrends_DRR_LOS
(
TimePeriod ,
TransType ,
HasDrrFlag,
LOS ,
Comparisontype ,
ComparisonTypeDesc,
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
lyTrx 
)
EXEC dbo.GetHVR_RecentTrends_DRR_LOS
@BookingType,
@Tuples,
@DataType,
@AsOfDate,
@Currency,
@ReportView,
@CompsetTuples, 
@GeosetTuples,
@TimePeriod,
@YoYDOW

Print('Begin HVR_RecentTrends_DRR_Mobile:' + Convert(Varchar(20),GETDATE(),113))

INSERT INTO #HVR_RecentTrends_DRR_Mobile
(
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
RateRuleGroup ,
HasDrrFlag ,
Comparisontype ,
ComparisonTypeDesc,
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
lyTrx 
)
EXEC dbo.GetHVR_RecentTrends_DRR_Mobile
@BookingType,
@Tuples,
@DataType,
@AsOfDate,
@Currency,
@ReportView,
@CompsetTuples, 
@GeosetTuples,
@TimePeriod,
@YoYDOW

Print('Begin HVR_RecentTrends_DRR_PK:' + Convert(Varchar(20),GETDATE(),113))

INSERT INTO #HVR_RecentTrends_DRR_PK
(
TimePeriod ,
TransType ,
PkIndicator ,
PkIndicatorType ,
RateRuleGroup ,
HasDrrFlag ,
BW ,
Comparisontype ,
ComparisonTypeDesc,
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
lyTrx 
)
EXEC dbo.GetHVR_RecentTrends_DRR_PK
@BookingType,
@Tuples,
@DataType,
@AsOfDate,
@Currency,
@ReportView,
@CompsetTuples, 
@GeosetTuples,
@TimePeriod,
@YoYDOW

Print('Begin HVR_RecentTrends_DRR_POSa:' + Convert(Varchar(20),GETDATE(),113))

INSERT INTO #HVR_RecentTrends_DRR_POSa
(
TimePeriod ,
TransType ,
PkIndicator ,
PkIndicatorType ,
HasDrrFlag ,
POSaBrandName ,
POSaCountryName ,
ComparisonType ,
ComparisonTypeDesc,
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
lyTrx 
)
EXEC dbo.GetHVR_RecentTrends_DRR_POSa
@BookingType,
@Tuples,
@DataType,
@AsOfDate,
@Currency,
@ReportView,
@CompsetTuples, 
@GeosetTuples,
@TimePeriod,
@YoYDOW

Print('Begin HVR_RecentTrends_Mobile_BW:' + Convert(Varchar(20),GETDATE(),113))

INSERT INTO #HVR_RecentTrends_Mobile_BW
(
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
BW ,
ComparisonType,
ComparisonTypeDesc,
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
lyTrx 
)
EXEC dbo.GetHVR_RecentTrends_Mobile_BW
@BookingType,
@Tuples,
@DataType,
@AsOfDate,
@Currency,
@ReportView,
@CompsetTuples, 
@GeosetTuples,
@TimePeriod,
@YoYDOW

Print('Begin HVR_RecentTrends_Mobile_DOW:' + Convert(Varchar(20),GETDATE(),113))

INSERT INTO #HVR_RecentTrends_Mobile_DOW
(
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
StayDOW ,
ComparisonType ,
ComparisonTypeDesc,
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
lyTrx 
)
EXEC dbo.GetHVR_RecentTrends_Mobile_DOW
@BookingType,
@Tuples,
@DataType,
@AsOfDate,
@Currency,
@ReportView,
@CompsetTuples, 
@GeosetTuples,
@TimePeriod,
@YoYDOW

Print('Begin HVR_RecentTrends_Mobile_PK:' + Convert(Varchar(20),GETDATE(),113))

INSERT INTO #HVR_RecentTrends_Mobile_PK
(
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
PkIndicator ,
PkIndicatorType ,
ComparisonType ,
ComparisonTypeDesc,
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
lyTrx 
)
EXEC dbo.GetHVR_RecentTrends_Mobile_PK
@BookingType,
@Tuples,
@DataType,
@AsOfDate,
@Currency,
@ReportView,
@CompsetTuples, 
@GeosetTuples,
@TimePeriod,
@YoYDOW

Print('Begin HVR_RecentTrends_Mobile_POSa:' + Convert(Varchar(20),GETDATE(),113))

INSERT INTO #HVR_RecentTrends_Mobile_POSa
(
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
POSaCountryName ,
ComparisonType ,
ComparisonTypeDesc,
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
lyTrx 
)
EXEC dbo.GetHVR_RecentTrends_Mobile_POSa
@BookingType,
@Tuples,
@DataType,
@AsOfDate,
@Currency,
@ReportView,
@CompsetTuples, 
@GeosetTuples,
@TimePeriod,
@YoYDOW

Print('Begin dbo.HVR_AllData:' + Convert(Varchar(20),GETDATE(),113))

--Combine all 
INSERT INTO dbo.HVR_AllData
(
TimePeriod ,
StayMonth ,
TransType ,
PkIndicator ,
PkIndicatorType ,
StayDOW ,
StarRatings ,
ComparisonType ,
ComparisonTypeDesc,
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
HVRID
)
SELECT
TimePeriod ,
StayMonth ,
TransType ,
PkIndicator ,
PkIndicatorType ,
StayDOW ,
StarRatings ,
ComparisonType ,
ComparisonTypeDesc,
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
'GetHVR_FutureTrends_PK_DOW' SprocName,
GetDate() RunDate,
1 Success,
@HVRID
FROM #HVR_FutureTrends_PK_DOW

INSERT INTO dbo.HVR_ALlData
(
MonthStart ,
TransType ,
PkIndicator ,
PkIndicatorType ,
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
HVRID
)
SELECT
MonthStart ,
TransType ,
PkIndicator ,
PkIndicatorType ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
lyRoomNights ,
lyBasePrice ,
lyBaseCost ,
lyFECOMM ,
'GetHVR_HistoricalTrends' SprocName,
GetDate() RunDate,
1 Success,
@HVRID

FROM #HVR_HistoricalTrends


INSERT INTO dbo.HVR_ALlData
(
BookingMonth ,
StayMonth ,
TransType ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM,
SprocName,
RunDate,
Success,
HVRID 
)
SELECT 
BookingMonth ,
StayMonth ,
TransType ,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
'GetHVR_HistoricalTrends_BookToStay' SprocName,
GetDate() RunDate,
1 Success,
@HVRID
FROM #HVR_HistoricalTrends_BookToStay


INSERT INTO dbo.HVR_ALlData
(
MonthStart ,
TransType ,
PkIndicator ,
PkIndicatorType ,
StayDOW ,
StarRatings ,
Comparisontype ,
ComparisonTypeDesc,
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
HVRID 
)
SELECT
MonthStart ,
TransType ,
PkIndicator ,
PkIndicatorType ,
StayDOW ,
StarRatings ,
Comparisontype ,
ComparisonTypeDesc,
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
'GetHVR_HistoricalTrends_PK' SprocName,
GetDate() RunDate,
1 Success,
@HVRID
FROM #HVR_HistoricalTrends_PK


INSERT INTO dbo.HVR_ALlData
(
BookingMonth ,
StayMonth ,
TransType ,
Comparisontype ,
ComparisonTypeDesc,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
SprocName,
RunDate,
Success,
HVRID 
)
SELECT
BookingMonth ,
StayMonth ,
TransType ,
Comparisontype ,
ComparisonTypeDesc,
cyRoomNights ,
cyBasePrice ,
cyBaseCost ,
cyFECOMM ,
'GetHVR_RecentTrends_BookToStay' SprocName,
GetDate() RunDate,
1 Success,
@HVRID
FROM #HVR_RecentTrends_BookToStay


INSERT INTO dbo.HVR_ALlData
(
TimePeriod ,
TransType ,
HasDrrFlag,
LOS ,
Comparisontype ,
ComparisonTypeDesc,
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
HVRID 
)
SELECT 
TimePeriod ,
TransType ,
HasDrrFlag,
LOS ,
Comparisontype ,
ComparisonTypeDesc,
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
'GetHVR_RecentTrends_DRR_LOS' SprocName,
GetDate() RunDate,
1 Success,
@HVRID
FROM #HVR_RecentTrends_DRR_LOS


INSERT INTO dbo.HVR_ALlData
(
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
RateRuleGroup ,
HasDrrFlag ,
Comparisontype ,
ComparisonTypeDesc,
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
SprocName,
RunDate,
Success,
HVRID
)
SELECT
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
RateRuleGroup ,
HasDrrFlag ,
Comparisontype ,
ComparisonTypeDesc,
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
'GetHVR_RecentTrends_DRR_Mobile' SprocName,
GetDate() RunDate,
1 Success,
@HVRID
FROM #HVR_RecentTrends_DRR_Mobile


INSERT INTO dbo.HVR_ALlData
(
TimePeriod ,
TransType ,
PkIndicator ,
PkIndicatorType ,
RateRuleGroup ,
HasDrrFlag ,
BW ,
Comparisontype ,
ComparisonTypeDesc,
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
SprocName,
RunDate,
Success,
HVRID
)
SELECT
TimePeriod ,
TransType ,
PkIndicator ,
PkIndicatorType ,
RateRuleGroup ,
HasDrrFlag ,
BW ,
Comparisontype ,
ComparisonTypeDesc,
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
'GetHVR_RecentTrends_DRR_PK' SprocName,
GetDate() RunDate,
1 Success,
@HVRID
FROM #HVR_RecentTrends_DRR_PK


INSERT INTO dbo.HVR_ALlData
(
TimePeriod ,
TransType ,
PkIndicator ,
PkIndicatorType ,
HasDrrFlag ,
POSaBrandName ,
MobileIndicator ,
POSaCountryName ,
ComparisonType ,
ComparisonTypeDesc,
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
SprocName,
RunDate,
Success,
HVRID
)
SELECT
TimePeriod ,
TransType ,
PkIndicator ,
PkIndicatorType ,
HasDrrFlag ,
POSaBrandName ,
MobileIndicator ,
POSaCountryName ,
ComparisonType ,
ComparisonTypeDesc,
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
'GetHVR_RecentTrends_DRR_POSa' SprocName,
GetDate() RunDate,
1 Success,
@HVRID
FROM #HVR_RecentTrends_DRR_POSa

INSERT INTO dbo.HVR_ALlData
(
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
BW ,
ComparisonType,
ComparisonTypeDesc,
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
SprocName,
RunDate,
Success,
HVRID
)
SELECT 
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
BW ,
ComparisonType,
ComparisonTypeDesc,
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
'GetHVR_RecentTrends_Mobile_BW' SprocName,
GetDate() RunDate,
1 Success,
@HVRID
FROM #HVR_RecentTrends_Mobile_BW


INSERT INTO dbo.HVR_ALlData
(
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
StayDOW ,
ComparisonType ,
ComparisonTypeDesc,
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
SprocName,
RunDate,
Success,
HVRID
)
SELECT
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
StayDOW ,
ComparisonType ,
ComparisonTypeDesc,
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
'GetHVR_RecentTrends_Mobile_DOW' SprocName,
GetDate() RunDate,
1 Success,
@HVRID
FROM #HVR_RecentTrends_Mobile_DOW


INSERT INTO dbo.HVR_ALlData
(
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
PkIndicator ,
PkIndicatorType ,
ComparisonType ,
ComparisonTypeDesc,
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
SprocName,
RunDate,
Success,
HVRID
)
SELECT
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
PkIndicator ,
PkIndicatorType ,
ComparisonType ,
ComparisonTypeDesc,
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
'GetHVR_RecentTrends_Mobile_PK' SprocName,
GetDate() RunDate,
1 Success,
@HVRID
FROM #HVR_RecentTrends_Mobile_PK


INSERT INTO dbo.HVR_ALlData
(
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
POSaCountryName,
ComparisonType ,
ComparisonTypeDesc,
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
SprocName,
RunDate,
Success,
HVRID
)
SELECT 
TimePeriod ,
TransType ,
POSaBrandName ,
MobileIndicator ,
POSaCountryName,
ComparisonType ,
ComparisonTypeDesc,
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
'GetHVR_RecentTrends_Mobile_POSa' SprocName,
GetDate() RunDate,
1 Success,
@HVRID
FROM #HVR_RecentTrends_Mobile_POSa

			