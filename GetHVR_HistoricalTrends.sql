USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetHVR_HistoricalTrends]    Script Date: 05/01/2015 11:03:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[GetHVR_HistoricalTrends]
@BookingType Varchar(4000) ='{[Booking Type].[Business Model Subtype].&[Merchant]}',
@Tuples Varchar(4000) = '{[Hotel].[Parent Chain Id].&[-16]}',
@DataType Varchar(10) ='Booked',
@AsOfBookingMonth Datetime ='06/01/2014',
@Currency Varchar(10) = 'USD',
@ReportView Int = 2

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
	
	-- last year
	MEMBER [Measures].[lyRoomNights] AS ('+@Dimension+'.[Month Start].CurrentMember.Lag(12),[Measures].[Room Nights])
	MEMBER [Measures].[lyBasePrice] AS ('+@Dimension+'.[Month Start].CurrentMember.Lag(12),[Measures].[USD Base Price])
	MEMBER [Measures].[lyBaseCost] AS ('+@Dimension+'.[Month Start].CurrentMember.Lag(12),[Measures].[USD Base Cost])
	MEMBER [Measures].[lyFECOMM] AS ('+@Dimension+'.[Month Start].CurrentMember.Lag(12),[Measures].[USD Front-End Commission])
'
ELSE
'	-- current year
	MEMBER	[Measures].[cyRoomNights] AS [Measures].[Room Nights]
	MEMBER  [Measures].[cyBasePrice] AS [Measures].[Hotel Base Price]
	MEMBER  [Measures].[cyBaseCost] AS [Measures].[Hotel Base Cost]
	MEMBER  [Measures].[cyFECOMM] AS [Measures].[Hotel Front-End Commission]

	-- last year
	MEMBER [Measures].[lyRoomNights] AS ('+@Dimension+'.[Month Start].CurrentMember.Lag(12),[Measures].[Room Nights])
	MEMBER [Measures].[lyBasePrice] AS ('+@Dimension+'.[Month Start].CurrentMember.Lag(12),[Measures].[Hotel Base Price])
	MEMBER [Measures].[lyBaseCost] AS ('+@Dimension+'.[Month Start].CurrentMember.Lag(12),[Measures].[Hotel Base Cost])
	MEMBER [Measures].[lyFECOMM] AS ('+@Dimension+'.[Month Start].CurrentMember.Lag(12),[Measures].[Hotel Front-End Commission])
' 
END

SELECT @MdxQuery = 'SELECT * FROM OPENQUERY(EDWCUBES_LODGINGBOOKING,''
WITH

SET [DateRange] AS LastPeriods(12,'+@Dimension+'.[Month Start].&['+CONVERT(Varchar(10),@AsOfBookingMonth,120)+'T00:00:00])

SET MainSets AS EXISTS(
[DateRange] *
{
	[Transaction Type].[Transaction Type].[All].Net,
	[Transaction Type].[Transaction Type].[Transaction Type Group].&[Gross]
} *
[Package Indicator].[Package Indicator].[Package Indicator] *
[Package Indicator].[Package Indicator Type].[Package Indicator Type] 		
)

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
		FROM ( 
			SELECT ({'+(@Tuples)+'}) ON COLUMNS

					FROM LodgingBooking))						     
'')'
--SELECT @MDXQuery
EXEC (@MDXQuery)
