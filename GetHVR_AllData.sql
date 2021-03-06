USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetHVR_AllData]    Script Date: 05/01/2015 11:01:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[GetHVR_AllData]
@BookingType Varchar(4000) ='3,1',
@ControlValue Varchar(4000) = 'Parent Group Eviivo',
@DataType Varchar(6) ='Stayed',
@AsOfDate Datetime ='09/25/2014',
@Currency Varchar(10) = 'USD',
@PPTTypeID Int = 2,  -- 0 = hotel, 2 = account group, 3 = parent chain
@StarRatings Varchar(4000) = '4,5',
@ComparisonTypeID Int = 2, -- 1 = compset, 2 = geo only, 3 = geo & compset 
@CompsetTypeID Int = 1, -- 1 = PPC , 2 = UDC,3 =enter own compset
@GeoTypeID Int = 1, -- 1 = market, 2 = submarket
@CompsetList Varchar(4000) = Null,
@CompeteMarketList Varchar(4000) = '95194',
@TimePeriodID Int = 7,
@YoYDOW int =0, -- 1 = DOW 0 = DOY
@HVRID Int =4

AS

DECLARE @AsOfBookingMonth DateTime,@AsOfFutureMonth DateTime, @ControlName Varchar(200),@GeoName Varchar(200),@MarketCnt Int,@POSuCountry Varchar(500),@POSuSR Varchar(10),@BookingTypeIncluded Varchar(500)

IF(ISNULL(@StarRatings,'') = '')
SET @StarRatings = '-1.0'

