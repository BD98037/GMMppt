USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetHVR_HistoricalTrends_PK]    Script Date: 05/01/2015 11:03:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[GetHVR_HistoricalTrends_PK]
@BookingType Varchar(4000) ='{[Booking Type].[Business Model Subtype].&[Merchant]}',
@Tuples Varchar(4000) = '[Account Group].[Account Group Name].&[25hours Hotels]',
@DataType Varchar(10) ='Booked',
@AsOfBookingMonth Datetime ='06/01/2014',
@Currency Varchar(10) = 'USD',
@StarRatings Varchar(4000) ='{[Hotel].[Star Rating].&[4.0],[Hotel].[Star Rating].&[3.5]}',
@ReportView Int =2,  -- 0 = hotel, 2 = account group, 3 = parent chain
@CompsetTuples Varchar(4000) = '{[Hotel].[Hotel Name].&[240750],[Hotel].[Hotel Name].&[240800]}', 
@GeosetTuples Varchar(4000) = '{[Hotel].[Market Id].&[95194]}'

AS 

SET NOCOUNT ON
SET ANSI_WARNINGS ON
SET ANSI_NULLS ON 

DECLARE @MDXQuery1 Varchar(4000),@MDXQuery2 Varchar(4000),@MDXQuery3 Varchar(4000),@Dimension Varchar(50),@Metrics Varchar(1500),@TimePeriodString Varchar(50)

SELECT @Dimension = CASE @DataType WHEN 'Booked' THEN '[Booking Date]' ELSE '[Stay Date]' END

SELECT @Metrics = CASE @Currency WHEN 'USD' THEN
'	-- current year
	MEMBER  [Measures].[cyBasePrice] AS [Measures].[USD Base Price]
	MEMBER  [Measures].[cyBaseCost] AS [Measures].[USD Base Cost]
	MEMBER  [Measures].[cyFECOMM] AS [Measures].[USD Front-End Commission]

	-- last year
	MEMBER [Measures].[lyBasePrice] AS ('+@Dimension+'.[Month Start].CurrentMember.Lag(12),[Measures].[USD Base Price])
	MEMBER [Measures].[lyBaseCost] AS ('+@Dimension+'.[Month Start].CurrentMember.Lag(12),[Measures].[USD Base Cost])
	MEMBER [Measures].[lyFECOMM] AS ('+@Dimension+'.[Month Start].CurrentMember.Lag(12),[Measures].[USD Front-End Commission])
'
ELSE
'	-- current year
	MEMBER  [Measures].[cyBasePrice] AS [Measures].[Hotel Base Price]
	MEMBER  [Measures].[cyBaseCost] AS [Measures].[Hotel Base Cost]
	MEMBER  [Measures].[cyFECOMM] AS [Measures].[Hotel Front-End Commission]

	-- last year
	MEMBER [Measures].[lyBasePrice] AS ('+@Dimension+'.[Month Start].CurrentMember.Lag(12),[Measures].[Hotel Base Price])
	MEMBER [Measures].[lyBaseCost] AS ('+@Dimension+'.[Month Start].CurrentMember.Lag(12),[Measures].[Hotel Base Cost])
	MEMBER [Measures].[lyFECOMM] AS ('+@Dimension+'.[Month Start].CurrentMember.Lag(12),[Measures].[Hotel Front-End Commission])
' 
END

SELECT @MDXQuery1 = 'SELECT * FROM OPENQUERY(EDWCUBES_LODGINGBOOKING,''
WITH

SET [DateRange] AS LastPeriods(6,'+@Dimension+'.[Month Start].&['+CONVERT(Varchar(10),@AsOfBookingMonth,120)+'T00:00:00])


SET [StarRatings] AS '+@StarRatings+'

-- Create hotel and the total market/submarket/compset
SET [Controlset] AS ('+@Tuples+')
SET [Geoset] AS ('+@GeosetTuples+')

MEMBER [Hotel].[Hotel Key].[GeosetTotal] AS Aggregate([Geoset])
MEMBER [Hotel].[Hotel Key].[CompsetTotal] AS Aggregate([Compset]) '

SELECT @MDXQuery2 = '
SET [Compset] AS ('+@CompsetTuples+')'

SELECT @MDXQuery3 = ' '

+ CASE @ReportView 
	WHEN 0 THEN '
	MEMBER [Hotel].[Hotel Key].[ControlsetTotal] AS Aggregate([Controlset]) '
	WHEN 2 THEN '
	SET [ControlsetTotal] AS [Controlset] '
	WHEN 3 THEN '
	MEMBER [Hotel].[Hotel Key].[ControlsetTotal] AS Aggregate([Controlset]) ' END + '

SET MainSets AS EXISTS(
[DateRange] *
{
	[Transaction Type].[Transaction Type].[All].Net,
	[Transaction Type].[Transaction Type].[Transaction Type Group].&[Gross]
} *
[Package Indicator].[Package Indicator].[Package Indicator] *
[Package Indicator].[Package Indicator Type].[Package Indicator Type] *
[Stay Date].[Day of Week].[Day of Week] * '
--[StarRatings]
+ CASE WHEN @ReportView = 2 THEN '
{([Hotel].[Hotel Key].[All],[ControlsetTotal],[Hotel].[Star Rating].[ALL]),([GeosetTotal],[Account Group].[Account Group Name].[All],[StarRatings]),([CompsetTotal],[Account Group].[Account Group Name].[All],[Hotel].[Star Rating].[ALL])} ' ELSE '
{([ControlsetTotal],[Account Group].[Account Group Name].[All],[StarRatings]),([GeosetTotal],[Account Group].[Account Group Name].[All],[StarRatings]),([CompsetTotal],[Account Group].[Account Group Name].[All],[Hotel].[Star Rating].[ALL])} ' END + '
)

-- current year
	MEMBER  [Measures].[cyRoomNights] AS [Measures].[Room Nights]
	MEMBER	[Measures].[cyTDBA] AS [Measures].[Total Booking Window]
	MEMBER	[Measures].[cyTrx] AS [Measures].[Transactions]

	-- last year
	MEMBER [Measures].[lyRoomNights] AS ('+@Dimension+'.[Month Start].CurrentMember.Lag(12),[Measures].[Room Nights])
	MEMBER	[Measures].[lyTDBA] AS ('+@Dimension+'.[Month Start].CurrentMember.Lag(12),[Measures].[Total Booking Window])
	MEMBER	[Measures].[lyTrx] AS ('+@Dimension+'.[Month Start].CurrentMember.Lag(12),[Measures].[Transactions])
'
+
	@Metrics 
+  
'

SELECT 
NON EMPTY 
{
[Measures].[cyRoomNights],
[Measures].[cyBasePrice],
[Measures].[cyBaseCost],
[Measures].[cyFECOMM],
[Measures].[cyTDBA], 
[Measures].[cyTrx],

[Measures].[lyRoomNights],
[Measures].[lyBasePrice],
[Measures].[lyBaseCost],
[Measures].[lyFECOMM],
[Measures].[lyTDBA] ,
[Measures].[lyTrx]
} ON COLUMNS,
NON EMPTY( 

      MainSets
                                                        
) ON ROWS

	FROM ( 
		SELECT ({'+@BookingType+ '}) ON COLUMNS 

			FROM LodgingBooking)
							     
'')'
--SELECT @MDXQuery
EXEC (@MDXQuery1+@MDXQuery2+@MDXQuery3)
