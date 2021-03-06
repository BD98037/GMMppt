USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetHVR_FutureTrends_PK_DOW]    Script Date: 05/01/2015 11:02:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[GetHVR_FutureTrends_PK_DOW]
@BookingType Varchar(4000) ='{[Booking Type].[Business Model Subtype].&[Merchant]}',
@Tuples Varchar(4000) = '[Hotel].[Hotel Name].&[292812]',--'[Account Group].[Account Group Name].&[25hours Hotels]',
@DataType Varchar(10) ='Booked',
@AsOfBookingMonth Datetime ='06/01/2014',
@AsOfDate DateTime ='06/30/2014',
@Currency Varchar(10) = 'USD',
@StarRatings Varchar(4000) ='{[Hotel].[Star Rating].&[4.0],[Hotel].[Star Rating].&[3.5]}',
@ReportView Int = 0,  -- 0 = hotel, 2 = account group, 3 = parent chain
@CompsetTuples Varchar(4000) ='{[Hotel].[Hotel Name].&[292812],[Hotel].[Hotel Name].&[556051],[Hotel].[Hotel Name].&[2214943],[Hotel].[Hotel Name].&[3283497],[Hotel].[Hotel Name].&[253790],[Hotel].[Hotel Name].&[3816287],[Hotel].[Hotel Name].&[249748],[Hotel].[Hotel Name].&[260924],[Hotel].[Hotel Name].&[246283],[Hotel].[Hotel Name].&[241295],[Hotel].[Hotel Name].&[594905],[Hotel].[Hotel Name].&[3083966],[Hotel].[Hotel Name].&[415674],[Hotel].[Hotel Name].&[243088],[Hotel].[Hotel Name].&[3894720],[Hotel].[Hotel Name].&[3354567],[Hotel].[Hotel Name].&[263260],[Hotel].[Hotel Name].&[3940802],[Hotel].[Hotel Name].&[246147],[Hotel].[Hotel Name].&[250553],[Hotel].[Hotel Name].&[258068],[Hotel].[Hotel Name].&[271234],[Hotel].[Hotel Name].&[243425],[Hotel].[Hotel Name].&[254651],[Hotel].[Hotel Name].&[3890482],[Hotel].[Hotel Name].&[257087],[Hotel].[Hotel Name].&[3817118],[Hotel].[Hotel Name].&[246276],[Hotel].[Hotel Name].&[272312],[Hotel].[Hotel Name].&[3881942],[Hotel].[Hotel Name].&[263860],[Hotel].[Hotel Name].&[270743],[Hotel].[Hotel Name].&[252623],[Hotel].[Hotel Name].&[285238],[Hotel].[Hotel Name].&[253323],[Hotel].[Hotel Name].&[482730],[Hotel].[Hotel Name].&[262397],[Hotel].[Hotel Name].&[3893158],[Hotel].[Hotel Name].&[2816150],[Hotel].[Hotel Name].&[268122],[Hotel].[Hotel Name].&[383853],[Hotel].[Hotel Name].&[3351698],[Hotel].[Hotel Name].&[3405235],[Hotel].[Hotel Name].&[3213239],[Hotel].[Hotel Name].&[3209308],[Hotel].[Hotel Name].&[304565],[Hotel].[Hotel Name].&[245196],[Hotel].[Hotel Name].&[3906593],[Hotel].[Hotel Name].&[3893317],[Hotel].[Hotel Name].&[576979],[Hotel].[Hotel Name].&[255326],[Hotel].[Hotel Name].&[263312],[Hotel].[Hotel Name].&[3247767],[Hotel].[Hotel Name].&[3942824],[Hotel].[Hotel Name].&[259221],[Hotel].[Hotel Name].&[3061037],[Hotel].[Hotel Name].&[519017],[Hotel].[Hotel Name].&[254367],[Hotel].[Hotel Name].&[512551],[Hotel].[Hotel Name].&[3357567],[Hotel].[Hotel Name].&[492585],[Hotel].[Hotel Name].&[254103],[Hotel].[Hotel Name].&[293281],[Hotel].[Hotel Name].&[243816],[Hotel].[Hotel Name].&[3888769],[Hotel].[Hotel Name].&[240800],[Hotel].[Hotel Name].&[259584],[Hotel].[Hotel Name].&[291998],[Hotel].[Hotel Name].&[376229],[Hotel].[Hotel Name].&[3302537],[Hotel].[Hotel Name].&[263410],[Hotel].[Hotel Name].&[255982],[Hotel].[Hotel Name].&[3231492]}', 
@GeosetTuples Varchar(4000) = '{[Hotel].[Market Id].&[878]}'

