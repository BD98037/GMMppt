USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetMMW_RecentTrends_Mobile_LOS]    Script Date: 05/01/2015 11:10:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[GetMMW_RecentTrends_Mobile_LOS]
@BookingType Varchar(4000) ='{[Booking Type].[Business Model Subtype].&[Merchant]}',
@Tuples Varchar(4000) = '[Hotel].[Market].&[Miami, FL]',
@GeosetTuples Varchar(4000) = '{[Hotel].[Market].&[Macau],[Hotel].[Market].&[Maui]}',
@DataType Varchar(10) ='Booked',
@AsOfDate Datetime ='06/01/2014',
@Currency Varchar(10) = 'USD',
@TimePeriod Int = 365,
@YoYDOW int =1

AS 

SET NOCOUNT ON
SET ANSI_WARNINGS ON
SET ANSI_NULLS ON 


DECLARE @MDXQuery Varchar(4000),@Dimension Varchar(50),@Metrics Varchar(3000),
		@TimePeriodString Varchar(50),@YoYString Varchar(200)

SELECT @Dimension = CASE @DataType WHEN 'Booked' THEN '[Booking Date]' ELSE '[Stay Date]' END

SET @TimePeriodString = '[TimePeriod' +Convert(Varchar(10),@TimePeriod)+']'

SELECT @YoYString = CASE @YoYDOW WHEN 1 THEN '[Time Calculations].[Prior Year]' 
						ELSE '(('+@Dimension+'.[Calendar].[Date].['+CONVERT(Varchar(10),DateAdd(d,-@TimePeriod+1,@AsOfDate),120)+']).lag(365):('+@Dimension+'.[Calendar].[Date].['+CONVERT(Varchar(10),@AsOfDate,120)+']).lag(365))' END

SELECT @Metrics = CASE @Currency WHEN 'USD' THEN
'	-- current year
	MEMBER  [Measures].[cyBasePrice] AS [Measures].[USD Base Price]
	MEMBER  [Measures].[cyBaseCost] AS [Measures].[USD Base Cost]
	MEMBER  [Measures].[cyFECOMM] AS [Measures].[USD Front-End Commission]

	-- last year
	MEMBER  [Measures].[lyBasePrice] AS SUM(('+@YoYString+'),[Measures].[USD Base Price])
	MEMBER  [Measures].[lyBaseCost] AS SUM(('+@YoYString+'),[Measures].[USD Base Cost])
	MEMBER  [Measures].[lyFECOMM] AS SUM(('+@YoYString+'),[Measures].[USD Front-End Commission])
'
ELSE
'	-- current year
	MEMBER  [Measures].[cyBasePrice] AS [Measures].[Hotel Base Price]
	MEMBER  [Measures].[cyBaseCost] AS [Measures].[Hotel Base Cost]
	MEMBER  [Measures].[cyFECOMM] AS [Measures].[Hotel Front-End Commission]

	-- last year
	MEMBER [Measures].[lyBasePrice] AS SUM(('+@YoYString+'),[Measures].[Hotel Base Price])
	MEMBER [Measures].[lyBaseCost] AS SUM(('+@YoYString+'),[Measures].[Hotel Base Cost])
	MEMBER [Measures].[lyFECOMM] AS SUM(('+@YoYString+'),[Measures].[Hotel Front-End Commission])
' 
END

SET @Metrics = @Metrics + ' 

	-- current year
	MEMBER  [Measures].[cyRoomNights] AS [Measures].[Room Nights]
	MEMBER	[Measures].[cyTDBA] AS [Measures].[Total Booking Window]
	MEMBER	[Measures].[cyTrx] AS [Measures].[Transactions]

	-- last year
	MEMBER [Measures].[lyRoomNights] AS SUM(('+@YoYString+'),[Measures].[Room Nights])
	MEMBER	[Measures].[lyTDBA] AS SUM(('+@YoYString+'),[Measures].[Total Booking Window])
	MEMBER	[Measures].[lyTrx] AS SUM(('+@YoYString+'),[Measures].[Transactions])
	
	'

SELECT @MdxQuery = 'SELECT * FROM OPENQUERY(EDWCUBES_LODGINGBOOKING,''
WITH

SET [DateRange] AS LastPeriods('+Convert(varchar(10),@TimePeriod)+','+@Dimension+'.[Calendar].[Date].['+CONVERT(Varchar(10),@AsOfDate,120)+'])

MEMBER ' +@Dimension+ '.[Calendar].'+@TimePeriodString+' AS Aggregate([DateRange]) 

SET [Controlset] AS ('+@Tuples+')
SET [Geoset] As ('+@GeosetTuples+')

SET MainSets AS EXISTS(
'+@TimePeriodString+' *
{
	[Transaction Type].[Transaction Type].[All].Net,
	[Transaction Type].[Transaction Type].[Transaction Type Group].&[Gross]
} *
{[Point of Sale].[Brand Name].&[Expedia],[Point of Sale].[Brand Name].&[Hotels.com]} *
[Mobile Indicator].[Mobile Indicator].[Mobile Indicator] *
[Length Of Stay].[Length of Stay Range].[Length of Stay Range] *
{[Controlset],[Geoset]})

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
EXEC (@MDXQuery)
