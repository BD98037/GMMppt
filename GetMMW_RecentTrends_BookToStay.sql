USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetMMW_RecentTrends_BookToStay]    Script Date: 05/01/2015 11:08:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[GetMMW_RecentTrends_BookToStay]
@BookingType Varchar(4000) ='{[Booking Type].[Business Model Subtype].&[Merchant]}',
@Tuples Varchar(4000) = '[Hotel].[Market].&[Miami, FL]',
@GeosetTuples Varchar(4000) = '{[Hotel].[Market].&[Macau],[Hotel].[Market].&[Maui]}',
@DataType Varchar(10) ='Booked',
@AsOfBookingMonth Datetime ='06/01/2014',
@Currency Varchar(10) = 'USD'

AS 

SET NOCOUNT ON
SET ANSI_WARNINGS ON
SET ANSI_NULLS ON 

DECLARE @MDXQuery Varchar(4000),@Dimension Varchar(50),@Metrics Varchar(1000)

SELECT @Dimension = CASE @DataType WHEN 'Booked' THEN '[Booking Date]' ELSE '[Stay Date]' END

SELECT @Metrics = CASE @Currency WHEN 'USD' THEN
'	-- current year
	MEMBER  [Measures].[cyRoomNights] AS [Measures].[Room Nights]
	MEMBER  [Measures].[cyBasePrice] AS [Measures].[USD Base Price]
	MEMBER  [Measures].[cyBaseCost] AS [Measures].[USD Base Cost]
	MEMBER  [Measures].[cyFECOMM] AS [Measures].[USD Front-End Commission]
'
ELSE
'	-- current year
	MEMBER	[Measures].[cyRoomNights] AS [Measures].[Room Nights]
	MEMBER  [Measures].[cyBasePrice] AS [Measures].[Hotel Base Price]
	MEMBER  [Measures].[cyBaseCost] AS [Measures].[Hotel Base Cost]
	MEMBER  [Measures].[cyFECOMM] AS [Measures].[Hotel Front-End Commission]
' 
END

SELECT @MdxQuery = 'SELECT * FROM OPENQUERY(EDWCUBES_LODGINGBOOKING,''
WITH

SET [BookedDateRange] AS LastPeriods(12,[Booking Date].[Month Start].&['+CONVERT(Varchar(10),@AsOfBookingMonth,120)+'T00:00:00])

SET [StayedDateRange] AS LastPeriods(6,[Stay Date].[Month Start].&['+CONVERT(Varchar(10),@AsOfBookingMonth,120)+'T00:00:00])

SET [Controlset] AS ('+@Tuples+',[Hotel].[Submarket].[Submarket])
SET [Geoset] As ('+@GeosetTuples+',[Hotel].[Submarket].[All])

SET MainSets AS EXISTS(
[BookedDateRange] *
[StayedDateRange] *
{
	[Transaction Type].[Transaction Type].[All].Net,
	[Transaction Type].[Transaction Type].[Transaction Type Group].&[Gross]
} *
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
[Measures].[cyFECOMM]

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
