USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetMMW_FutureTrends_POSa]    Script Date: 05/01/2015 11:07:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[GetMMW_FutureTrends_POSa]
@BookingType Varchar(4000) ='{[Booking Type].[Business Model Subtype].&[Merchant]}',
@Tuples Varchar(4000) = '[Hotel].[Market].&[Miami, FL]',
@GeosetTuples Varchar(4000) = '{[Hotel].[Market].&[Macau],[Hotel].[Market].&[Maui]}',
@AsOfBookingMonth Datetime ='06/01/2014',
@AsOfDate DateTime ='06/30/2014',
@Currency Varchar(10) = 'USD'

AS 

SET NOCOUNT ON
SET ANSI_WARNINGS ON
SET ANSI_NULLS ON 

DECLARE @MDXQuery Varchar(4000),@Dimension Varchar(50),@Metrics Varchar(1000)



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
MEMBER [Booking Date].[Calendar].[cyBookedDateRange] as Aggregate([Booking Date].[Calendar].[Date].&['+CONVERT(Varchar(10),DateAdd(m,-18,@AsOfBookingMonth),120)+'T00:00:00]:[Booking Date].[Calendar].[Date].&['+CONVERT(Varchar(10),@AsOfDate,120)+'T00:00:00])

--For all stays OTB of last year
MEMBER [Booking Date].[Calendar].[lyBookedDateRange] as Aggregate([Booking Date].[Calendar].[Date].&['+CONVERT(Varchar(10),DateAdd(m,-30,@AsOfBookingMonth),120)+'T00:00:00]:[Booking Date].[Calendar].[Date].&['+CONVERT(Varchar(10),DateAdd(d,-365,@AsOfDate),120)+'T00:00:00])

SET [Booked FS] AS ([cyBookedDateRange],[StayDateRange]) 

SET [Controlset] AS ('+@Tuples+')
SET [Geoset] As ('+@GeosetTuples+')

--SET [Hotel].[Market].[Groupset] AS IIF([Hotel].[Market].CurrentMember.Name ='+@Tuples+'.Name,"Control","Compete")

SET MainSets AS (
[Booked FS] *
{
	[Transaction Type].[Transaction Type].[All].Net,
	[Transaction Type].[Transaction Type].[Transaction Type Group].&[Gross]
} *
[Point of Sale].[Brand Name].[Brand Name] *
[Point of Sale].[Point of Sale Country].[Point of Sale Country] *
[Point of Sale].[Point of Sale Super Region].[Point of Sale Super Region] *
{[Controlset],[Geoset]})

-- current year
	MEMBER  [Measures].[cyRoomNights] AS [Measures].[Room Nights]

-- last year
	MEMBER [Measures].[lyRoomNights] AS (([Stay Date].[Month Start].CurrentMember.Lag(12)),([lyBookedDateRange],[Measures].[Room Nights]))
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

[Measures].[lyRoomNights],
[Measures].[lyBasePrice],
[Measures].[lyBaseCost],
[Measures].[lyFECOMM]

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