IF(@PPTTypeID = 0)
	BEGIN
		IF(@CompsetTypeID <>3)
			BEGIN	
				SELECT @CompsetList =
				(
				SELECT ',[Hotel].[Hotel Name].&['+CONVERT(Varchar(15),CMPRBL_LODG_PROPERTY_KEY)+']'
				FROM [chcxsqlpsg014].Mirror.DB2_LZ.LZ_PSG_CMP_SET_ACTIVE WHERE LODG_PROPERTY_KEY = @ControlValue AND PCC_FLAG = CASE @CompsetTypeID WHEN 2 THEN 0 ELSE @CompsetTypeID END
					FOR XML PATH (''))
				SELECT @CompsetList =  '{' + stuff(REPLACE(@CompsetList, '&amp;','&'),1,1,'') + '}'	
				
				IF EXISTS(SELECT TOP 1* FROM  HVR_CompsetList WHERE HVRID = @HVRID)
				 DELETE FROM HVR_CompsetList WHERE HVRID = @HVRID
				 
				INSERT INTO HVR_CompsetList
						(
						HVRID,
						ControlID,
						ControlKey,
						CMPRBL_ExpediaID,
						CMPRBL_HotelKey,
						CompsetType,
						SnapshotDate
						)
				SELECT @HVRID,CTRL_ID,LODG_PROPERTY_KEY,CMPRBL_Expe_ID,CMPRBL_LODG_PROPERTY_KEY,PCC_FLAG,SNAPSHOT_DATETM
					FROM [chcxsqlpsg014].Mirror.DB2_LZ.LZ_PSG_CMP_SET_ACTIVE 
						WHERE LODG_PROPERTY_KEY = @ControlValue AND PCC_FLAG = CASE @CompsetTypeID WHEN 2 THEN 0 ELSE @CompsetTypeID END
				 
			END
		ELSE IF(@CompsetTypeID=3)
				BEGIN
				
				IF NOT EXISTS(SELECT TOP 1* FROM  HVR_CompsetList WHERE HVRID = @HVRID)
						INSERT INTO HVR_CompsetList
						(
						HVRID,
						ControlID,
						ControlKey,
						CMPRBL_ExpediaID,
						CMPRBL_HotelKey--,
						--CompsetType,
						--SnapshotDate
						)
						SELECT @HVRID,@ControlValue CTRL_ID,null ControlKey,p.EXPE_LODG_PROPERTY_ID CMPRBL_Expe_ID,
									LODG_PROPERTY_KEY CMPRBL_LODG_PROPERTY_KEY
							FROM [chcxsqlpsg014].Mirror.DB2_DM.LODG_PROPERTY_DIM p
							JOIN (SELECT [STR] AS ExpediaID FROM dbo.charlist_to_table(@CompsetList ,';')) c
							ON  c.ExpediaID = p.EXPE_LODG_PROPERTY_ID
							
					SELECT @CompsetList =
						(
						SELECT ',[Hotel].[Hotel Name].&['+CONVERT(Varchar(15),LODG_PROPERTY_KEY)+']'
						FROM (SELECT [STR] AS ExpediaID FROM dbo.charlist_to_table(@CompsetList ,';')) c
						JOIN [chcxsqlpsg014].Mirror.DB2_DM.LODG_PROPERTY_DIM p
							ON  c.ExpediaID = p.EXPE_LODG_PROPERTY_ID
							FOR XML PATH (''))
						SELECT @CompsetList =  '{' + stuff(REPLACE(@CompsetList, '&amp;','&'),1,1,'') + '}'	
						
						
						
						UPDATE c
						SET c.ControlKey = p2.LODG_PROPERTY_KEY
						FROM HVR_CompsetList c
						JOIN [chcxsqlpsg014].Mirror.DB2_DM.LODG_PROPERTY_DIM p2
							ON c.ControlID = p2.EXPE_LODG_PROPERTY_ID AND p2.EXPE_LODG_PROPERTY_ID = @ControlValue AND c.HVRID = @HVRID
				END
					
		SELECT @CompeteMarketList= CASE @GeoTypeID WHEN 1 THEN '[Hotel].[Market Id].&['+Convert(Varchar(20),PROPERTY_MKT_ID)+']'
											 WHEN 2 THEN '[Hotel].[SubMarket Id].&['+Convert(Varchar(20),PROPERTY_SUB_MKT_ID)+']' ELSE '[Hotel].[Market Id].&[]' END,
			  @GeoName	=   CASE @GeoTypeID WHEN 1 THEN PROPERTY_MKT_NAME WHEN 2 THEN PROPERTY_SUB_MKT_NAME ELSE '' END,
			  @StarRatings = CASE WHEN ISNULL(EXPE_HALF_STAR_RTG,0) = 0 THEN '[Hotel].[Star Rating].&[]' ELSE '{[Hotel].[Star Rating].&['+Convert(Varchar(3),EXPE_HALF_STAR_RTG-.5)+'],[Hotel].[Star Rating].&['+Convert(Varchar(3),EXPE_HALF_STAR_RTG)+'],[Hotel].[Star Rating].&['+Convert(Varchar(3),EXPE_HALF_STAR_RTG+.5)+']}' END,
			  @ControlName =  LODG_PROPERTY_NAME,
			  @POSuCountry = LTRIM(RTRIM(PROPERTY_CNTRY_NAME)),
			  @POSuSR = LTRIM(RTRIM(PROPERTY_SUPER_REGN_NAME))
			FROM [chcxsqlpsg014].Mirror.DB2_DM.LODG_PROPERTY_DIM WHERE LODG_PROPERTY_KEY = @ControlValue

		SET @ControlValue = '[Hotel].[Hotel Name].&['+ISNULL(@ControlValue,'')+']'
		
		IF(ISNULL(@CompsetList,'') ='')
			SET @CompsetList ='[Hotel].[Hotel Name].&[]'
		
	END
