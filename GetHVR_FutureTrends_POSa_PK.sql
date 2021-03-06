USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetHVR_FutureTrends_POSa_PK]    Script Date: 05/01/2015 11:02:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[GetHVR_FutureTrends_POSa_PK]
@BookingType Varchar(4000) ='{[Booking Type].[Business Model Subtype].&[Merchant]}',
@Tuples Varchar(4000) = '[Hotel].[Parent Chain Id].&[-16]',--[Hotel].[Hotel Key].&[240750]
@DataType Varchar(10) ='Booked',
@AsOfBookingMonth Datetime ='06/01/2014',
@AsOfDate DateTime ='06/30/2014',
@Currency Varchar(10) = 'USD',
@StarRatings Varchar(4000) ='{[Hotel].[Star Rating].&[3.],[Hotel].[Star Rating].&[2.5]}',
@ReportView Int = 0,  -- 0 = hotel, 2 = account group, 3 = parent chain
@ComparisonType Int = 1, -- 0 = compset, 1 = geo only, 2 = geo & compset 
@CompsetType Int = 0, -- 0 = PPC , 1 = UDC
@GeoType Int = 0, -- 0 = market, 1 = submarket
@CompsetTuples Varchar(4000) = '{[Hotel].[Parent Chain Id].&[-16]}',
@GeosetTuples Varchar(4000) = '{[Hotel].[Market].&[San Francisco]}'

AS 

SET NOCOUNT ON
SET ANSI_WARNINGS ON
SET ANSI_NULLS ON 

DECLARE @MDXQuery Varchar(4000),@Dimension Varchar(50),@Metrics Varchar(1500),@TimePeriodString Varchar(50)

SELECT @Dimension = CASE @DataType WHEN 'Booked' THEN '[Booking Date]' ELSE '[Stay Date]' END

SELECT @Metrics = CASE @Currency WHEN 'USD' THEN
'	-- current year
	MEMBER  [Measures].[cyBasePrice] AS [Measures].[USD Base Price]
	MEMBER  [Measures].[cyBaseCost] AS [Measures].[USD Base Cost]
	MEMBER  [Measures].[cyFECOMM] AS [Measures].[USD Front-End Commission]

	-- last year
	MEMBER [Measures].[lyBasePrice] AS ([Stay Date].[Month Start].CurrentMember.Lag(12),([lyBookedDateRange],[Measures].[USD Base Price]))
	MEMBER [Measures].[lyBaseCost] AS ([Stay Date].[Month Start].CurrentMember.Lag(12),([lyBookedDateRange],[Measures].[USD Base Cost]))
	MEMBER [Measures].[lyFECOMM] AS ([Stay Date].[Month Start].CurrentMember.Lag(12),([lyBookedDateRange],[Measures].[USD Front-End Commission]))
'
ELSE
'	-- current year
	MEMBER  [Measures].[cyBasePrice] AS [Measures].[Hotel Base Price]
	MEMBER  [Measures].[cyBaseCost] AS [Measures].[Hotel Base Cost]
	MEMBER  [Measures].[cyFECOMM] AS [Measures].[Hotel Front-End Commission]

	-- last year
	MEMBER [Measures].[lyBasePrice] AS (([Stay Date].[Month Start].CurrentMember.Lag(12)),([lyBookedDateRange],[Measures].[Hotel Base Price]))
	MEMBER [Measures].[lyBaseCost] AS (([Stay Date].[Month Start].CurrentMember.Lag(12),([lyBookedDateRange],[Measures].[Hotel Base Cost]))
	MEMBER [Measures].[lyFECOMM] AS (([Stay Date].[Month Start].CurrentMember.Lag(12),([lyBookedDateRange],[Measures].[Hotel Front-End Commission]))
' 
END

SELECT @MdxQuery = 'SELECT * FROM OPENQUERY(EDWCUBES_LODGINGBOOKING,''
WITH

SET [StayDateRange] AS LastPeriods(-6,[Stay Date].[Month Start].&['+CONVERT(Varchar(10),@AsOfBookingMonth,120)+'T00:00:00])

--For all stays OTB of current year
MEMBER [Booking Date].[Calendar].[cyBookedDateRange] as Aggregate([Booking Date].[Calendar].[Date].&['+CONVERT(Varchar(10),DateAdd(m,-12,@AsOfBookingMonth),120)+'T00:00:00]:[Booking Date].[Calendar].[Date].&['+CONVERT(Varchar(10),@AsOfDate,120)+'T00:00:00])

--For all stays OTB of last year
MEMBER [Booking Date].[Calendar].[lyBookedDateRange] as Aggregate([Booking Date].[Calendar].[Date].&['+CONVERT(Varchar(10),DateAdd(m,-24,@AsOfBookingMonth),120)+'T00:00:00]:[Booking Date].[Calendar].[Date].&['+CONVERT(Varchar(10),DateAdd(d,-365,@AsOfDate),120)+'T00:00:00])

SET [Booked FS] AS ([cyBookedDateRange],[StayDateRange]) 

-- Create hotel and the total market/submarket/compset
SET [Controlset] AS ('+@Tuples+')
SET [Geoset] AS ('+@GeosetTuples+')'

+ CASE @ReportView 
	WHEN 0 THEN '
	MEMBER [Hotel].[Hotel Key].[GeosetTotal] AS Aggregate([Geoset])
	MEMBER [Hotel].[Hotel Key].[CompsetTotal] AS Aggregate('+@CompsetTuples+')'
	WHEN 2 THEN '
	MEMBER [Account Group].[Account Group Name].[GeosetTotal] AS Aggregate([Geoset])
	MEMBER [Account Group].[Account Group Name].[CompsetTotal] AS Aggregate('+@CompsetTuples+')'
	WHEN 3 THEN '
	MEMBER [Hotel].[Parent Chain Id].[GeosetTotal] AS Aggregate([Geoset])
	MEMBER [Hotel].[Parent Chain Id].[CompsetTotal] AS Aggregate('+@CompsetTuples+')' END + '

SET MainSets AS EXISTS(
[Booked FS] *
{
	[Transaction Type].[Transaction Type].[All].Net,
	[Transaction Type].[Transaction Type].[Transaction Type Group].&[Gross]
} *
[Point of Sale].[Brand Name].[Brand Name] *
[Management Unit].[Management Unit Name].[Management Unit Name] *
--[Point of Sale].[Point of Sale].[Point of Sale Country] *
--[Point of Sale].[Point of Sale Super Region].[Point of Sale Super Region] *
[Package Indicator].[Package Indicator].[Package Indicator] *
[Package Indicator].[Package Indicator Type].[Package Indicator Type] *
{[Controlset],[GeosetTotal],[CompsetTotal]})

-- current year
	MEMBER  [Measures].[cyRoomNights] AS [Measures].[Room Nights]
	MEMBER	[Measures].[cyTDBA] AS [Measures].[Total Booking Window]
	MEMBER	[Measures].[cyTrx] AS [Measures].[Transactions]

	-- last year
	MEMBER [Measures].[lyRoomNights] AS (([Stay Date].[Month Start].CurrentMember.Lag(12)),([lyBookedDateRange],[Measures].[Room Nights]))
	MEMBER [Measures].[lyTDBA] AS (([Stay Date].[Month Start].CurrentMember.Lag(12)),([lyBookedDateRange],[Measures].[Total Booking Window]))
	MEMBER [Measures].[lyTrx] AS  (([Stay Date].[Month Start].CurrentMember.Lag(12)),([lyBookedDateRange],[Measures].[Transactions]))
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