-- for compset tuples:
-- need to use hotelname as hotelkey does not agg correctly by starrating for hotel level.
-- but then for the chain & hotel levels, has to aggregate as hotelkey in order to have the data by starratings correctly.

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

SELECT @MDXQuery1 = 'SELECT * FROM OPENQUERY(EDWCUBES_LODGINGBOOKING,''
WITH

SET [StayDateRange] AS LastPeriods(-6,[Stay Date].[Month Start].&['+CONVERT(Varchar(10),@AsOfBookingMonth,120)+'T00:00:00])

--For all stays OTB of current year
MEMBER [Booking Date].[Calendar].[cyBookedDateRange] as Aggregate([Booking Date].[Calendar].[Date].&['+CONVERT(Varchar(10),DateAdd(m,-18,@AsOfBookingMonth),120)+'T00:00:00]:[Booking Date].[Calendar].[Date].&['+CONVERT(Varchar(10),@AsOfDate,120)+'T00:00:00])

--For all stays OTB of last year
MEMBER [Booking Date].[Calendar].[lyBookedDateRange] as Aggregate([Booking Date].[Calendar].[Date].&['+CONVERT(Varchar(10),DateAdd(m,-30,@AsOfBookingMonth),120)+'T00:00:00]:[Booking Date].[Calendar].[Date].&['+CONVERT(Varchar(10),DateAdd(d,-365,@AsOfDate),120)+'T00:00:00])

SET [Booked FS] AS ([cyBookedDateRange],[StayDateRange]) 

SET [StarRatings] AS '+@StarRatings+'

MEMBER [Hotel].[Star Rating].[Other StarRating] AS Aggregate( { EXISTING {[Hotel].[Star Rating].Members} - [StarRatings]})

SET [All StarRating] AS {[StarRatings],[Hotel].[Star Rating].[Other StarRating]}

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
[Booked FS] *
{
	[Transaction Type].[Transaction Type].[All].Net,
	[Transaction Type].[Transaction Type].[Transaction Type Group].&[Gross]
} *
[Package Indicator].[Package Indicator].[Package Indicator] *
[Package Indicator].[Package Indicator Type].[Package Indicator Type] *
[Stay Date].[Day of Week].[Day of Week] * '
+ CASE WHEN @ReportView = 2 THEN '
{([Hotel].[Hotel Key].[All],[ControlsetTotal],[Hotel].[Star Rating].[ALL]),([GeosetTotal],[Account Group].[Account Group Name].[All],[All StarRating]),([CompsetTotal],[Account Group].[Account Group Name].[All],[Hotel].[Star Rating].[ALL])} ' ELSE '
{([ControlsetTotal],[Account Group].[Account Group Name].[All],[StarRatings]),([GeosetTotal],[Account Group].[Account Group Name].[All],[All StarRating]),([CompsetTotal],[Account Group].[Account Group Name].[All],[Hotel].[Star Rating].[ALL])} ' END + '
)


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
--SELECT (@MDXQuery1+@MDXQuery2+@MDXQuery3)
EXEC (@MDXQuery1+@MDXQuery2+@MDXQuery3)