ELSE IF(@PPTTypeID = 2)
	BEGIN		
	
		SELECT @CompsetList ='[Hotel].[Hotel Name].&[]'--,
		--@GeoName =@ControlValue
		
		SELECT @StarRatings =
		(
		SELECT ',[Hotel].[Star Rating].&['+StarRating+']'
		FROM (SELECT [STR] AS StarRating FROM dbo.charlist_to_table(@StarRatings ,DEFAULT)) b
			FOR XML PATH (''))
		SELECT @StarRatings =  '{' + stuff(REPLACE(@StarRatings, '&amp;','&'),1,1,'') + '}'	
		
		
		SELECT DISTINCT PROPERTY_MKT_ID,PROPERTY_MKT_NAME,PROPERTY_CNTRY_NAME POSuCountry,PROPERTY_SUPER_REGN_NAME POSuSR 
		INTO #Markets
		FROM [chcxsqlpsg014].Mirror.Expedient.AccountGroup ac
		JOIN [chcxsqlpsg014].Mirror.DB2_DM.LODG_PROPERTY_DIM p ON ac.ExpediaID = p.EXPE_LODG_PROPERTY_ID
		WHERE AccountGroupName = @ControlValue
				
		SET @CompeteMarketList = '[Hotel].[Market Id].&[]'		
		IF(@ComparisonTypeID>1)
			BEGIN
				SELECT @MarketCnt = COUNT(DISTINCT PROPERTY_MKT_ID) FROM #Markets
				IF(@MarketCnt =1)
					BEGIN
						SELECT @CompeteMarketList = '[Hotel].[Market Id].&['+Convert(Varchar(20),PROPERTY_MKT_ID)+']' FROM #Markets
						SELECT @GeoName = PROPERTY_MKT_NAME FROM #Markets
					END
			END

		SET @ControlName = @ControlValue
		SET @ControlValue = '[Account Group].[Account Group Name].&['+@ControlValue+']'
		
		IF((SELECT COUNT(DISTINCT POSuCountry) FROM #Markets) = 1)
		SELECT @POSuCountry = POSuCountry,@POSuSR = POSuSR FROM #Markets
		ELSE IF((SELECT COUNT(DISTINCT POSuSR) FROM #Markets) = 1)
		SELECT @POSuSR = POSuSR FROM #Markets
		
	END
ELSE IF(@PPTTypeID = 3)
	BEGIN
		SELECT @CompsetList ='[Hotel].[Hotel Name].&[]'
		SET @CompeteMarketList = '[Hotel].[Market Id].&['+@CompeteMarketList+']'
		SELECT @ControlName = ParentChainName FROM [chcxsqlpsg014].Mirror.GPCMaster.ParentChain WHERE ParentChainID = @ControlValue
		SET @ControlValue = '[Parent Chain].[Parent Chain Id].&['+@ControlValue+']'
		
		SELECT @StarRatings =
		(
		SELECT ',[Hotel].[Star Rating].&['+StarRating+']'
		FROM (SELECT [STR] AS StarRating FROM dbo.charlist_to_table(@StarRatings ,DEFAULT)) b
			FOR XML PATH (''))
		SELECT @StarRatings =  '{' + stuff(REPLACE(@StarRatings, '&amp;','&'),1,1,'') + '}'	
	END
	
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

SELECT DISTINCT [POS_CNTRY_NAME] POSaCountryName,[LPS_POS_SUPER_REGN_NAME] POSaSR
INTO #POSa
FROM [chcxsqlpsg014].[Mirror].[DB2_DM].[POS_DIM]

IF(@PPTTypeID = 2 AND (ISNULL(@CompeteMarketList,'') <> '[Hotel].[Market Id].&[]' OR ISNULL(@CompsetList,'') <>'[Hotel].[Hotel Name].&[]'))
	BEGIN
		Print('GetHVR_AccountGroup')
		EXEC [dbo].[GetHVR_AccountGroup]
		@BookingType,
		@ControlValue,
		@DataType,
		@AsOfDate,
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
		@HVRID
		
	UPDATE hvr 
	SET DataType = @DataType,
		BookingTypeIncluded = Substring(@BookingTypeIncluded,2,LEN(@BookingTypeIncluded)-1),
		--HVRID = @HVRID,
		AsofDate = @AsOfDate,
		POSaSR = pos.POSaSR,
		ComparisonType = CASE ComparisonTypeDesc WHEN @ControlName THEN 'ControlSetTotal' ELSE ComparisonType END,
		ComparisonTypeDesc = CASE ComparisonType WHEN 'GeoSetTotal' THEN @GeoName ELSE ComparisonTypeDesc END,
		InternationalFlag = CASE WHEN ISNULL(@POSuSR,'') ='' AND SprocName ='GetHVR_RecentTrends_DRR_POSa' THEN 'Delete' ELSE  
									CASE WHEN ISNULL(hvr .POSaCountryName,'') <> '' THEN 
										CASE WHEN ISNULL(hvr .POSaCountryName,'') = @POSuCountry THEN 'Domestic'
											ELSE CASE WHEN RIGHT(pos.POSaSR,4) = @POSuSR THEN 'Domestic'
													ELSE 'International' END END END END	
	FROM dbo.HVR_AllData hvr 
	LEFT JOIN #POSa pos
	ON hvr.POSaCountryName = pos.POSaCountryName
	WHERE ISNULL(HVRID,'') =@HVRID
	
	END
ELSE
	BEGIN
		Print('GetHVR_OtherThanAccountGroup')
		EXEC [dbo].[GetHVR_OtherThanAccountGroup]
		@BookingType,
		@ControlValue,
		@DataType,
		@AsOfDate,
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
		@HVRID
		
		--SELECT  @POSuCountry,ISNULL(@POSuSR,'') POSuSR
		
		UPDATE hvr 
		SET DataType = @DataType,
			BookingTypeIncluded = Substring(@BookingTypeIncluded,2,LEN(@BookingTypeIncluded)-1),
			--HVRID = @HVRID,
			AsofDate = @AsOfDate,
			POSaSR = pos.POSaSR,
			ComparisonTypeDesc = CASE WHEN ComparisonType = 'GeoSetTotal' THEN @GeoName 
													 WHEN ComparisonType = 'ControlSetTotal' OR ComparisonType = @ControlName  THEN @ControlName ELSE ComparisonTypeDesc END,
			--POSale Logic #1
			InternationalFlag = CASE WHEN ISNULL(@POSuSR,'') ='' AND SprocName ='GetHVR_RecentTrends_DRR_POSa' THEN 'Delete' ELSE  
										CASE WHEN ISNULL(hvr .POSaCountryName,'') <> '' THEN 
											CASE WHEN ISNULL(hvr .POSaCountryName,'') = @POSuCountry THEN 'Domestic'
												--ELSE CASE WHEN RIGHT(pos.POSaSR,4) = @POSuSR THEN 'Domestic'
														ELSE 'International' END END END --END	
		FROM dbo.HVR_AllData hvr 
		LEFT JOIN #POSa pos
		ON hvr.POSaCountryName = pos.POSaCountryName
		WHERE ISNULL(HVRID,'') =@HVRID
		
	END
		--check for logic #2 to make sure if only internaltional POSales
		IF((SELECT COUNT(*) FROM dbo.HVR_AllData WHERE HVRID = @HVRID AND InternationalFlag ='Domestic') < 1)
		UPDATE hvr 
		SET
			InternationalFlag = 'Domestic'											
		FROM dbo.HVR_AllData hvr 
		WHERE ISNULL(HVRID,'') = @HVRID AND RIGHT(POSaSR,4) = RIGHT(@POSuSR,4)

		UPDATE dbo.HVR_AllData
		SET ComparisonType = CASE ComparisonTypeDesc WHEN @ControlName THEN 'ControlSetTotal' ELSE ComparisonType END
		WHERE ISNULL(HVRID,'') = @HVRID
	
DECLARE @TimePeriodName Varchar(50),@NumOfDays Int
SET @NumOfDays = @TimePeriodID
SELECT @TimePeriodName = ShortName,@TimePeriodID = TimePeriodID
	FROM dbo.PPTFilters f
	JOIN dbo.TimePeriod t
	ON f.TimePeriodID = t.ID 
	WHERE f.PPTID = @HVRID
	
IF(ISNULL(@TimePeriodName,'') ='')
	BEGIN
		IF(@TimePeriodID IN (0,-7))
			SELECT @TimePeriodName = Convert(Varchar(10),DATEADD(d,-@NumOfDays+1,@AsOfDate),120) + ' to ' +   Convert(Varchar(10),@AsOfDate,120)
		ELSE IF(@TimePeriodID = 30)
				SELECT @TimePeriodName = MONTH(@AsOfDate)
			ELSE IF(@TimePeriodID = 91)
				SELECT @TimePeriodName = CASE WHEN MONTH(@AsOfDate) BETWEEN 1 and 3 THEN 'Q1'
												WHEN MONTH(@AsOfDate) BETWEEN 4 and 6 THEN 'Q2'
													WHEN MONTH(@AsOfDate) BETWEEN 7 and 9 THEN 'Q3'
														WHEN MONTH(@AsOfDate) BETWEEN 10 and 12 THEN 'Q4' END
				
	END

UPDATE dbo.HVR_AllData
SET TimePeriod = @TimePeriodName
WHERE HVRID = @HVRID AND ISNULL(TimePeriod,'') <> ''


