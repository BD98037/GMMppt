USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetPPT_Data]    Script Date: 05/01/2015 11:13:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[GetPPT_Data]
@ProcessID INT = 0
AS

DECLARE
@PPTTypeID int,
@ControlValue Varchar(100),
@TimePeriodID int,
@BeginDate DateTime,
@EndDate DateTime,
@DataType Varchar(6),
@BookingType Varchar(100),
@ComparisonTypeID int,
@CompsetTypeID int,
@CompsetList varchar(500),
@GeoTypeID int,
@CompeteMarketList varchar(50),
@StarRatings varchar(50),
@Currency varchar(3) = 'USD',
@PPTID int, 
@YoYDOW int,
@RequestedBy varchar(100),
@MaxProcessedPPTID int,
@UnProcessedPPTID int,
@ReProcess int,
@Status int = 0

SELECT TOP 1 @PPTID =  PPTID  FROM PPTFilters WHERE Isnull(Processed,0) = 0

UPDATE dbo.PPTFilters 
SET Processed =2, --processing
	ProcessedBeginDt = GETDATE(),
	ProcessID = @ProcessID
	WHERE PPTID = @PPTID
	
/*
SELECT @MaxProcessedPPTID = MAX(PPTID) FROM PPTFilters WHERE Isnull(Processed,0) = 1

SELECT @UnProcessedPPTID = COUNT(*) FROM PPTFilters WHERE Isnull(Processed,0) = 0

IF(@UnProcessedPPTID = 0)
	SET @ReProcess = 3
ELSE 
	SET @ReProcess = 0
*/

SELECT TOP 1
--@PPTID = PPTID,
@RequestedBy = RequestedBy,
@PPTTypeID = PPTTypeID,
@ControlValue = ControlValue,
@TimePeriodID = TimePeriodID,
@BeginDate = BeginDate,
@EndDate = EndDate,
@DataType = DataType,
@BookingType = BookingType,
@ComparisonTypeID = ComparisonTypeID,
@CompsetTypeID = CompsetTypeID,
@CompsetList = CompsetList,
@GeoTypeID =GeoTypeID,
@CompeteMarketList =CompeteMarketList,
@StarRatings = StarRatings,
@Currency = @Currency
FROM dbo.PPTFilters WHERE Isnull(Processed,0) = 2 AND ProcessID = @ProcessID AND PPTID = @PPTID
ORDER BY RequestedDt ASC


CREATE TABLE #Dates(
	[period1] [int] NULL,
	[startdate1] [datetime] NULL,
	[startdate1MDX] [varchar](61) NULL,
	[enddate1] [datetime] NULL,
	[enddate1MDX] [varchar](61) NULL,
	[lystartdate1] [datetime] NULL,
	[lystartdate1MDX] [varchar](61) NULL,
	[lyenddate1] [datetime] NULL,
	[lyenddate1MDX] [varchar](61) NULL,
	[py_lystartdate1] [datetime] NULL,
	[py_lystartdate1MDX] [varchar](61) NULL,
	[py_lyenddate1] [datetime] NULL,
	[py_lyenddate1MDX] [varchar](61) NULL,
	[period2] [int] NULL,
	[startdate2] [datetime] NULL,
	[startdate2MDX] [varchar](61) NULL,
	[enddate2] [datetime] NULL,
	[enddate2MDX] [varchar](61) NULL,
	[lystartdate2] [datetime] NULL,
	[lystartdate2MDX] [varchar](61) NULL,
	[lyenddate2] [datetime] NULL,
	[lyenddate2MDX] [varchar](61) NULL,
	[py_lystartdate2] [datetime] NULL,
	[py_lystartdate2MDX] [varchar](61) NULL,
	[py_lyenddate2] [datetime] NULL,
	[py_lyenddate2MDX] [varchar](61) NULL,
	[defaultdate] [varchar](50) NULL,
	[lystartdate] [varchar](45) NULL,
	[lyenddate] [varchar](45) NULL
)

INSERT INTO #Dates
EXEC ProdReports.dbo.Get_MM_ValidDates 
@Period1 = @TimePeriodID,
@Current_dt = @EndDate,
@StartDate1 = @BeginDate,
@EndDate1 = @EndDate

SELECT @TimePeriodID = DATEDIFF(d,StartDate1,EndDate1) + 1,@BeginDate =startdate1,@EndDate = enddate1  FROM #Dates

IF(@EndDate = DateAdd(d,-1,DateAdd(m,1,dbo.GetMonthBegin(@EndDate)))
	AND @BeginDate = dbo.GetMonthBegin(@BeginDate))
SET @YoYDOW = 0
ELSE 
SET @YoYDOW = 1

IF(@PPTTypeID = 0)
SELECT @ControlValue = LODG_PROPERTY_KEY FROM [CHCXSQLPSG014].Mirror.DB2_DM.LODG_PROPERTY_DIM WHERE EXPE_LODG_PROPERTY_ID = @ControlValue

IF(@PPTTypeID =1)
	BEGIN
		EXEC [dbo].[GetMMW_AllData]
		@BookingType,
		@ControlValue,
		@CompeteMarketList,
		@DataType,
		@EndDate,
		@Currency,
		@TimePeriodID,
		@YoYDOW,
		@PPTID
		
		SET @Status =@@ERROR
	END
ELSE IF(@PPTTypeID IN (0,2,3))
		BEGIN
			EXEC [dbo].[GetHVR_AllData]
			@BookingType,
			@ControlValue,
			@DataType,
			@EndDate,
			@Currency,
			@PPTTypeID,
			@StarRatings,
			@ComparisonTypeID, 
			@CompsetTypeID,
			@GeoTypeID,
			@CompsetList, 
			@CompeteMarketList,
			@TimePeriodID,
			@YoYDOW,
			@PPTID
			
			SET @Status =@@ERROR
		END


UPDATE dbo.PPTFilters 
SET Processed = 1, -- complete
	ProcessedEndDt = GETDATE()
	WHERE RequestedBy = @RequestedBy AND PPTID = @PPTID

	
	
