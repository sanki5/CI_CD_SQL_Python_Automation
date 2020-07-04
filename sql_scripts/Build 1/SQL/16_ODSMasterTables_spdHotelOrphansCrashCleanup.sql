--run at DBP64CLU23SQLx1
USE [ODSMasterTables]
GO

/****** Object:  StoredProcedure [dbo].[spdHotelOrphansCrashCleanup]    Script Date: 2/6/2020 9:08:05 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[spdHotelOrphansCrashCleanup]
GO

/****** Object:  StoredProcedure [dbo].[spdHotelOrphansCrashCleanup]    Script Date: 2/6/2020 9:08:05 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[spdHotelOrphansCrashCleanup]  
	@DataMart NVARCHAR(50),
	@ExecutionID [UNIQUEIDENTIFIER],
	@Version VARCHAR(20)	
AS
/*  

Stored Procedure:	dbo.spdHotelOrphansCrashCleanup 
Purpose: Performed crash cleanup of failed records. Deleted failed orphaned hotel records from ODSLkupHotelBCDMaster, ODSLkupHotel and dimHotelHMF (Conforming Dimensions, PreTrip, and PostTrip) 
Caller:  SSIS Package - HotelOrphansCreatePurgeTable.dtsx (HotelOrphanedRecordsPurge)

Version		Updated By			Updated Date			Description
--------	-----------			-------------			------------------------
V1			Ankur Adarsh		12-26-2017				Created as per DSD-1110
V2  		Ankur Adarsh		05-10-2018				Added the logic to avoid the cancelled Hotel and 
														ParentHotelKey conflict record to get deleted from 
														hotel tables as per BCDETL-xxx. 
V3			SH					02-07-2020				Modified the sproc to add column LanyonID (DN-1651)
*/
    
  
BEGIN  

SET NOCOUNT ON;  
SET DEADLOCK_PRIORITY LOW;  
DECLARE  @ERROR_MESSAGE NVARCHAR(4000)
		,@ERROR_NUMBER INT
		,@ERROR_LINE INT
		,@ERROR_STATE INT 
		,@XSTATE int


DECLARE @RowCount INT ,
		@RecsDeletedConfDim INT,
		@RecsDeletedPreTrip INT,
		@RecsDeletedPostTrip INT,
		@RecsDeletedODSLkupHotel INT,
		@RecsDeletedODSLkupHotelBCDMaster INT,

		@ExecIDLoop		VARCHAR(50),	
		@TaskNameLoop	VARCHAR(50),

		@ExecIDConfDim		VARCHAR(50),	
		@TaskNameConfDim	VARCHAR(50),
		@ExecIDPreTrip		VARCHAR(50),	
		@TaskNamePreTrip	VARCHAR(50),
		@ExecIDPostTrip		VARCHAR(50),	
		@TaskNamePostTrip	VARCHAR(50),
		
		@ExecIDODSLkupHotel		VARCHAR(50),	
		@TaskNameODSLkupHotel	VARCHAR(50),
		
		@ExecIDODSLkupHotelBCDMaster	VARCHAR(50),	
		@TaskNameODSLkupHotelBCDMaster	VARCHAR(50),
		 
		@EndDate					DATETIME ,

		@TranCount int,
		
		@MinRowID INT,
		@MaxRowID INT;

SET @TaskNameLoop  = 'CrashCleanup HotelOrphan Delete Loop'
SET @TaskNameConfDim  = 'CrashCleanup Delete Conforming Dimensions dimHotelHMF'
SET @TaskNamePreTrip  = 'CrashCleanup Delete PreTrip dimHotelHMF'
SET @TaskNamePostTrip = 'CrashCleanup Delete PostTrip dimHotelHMF'
SET @TaskNameODSLkupHotel = 'CrashCleanup Delete ODSLkupHotel'
SET @TaskNameODSLkupHotelBCDMaster = 'CrashCleanup Delete ODSLkupHotelBCDMaster'

SET @RecsDeletedConfDim = 0 
SET @RecsDeletedPreTrip = 0 
SET @RecsDeletedPostTrip = 0 
SET	@RecsDeletedODSLkupHotel = 0
SET	@RecsDeletedODSLkupHotelBCDMaster = 0

DELETE oh
FROM ODSMasterTables_Stage.dbo.HotelOrphanPurge oh WITH (ROWLOCK)
WHERE 
(
(DeleteStarted = 'Y' AND DeleteCompleted = 'Y')
OR (DeleteStarted IS NULL AND DeleteCompleted IS NULL)
)

SELECT @MinRowID = MIN(RowID) , @MaxRowID = MAX(RowID) FROM ODSMasterTables_Stage.dbo.HotelOrphanPurge (NOLOCK)

IF @MaxRowID IS NULL
RETURN;

-- Logging: Loop initial
	EXEC DMLogs.dbo.spiuPackageExecution 
				@DataMart = @DataMart,
				@PackageType = @TaskNameLoop,
				@ParentExecutionID = @ExecutionID,
				@Version=@Version,
				@ExecutionID = @ExecIDLoop OUTPUT

--SET @TranCount = @@trancount;
BEGIN TRY
--IF @TranCount = 0 
--	BEGIN TRANSACTION 
--ELSE 
--	SAVE TRANSACTION DeleteHotelOrphans_Tran

-- Logging: ODSLkupHotelBCDMaster initial	
	EXEC DMLogs.dbo.spiuPackageExecution 
				@DataMart = @DataMart,
				@PackageType = @TaskNameODSLkupHotelBCDMaster,
				@ParentExecutionID = @ExecutionID,
				@Version=@Version,
				@ExecutionID = @ExecIDODSLkupHotelBCDMaster OUTPUT

-- ODSLkupHotelBCDMaster Begin
TRUNCATE TABLE [ODSMasterTables_Stage].[dbo].[STAGE_ODSLkupHotelBCDMasterOrphanArchive] 	
INSERT INTO [ODSMasterTables_Stage].[dbo].[STAGE_ODSLkupHotelBCDMasterOrphanArchive]
           ([HotelKey]
           ,[BCDPropertyID]
           ,[DSSourceCode]
           ,[DSCreateDate]
           ,[DSCreateUser]
           ,[DSLastChangeDate]
           ,[DSLastChangeUser]
           ,[DSChangeReason])
SELECT  A.[HotelKey]
      ,A.[BCDPropertyID]
      ,A.[DSSourceCode]
      ,A.[DSCreateDate]
      ,A.[DSCreateUser]
      ,A.[DSLastChangeDate]
      ,A.[DSLastChangeUser]
      ,A.[DSChangeReason]
	FROM ODSMasterTables.dbo.ODSLkupHotelBCDMaster A  (NOLOCK)
	JOIN ODSMasterTables_Stage.dbo.HotelOrphanPurge P (NOLOCK)
	ON A.HotelKey = P.HotelKeyODS
	WHERE P.RowID BETWEEN @MinRowID AND @MaxRowID 

MERGE INTO [DSCommonLogArchive].[dbo].[ODSLkupHotelBCDMasterOrphanArchive] AS Target
USING [ODSMasterTables_Stage].[dbo].[STAGE_ODSLkupHotelBCDMasterOrphanArchive] (NOLOCK)
    AS Source
ON Target.HotelKey = Source.HotelKey
WHEN MATCHED THEN
    UPDATE SET Target.[BCDPropertyID] = Source.[BCDPropertyID] ,
               Target.[DSSourceCode] = Source.[DSSourceCode] ,
               Target.[DSCreateDate] = Source.[DSCreateDate] ,
               Target.[DSCreateUser] = Source.[DSCreateUser] ,
               Target.[DSLastChangeDate] = Source.[DSLastChangeDate] ,
               Target.[DSLastChangeUser] = Source.[DSLastChangeUser] ,
               Target.[DSChangeReason] = Source.[DSChangeReason]
WHEN NOT MATCHED THEN
    INSERT ( [HotelKey] ,
             [BCDPropertyID] ,
             [DSSourceCode] ,
             [DSCreateDate] ,
             [DSCreateUser] ,
             [DSLastChangeDate] ,
             [DSLastChangeUser] ,
             [DSChangeReason]
           )
    VALUES ( Source.[HotelKey] ,
             Source.[BCDPropertyID] ,
             Source.[DSSourceCode] ,
             Source.[DSCreateDate] ,
             Source.[DSCreateUser] ,
             Source.[DSLastChangeDate] ,
             Source.[DSLastChangeUser] ,
             Source.[DSChangeReason]
           );

DELETE A 
FROM ODSMasterTables.dbo.ODSLkupHotelBCDMaster A  WITH (ROWLOCK)
JOIN  [ODSMasterTables_Stage].[dbo].[STAGE_ODSLkupHotelBCDMasterOrphanArchive] B  (NOLOCK)
ON A.HotelKey = B.HotelKey 

SELECT @RecsDeletedODSLkupHotelBCDMaster = @@RowCount
	
TRUNCATE TABLE [ODSMasterTables_Stage].[dbo].[STAGE_ODSLkupHotelBCDMasterOrphanArchive] 

SET @EndDate = GETDATE()

-- Logging: ODSLkupHotelBCDMaster final						
	EXEC DMLogs.dbo.spiuPackageExecution
			@ExecutionID = @ExecIDODSLkupHotelBCDMaster,	 
			@RowCount = @RecsDeletedODSLkupHotelBCDMaster,
			@EndDate = @EndDate 

-- ODSLkupHotelBCDMaster End

-- ODSLkupHotel Begin

-- Logging: ODSLkupHotel initial	
	EXEC DMLogs.dbo.spiuPackageExecution 
				@DataMart = @DataMart,
				@PackageType = @TaskNameODSLkupHotel,
				@ParentExecutionID = @ExecutionID,
				@Version=@Version,
				@ExecutionID = @ExecIDODSLkupHotel OUTPUT

TRUNCATE TABLE [ODSMasterTables_Stage].[dbo].[STAGE_ODSLkupHotelOrphanArchive]
INSERT INTO [ODSMasterTables_Stage].[dbo].[STAGE_ODSLkupHotelOrphanArchive]
           ([HotelKey]
           ,[System]
           ,[HotelID]
           ,[GDSHotelNumber]
           ,[HotelChainCode]
           ,[HotelChainName]
           ,[HotelName]
           ,[HotelAddr1]
           ,[HotelAddr2]
           ,[HotelAddr3]
           ,[HotelCityCode]
           ,[HotelCityName]
           ,[HotelState]
           ,[HotelCountryCode]
           ,[HotelCountry]
           ,[HotelPostalCode]
           ,[HotelPhoneNumber]
           ,[GeoKey]
           ,[Latitude]
           ,[Longitude]
           ,[CreateDate]
           ,[UpdateDate]
           ,[isMasterData]
           ,[colCheckSum]
           ,[MasterHotelID]
           ,[HotelPhoneNumberReversed]
           ,[HotelPhoneNumberRight10]
--V2 Start
		   ,[GDSCodeFormatted]
		   ,[CRSCode]
--V2 End		   
		   )
	SELECT  A.[HotelKey]
      ,A.[System]
      ,A.[HotelID]
      ,A.[GDSHotelNumber]
      ,A.[HotelChainCode]
      ,A.[HotelChainName]
      ,A.[HotelName]
      ,A.[HotelAddr1]
      ,A.[HotelAddr2]
      ,A.[HotelAddr3]
      ,A.[HotelCityCode]
      ,A.[HotelCityName]
      ,A.[HotelState]
      ,A.[HotelCountryCode]
      ,A.[HotelCountry]
      ,A.[HotelPostalCode]
      ,A.[HotelPhoneNumber]
      ,A.[GeoKey]
      ,A.[Latitude]
      ,A.[Longitude]
      ,A.[CreateDate]
      ,A.[UpdateDate]
      ,A.[isMasterData]
      ,A.[colCheckSum]
      ,A.[MasterHotelID]
      ,A.[HotelPhoneNumberReversed]
      ,A.[HotelPhoneNumberRight10]
--V2 Start
	  ,A.[GDSCodeFormatted]
	  ,A.[CRSCode]
--V2 End
	FROM ODSMasterTables.dbo.ODSLkupHotel A  (NOLOCK)
	JOIN ODSMasterTables_Stage.dbo.HotelOrphanPurge P (NOLOCK)
	ON A.HotelID = P.HotelID
	WHERE P.RowID BETWEEN @MinRowID AND @MaxRowID

MERGE INTO [DSCommonLogArchive].[dbo].[ODSLkupHotelOrphanArchive] AS Target
USING [ODSMasterTables_Stage].[dbo].[STAGE_ODSLkupHotelOrphanArchive] (NOLOCK) AS Source
ON Target.HotelID = Source.HotelID
WHEN MATCHED THEN 
UPDATE SET Target.[HotelKey] = Source.[HotelKey],
			Target.[System] = Source.[System],
			--Target.[HotelID] = Source.[HotelID],
			Target.[GDSHotelNumber] = Source.[GDSHotelNumber],
			Target.[HotelChainCode] = Source.[HotelChainCode],
			Target.[HotelChainName] = Source.[HotelChainName],
			Target.[HotelName] = Source.[HotelName],
			Target.[HotelAddr1] = Source.[HotelAddr1],
			Target.[HotelAddr2] = Source.[HotelAddr2],
			Target.[HotelAddr3] = Source.[HotelAddr3],
			Target.[HotelCityCode] = Source.[HotelCityCode],
			Target.[HotelCityName] = Source.[HotelCityName],
			Target.[HotelState] = Source.[HotelState],
			Target.[HotelCountryCode] = Source.[HotelCountryCode],
			Target.[HotelCountry] = Source.[HotelCountry],
			Target.[HotelPostalCode] = Source.[HotelPostalCode],
			Target.[HotelPhoneNumber] = Source.[HotelPhoneNumber],
			Target.[GeoKey] = Source.[GeoKey],
			Target.[Latitude] = Source.[Latitude],
			Target.[Longitude] = Source.[Longitude],
			Target.[CreateDate] = Source.[CreateDate],
			Target.[UpdateDate] = Source.[UpdateDate],
			Target.[isMasterData] = Source.[isMasterData],
			Target.[colCheckSum] = Source.[colCheckSum],
			Target.[MasterHotelID] = Source.[MasterHotelID],
			Target.[HotelPhoneNumberReversed] = Source.[HotelPhoneNumberReversed],
			Target.[HotelPhoneNumberRight10] = Source.[HotelPhoneNumberRight10],
--V2 Start
		    Target.[GDSCodeFormatted] = Source.[GDSCodeFormatted],
		    Target.[CRSCode] = Source.[CRSCode]
--V2 End
WHEN NOT MATCHED THEN 
INSERT ( [HotelKey]
		,[System]
		,[HotelID]
		,[GDSHotelNumber]
		,[HotelChainCode]
		,[HotelChainName]
		,[HotelName]
		,[HotelAddr1]
		,[HotelAddr2]
		,[HotelAddr3]
		,[HotelCityCode]
		,[HotelCityName]
		,[HotelState]
		,[HotelCountryCode]
		,[HotelCountry]
		,[HotelPostalCode]
		,[HotelPhoneNumber]
		,[GeoKey]
		,[Latitude]
		,[Longitude]
		,[CreateDate]
		,[UpdateDate]
		,[isMasterData]
		,[colCheckSum]
		,[MasterHotelID]
		,[HotelPhoneNumberReversed]
		,[HotelPhoneNumberRight10] 
--V2 Start
		,[GDSCodeFormatted]
		,[CRSCode]
--V2 End
		)
VALUES (
	 Source.[HotelKey]
	,Source.[System]
	,Source.[HotelID]
	,Source.[GDSHotelNumber]
	,Source.[HotelChainCode]
	,Source.[HotelChainName]
	,Source.[HotelName]
	,Source.[HotelAddr1]
	,Source.[HotelAddr2]
	,Source.[HotelAddr3]
	,Source.[HotelCityCode]
	,Source.[HotelCityName]
	,Source.[HotelState]
	,Source.[HotelCountryCode]
	,Source.[HotelCountry]
	,Source.[HotelPostalCode]
	,Source.[HotelPhoneNumber]
	,Source.[GeoKey]
	,Source.[Latitude]
	,Source.[Longitude]
	,Source.[CreateDate]
	,Source.[UpdateDate]
	,Source.[isMasterData]
	,Source.[colCheckSum]
	,Source.[MasterHotelID]
	,Source.[HotelPhoneNumberReversed]
	,Source.[HotelPhoneNumberRight10]
--V2 Start
	,Source.[GDSCodeFormatted]
	,Source.[CRSCode]
--V2 End
) ;

DELETE A 
FROM ODSMasterTables.dbo.ODSLkupHotel A  WITH (ROWLOCK)
JOIN  [ODSMasterTables_Stage].[dbo].STAGE_ODSLkupHotelOrphanArchive B  (NOLOCK)
ON A.HotelID = B.HotelID  

SELECT @RecsDeletedODSLkupHotel = @@RowCount


TRUNCATE TABLE [ODSMasterTables_Stage].[dbo].[STAGE_ODSLkupHotelOrphanArchive]

SET @EndDate = GETDATE()
-- Logging: ODSLkupHotel final							
	EXEC DMLogs.dbo.spiuPackageExecution
			@ExecutionID = @ExecIDODSLkupHotel,	 
			@RowCount = @RecsDeletedODSLkupHotel,
			@EndDate = @EndDate 
-- ODSLkupHotel End

-- ConformingDimensions Begin
-- Logging: ConformingDimensions initial	
	EXEC DMLogs.dbo.spiuPackageExecution 
				@DataMart = @DataMart,
				@PackageType = @TaskNameConfDim,
				@ParentExecutionID = @ExecutionID,
				@Version=@Version,
				@ExecutionID = @ExecIDConfDim OUTPUT

IF OBJECT_ID('tempdb.dbo.#HotelOrphanPurge') IS NOT NULL
DROP TABLE dbo.#HotelOrphanPurge;
SELECT CONVERT(varchar(20), P.HotelID) AS HotelID
INTO dbo.#HotelOrphanPurge
FROM  ODSMasterTables_Stage.dbo.HotelOrphanPurge P (NOLOCK)
WHERE P.RowID BETWEEN @MinRowID AND @MaxRowID;

TRUNCATE TABLE [ConformingDimensions].[dbo].[STAGE_dimHotelHMFOrphanArchive]
INSERT INTO [ConformingDimensions].[dbo].[STAGE_dimHotelHMFOrphanArchive]
           ([HotelKey]
           ,[HotelChainKey]
           ,[GDSPropertyNumber]
           ,[GeoKey]
           ,[PropertyName]
           ,[Address1]
           ,[Address2]
           ,[Address3]
           ,[CityCode]
           ,[CityName]
           ,[State]
           ,[PostalCode]
           ,[CountryKey]
           ,[Phone]
           ,[HotelID]
           ,[ChkSum]
           ,[BCDPropertyName]
           ,[StateProvinceName]
           ,[PropertyLatitude]
           ,[PropertyLongitude]
           ,[GeoResolutionCode]
           ,[GeoResolution]
           ,[BCDMultAptCityCode]
           ,[BCDMultAptCityName]
           ,[MutiAptCityCode]
           ,[AirportLatitude]
           ,[AirportLongitude]
           ,[DstMiles]
           ,[DstKm]
           ,[PropApTyp]
           ,[PhoneCountryCode]
           ,[PhoneCityCode]
           ,[PhoneExchange]
           ,[Fax]
           ,[FaxCountryCode]
           ,[FaxCityCode]
           ,[FaxExchange]
           ,[AmadeusID]
           ,[AmadeusBrandCode]
           ,[WorldSpanID]
           ,[WorldSpanBrandCode]
           ,[SabreID]
           ,[SabreBrandCode]
           ,[ApolloID]
           ,[ApolloBrandCode]
           ,[MarketTier]
           ,[ServiceLevel]
           ,[BCDPropertyID]
           ,[ParentHotelKey]
           ,[StartDate]
           ,[EndDate]
           ,[CurrentRecord]
           ,[InferredMember]
           ,[DSSourceCode]
           ,[DSCreateDate]
           ,[DSCreateUser]
           ,[DSLastChangeDate]
           ,[DSLastChangeUser]
           ,[DSChangeReason]
--V3 Start
		   ,[LanyonID] 
--V3 End		   
		   )
	SELECT A.[HotelKey]
      ,A.[HotelChainKey]
      ,A.[GDSPropertyNumber]
      ,A.[GeoKey]
      ,A.[PropertyName]
      ,A.[Address1]
      ,A.[Address2]
      ,A.[Address3]
      ,A.[CityCode]
      ,A.[CityName]
      ,A.[State]
      ,A.[PostalCode]
      ,A.[CountryKey]
      ,A.[Phone]
      ,A.[HotelID]
      ,A.[ChkSum]
      ,A.[BCDPropertyName]
      ,A.[StateProvinceName]
      ,A.[PropertyLatitude]
      ,A.[PropertyLongitude]
      ,A.[GeoResolutionCode]
      ,A.[GeoResolution]
      ,A.[BCDMultAptCityCode]
      ,A.[BCDMultAptCityName]
      ,A.[MutiAptCityCode]
      ,A.[AirportLatitude]
      ,A.[AirportLongitude]
      ,A.[DstMiles]
      ,A.[DstKm]
      ,A.[PropApTyp]
      ,A.[PhoneCountryCode]
      ,A.[PhoneCityCode]
      ,A.[PhoneExchange]
      ,A.[Fax]
      ,A.[FaxCountryCode]
      ,A.[FaxCityCode]
      ,A.[FaxExchange]
      ,A.[AmadeusID]
      ,A.[AmadeusBrandCode]
      ,A.[WorldSpanID]
      ,A.[WorldSpanBrandCode]
      ,A.[SabreID]
      ,A.[SabreBrandCode]
      ,A.[ApolloID]
      ,A.[ApolloBrandCode]
      ,A.[MarketTier]
      ,A.[ServiceLevel]
      ,A.[BCDPropertyID]
      ,A.[ParentHotelKey]
      ,A.[StartDate]
      ,A.[EndDate]
      ,A.[CurrentRecord]
      ,A.[InferredMember]
      ,A.[DSSourceCode]
      ,A.[DSCreateDate]
      ,A.[DSCreateUser]
      ,A.[DSLastChangeDate]
      ,A.[DSLastChangeUser]
      ,A.[DSChangeReason]
--V3 Start
	  ,A.[LanyonID] 
--V3 End
	FROM ConformingDimensions.dbo.dimHotelHMF A  (NOLOCK)
	--JOIN ODSMasterTables_Stage.dbo.HotelOrphanPurge P (NOLOCK)
	--ON A.HotelID = P.HotelID
	--WHERE P.RowID BETWEEN @MinRowID AND @MaxRowID
	JOIN dbo.#HotelOrphanPurge P
	ON A.HotelID = P.HotelID

MERGE INTO [DSCommonLogArchive].[dbo].[dimHotelHMFOrphanArchiveConfDim] AS Target
USING [ConformingDimensions].[dbo].[STAGE_dimHotelHMFOrphanArchive] (NOLOCK)
    AS Source
ON Target.HotelID = Source.HotelID
WHEN MATCHED THEN
UPDATE SET 
	Target.[HotelKey]			= Source.[HotelKey],
	Target.[HotelChainKey]		= Source.[HotelChainKey],
	Target.[GDSPropertyNumber]	= Source.[GDSPropertyNumber],
	Target.[GeoKey]				= Source.[GeoKey],
	Target.[PropertyName]		= Source.[PropertyName],
	Target.[Address1]			= Source.[Address1],
	Target.[Address2]			= Source.[Address2],
	Target.[Address3]			= Source.[Address3],
	Target.[CityCode]			= Source.[CityCode],
	Target.[CityName]			= Source.[CityName],
	Target.[State]				= Source.[State],
	Target.[PostalCode]			= Source.[PostalCode],
	Target.[CountryKey]			= Source.[CountryKey],
	Target.[Phone]				= Source.[Phone],
	--Target.[HotelID]			= Source.[HotelID],
	Target.[ChkSum]				= Source.[ChkSum],
	Target.[BCDPropertyName]	= Source.[BCDPropertyName],
	Target.[StateProvinceName]	= Source.[StateProvinceName],
	Target.[PropertyLatitude]	= Source.[PropertyLatitude],
	Target.[PropertyLongitude]	= Source.[PropertyLongitude],
	Target.[GeoResolutionCode]	= Source.[GeoResolutionCode],
	Target.[GeoResolution]		= Source.[GeoResolution],
	Target.[BCDMultAptCityCode] = Source.[BCDMultAptCityCode],
	Target.[BCDMultAptCityName] = Source.[BCDMultAptCityName],
	Target.[MutiAptCityCode]	= Source.[MutiAptCityCode],
	Target.[AirportLatitude]	= Source.[AirportLatitude],
	Target.[AirportLongitude]	= Source.[AirportLongitude],
	Target.[DstMiles]			= Source.[DstMiles],
	Target.[DstKm]				= Source.[DstKm],
	Target.[PropApTyp]			= Source.[PropApTyp],
	Target.[PhoneCountryCode]	= Source.[PhoneCountryCode],
	Target.[PhoneCityCode]		= Source.[PhoneCityCode],
	Target.[PhoneExchange]		= Source.[PhoneExchange],
	Target.[Fax]				= Source.[Fax],
	Target.[FaxCountryCode]		= Source.[FaxCountryCode],
	Target.[FaxCityCode]		= Source.[FaxCityCode],
	Target.[FaxExchange]		= Source.[FaxExchange],
	Target.[AmadeusID]			= Source.[AmadeusID],
	Target.[AmadeusBrandCode]	= Source.[AmadeusBrandCode],
	Target.[WorldSpanID]		= Source.[WorldSpanID],
	Target.[WorldSpanBrandCode] = Source.[WorldSpanBrandCode],
	Target.[SabreID]			= Source.[SabreID],
	Target.[SabreBrandCode]		= Source.[SabreBrandCode],
	Target.[ApolloID]			= Source.[ApolloID],
	Target.[ApolloBrandCode]	= Source.[ApolloBrandCode],
	Target.[MarketTier]			= Source.[MarketTier],
	Target.[ServiceLevel]		= Source.[ServiceLevel],
	Target.[BCDPropertyID]		= Source.[BCDPropertyID],
	Target.[ParentHotelKey]		= Source.[ParentHotelKey],
	Target.[StartDate]			= Source.[StartDate],
	Target.[EndDate]			= Source.[EndDate],
	Target.[CurrentRecord]		= Source.[CurrentRecord],
	Target.[InferredMember]		= Source.[InferredMember],
	Target.[DSSourceCode]		= Source.[DSSourceCode],
	Target.[DSCreateDate]		= Source.[DSCreateDate],
	Target.[DSCreateUser]		= Source.[DSCreateUser],
	Target.[DSLastChangeDate]	= Source.[DSLastChangeDate],
	Target.[DSLastChangeUser]	= Source.[DSLastChangeUser],
	Target.[DSChangeReason]		= Source.[DSChangeReason],
--V3 Start
	Target.[LanyonID]			= Source.[LanyonID]
--V3 End

WHEN NOT MATCHED THEN
    INSERT ([HotelKey] , 
			[HotelChainKey] , 
			[GDSPropertyNumber] , 
			[GeoKey] , 
			[PropertyName] , 
			[Address1] , 
			[Address2] , 
			[Address3] , 
			[CityCode] , 
			[CityName] , 
			[State] , 
			[PostalCode] , 
			[CountryKey] , 
			[Phone] , 
			[HotelID] , 
			[ChkSum] , 
			[BCDPropertyName] , 
			[StateProvinceName] , 
			[PropertyLatitude] , 
			[PropertyLongitude] , 
			[GeoResolutionCode] , 
			[GeoResolution] , 
			[BCDMultAptCityCode] , 
			[BCDMultAptCityName] , 
			[MutiAptCityCode] , 
			[AirportLatitude] , 
			[AirportLongitude] , 
			[DstMiles] , 
			[DstKm] , 
			[PropApTyp] , 
			[PhoneCountryCode] , 
			[PhoneCityCode] , 
			[PhoneExchange] , 
			[Fax] , 
			[FaxCountryCode] , 
			[FaxCityCode] , 
			[FaxExchange] , 
			[AmadeusID] , 
			[AmadeusBrandCode] , 
			[WorldSpanID] , 
			[WorldSpanBrandCode] , 
			[SabreID] , 
			[SabreBrandCode] , 
			[ApolloID] , 
			[ApolloBrandCode] , 
			[MarketTier] , 
			[ServiceLevel] , 
			[BCDPropertyID] , 
			[ParentHotelKey] , 
			[StartDate] , 
			[EndDate] , 
			[CurrentRecord] , 
			[InferredMember] , 
			[DSSourceCode] , 
			[DSCreateDate] , 
			[DSCreateUser] , 
			[DSLastChangeDate] , 
			[DSLastChangeUser] , 
			[DSChangeReason],
--V3 Start
			[LanyonID]
--V3 End			
			)
VALUES (Source.[HotelKey] , 
		Source.[HotelChainKey] , 
		Source.[GDSPropertyNumber] , 
		Source.[GeoKey] , 
		Source.[PropertyName] , 
		Source.[Address1] , 
		Source.[Address2] , 
		Source.[Address3] , 
		Source.[CityCode] , 
		Source.[CityName] , 
		Source.[State] , 
		Source.[PostalCode] , 
		Source.[CountryKey] , 
		Source.[Phone] , 
		Source.[HotelID] , 
		Source.[ChkSum] , 
		Source.[BCDPropertyName] , 
		Source.[StateProvinceName] , 
		Source.[PropertyLatitude] , 
		Source.[PropertyLongitude] , 
		Source.[GeoResolutionCode] , 
		Source.[GeoResolution] , 
		Source.[BCDMultAptCityCode] , 
		Source.[BCDMultAptCityName] , 
		Source.[MutiAptCityCode] , 
		Source.[AirportLatitude] , 
		Source.[AirportLongitude] , 
		Source.[DstMiles] , 
		Source.[DstKm] , 
		Source.[PropApTyp] , 
		Source.[PhoneCountryCode] , 
		Source.[PhoneCityCode] , 
		Source.[PhoneExchange] , 
		Source.[Fax] , 
		Source.[FaxCountryCode] , 
		Source.[FaxCityCode] , 
		Source.[FaxExchange] , 
		Source.[AmadeusID] , 
		Source.[AmadeusBrandCode] , 
		Source.[WorldSpanID] , 
		Source.[WorldSpanBrandCode] , 
		Source.[SabreID] , 
		Source.[SabreBrandCode] , 
		Source.[ApolloID] , 
		Source.[ApolloBrandCode] , 
		Source.[MarketTier] , 
		Source.[ServiceLevel] , 
		Source.[BCDPropertyID] , 
		Source.[ParentHotelKey] , 
		Source.[StartDate] , 
		Source.[EndDate] , 
		Source.[CurrentRecord] , 
		Source.[InferredMember] , 
		Source.[DSSourceCode] , 
		Source.[DSCreateDate] , 
		Source.[DSCreateUser] , 
		Source.[DSLastChangeDate] , 
		Source.[DSLastChangeUser] , 
		Source.[DSChangeReason] ,
--V3 Start
		Source.[LanyonID]
--V3 End		
		) ;

--V1 Start (Not required check ConformingDimensions.dbo.spiuDimHotelHMF)
/*
UPDATE A
SET A.ParentHotelkey = A.Hotelkey
FROM ConformingDimensions.dbo.dimHotelHMF A  WITH (ROWLOCK)
JOIN  [ConformingDimensions].[dbo].[STAGE_dimHotelHMFOrphanArchive] B  (NOLOCK)
ON A.ParentHotelkey = B.Hotelkey
WHERE A.ParentHotelkey <> A.Hotelkey
*/
--V1 End

DELETE A 
FROM ConformingDimensions.dbo.dimHotelHMF A  WITH (ROWLOCK)
JOIN  [ConformingDimensions].[dbo].[STAGE_dimHotelHMFOrphanArchive] B  (NOLOCK)
ON A.HotelID = B.HotelID 

SELECT @RecsDeletedConfDim = @@RowCount

TRUNCATE TABLE [ConformingDimensions].[dbo].[STAGE_dimHotelHMFOrphanArchive]
SET @EndDate = GETDATE()
-- Logging: ConformingDimensions final							
	EXEC DMLogs.dbo.spiuPackageExecution
			@ExecutionID = @ExecIDConfDim,	 
			@RowCount = @RecsDeletedConfDim,
			@EndDate = @EndDate  

-- ConformingDimensions End

-- PreTrip Begin

-- Logging: PreTrip initial	
	EXEC DMLogs.dbo.spiuPackageExecution 
				@DataMart = @DataMart,
				@PackageType = @TaskNamePreTrip,
				@ParentExecutionID = @ExecutionID,
				@Version=@Version,
				@ExecutionID = @ExecIDPreTrip OUTPUT

TRUNCATE TABLE [PreTripDM_Stage].[dbo].[STAGE_dimHotelHMFOrphanArchive]
INSERT INTO [PreTripDM_Stage].[dbo].[STAGE_dimHotelHMFOrphanArchive]
           ([HotelKey]
           ,[HotelChainKey]
           ,[GDSPropertyNumber]
           ,[GeoKey]
           ,[PropertyName]
           ,[Address1]
           ,[Address2]
           ,[Address3]
           ,[CityCode]
           ,[CityName]
           ,[State]
           ,[PostalCode]
           ,[CountryKey]
           ,[Phone]
           ,[HotelID]
           ,[ChkSum]
           ,[BCDPropertyName]
           ,[StateProvinceName]
           ,[PropertyLatitude]
           ,[PropertyLongitude]
           ,[GeoResolutionCode]
           ,[GeoResolution]
           ,[BCDMultAptCityCode]
           ,[BCDMultAptCityName]
           ,[MutiAptCityCode]
           ,[AirportLatitude]
           ,[AirportLongitude]
           ,[DstMiles]
           ,[DstKm]
           ,[PropApTyp]
           ,[PhoneCountryCode]
           ,[PhoneCityCode]
           ,[PhoneExchange]
           ,[Fax]
           ,[FaxCountryCode]
           ,[FaxCityCode]
           ,[FaxExchange]
           ,[AmadeusID]
           ,[AmadeusBrandCode]
           ,[WorldSpanID]
           ,[WorldSpanBrandCode]
           ,[SabreID]
           ,[SabreBrandCode]
           ,[ApolloID]
           ,[ApolloBrandCode]
           ,[MarketTier]
           ,[ServiceLevel]
           ,[BCDPropertyID]
           ,[ParentHotelKey]
           ,[StartDate]
           ,[EndDate]
           ,[CurrentRecord]
           ,[InferredMember]
           ,[DSSourceCode]
           ,[DSCreateDate]
           ,[DSCreateUser]
           ,[DSLastChangeDate]
           ,[DSLastChangeUser]
           ,[DSChangeReason]
--V3 Start
		   ,[LanyonID]
--V3 End			   
		   )

	SELECT A.[HotelKey]
      ,A.[HotelChainKey]
      ,A.[GDSPropertyNumber]
      ,A.[GeoKey]
      ,A.[PropertyName]
      ,A.[Address1]
      ,A.[Address2]
      ,A.[Address3]
      ,A.[CityCode]
      ,A.[CityName]
      ,A.[State]
      ,A.[PostalCode]
      ,A.[CountryKey]
      ,A.[Phone]
      ,A.[HotelID]
      ,A.[ChkSum]
      ,A.[BCDPropertyName]
      ,A.[StateProvinceName]
      ,A.[PropertyLatitude]
      ,A.[PropertyLongitude]
      ,A.[GeoResolutionCode]
      ,A.[GeoResolution]
      ,A.[BCDMultAptCityCode]
      ,A.[BCDMultAptCityName]
      ,A.[MutiAptCityCode]
      ,A.[AirportLatitude]
      ,A.[AirportLongitude]
      ,A.[DstMiles]
      ,A.[DstKm]
      ,A.[PropApTyp]
      ,A.[PhoneCountryCode]
      ,A.[PhoneCityCode]
      ,A.[PhoneExchange]
      ,A.[Fax]
      ,A.[FaxCountryCode]
      ,A.[FaxCityCode]
      ,A.[FaxExchange]
      ,A.[AmadeusID]
      ,A.[AmadeusBrandCode]
      ,A.[WorldSpanID]
      ,A.[WorldSpanBrandCode]
      ,A.[SabreID]
      ,A.[SabreBrandCode]
      ,A.[ApolloID]
      ,A.[ApolloBrandCode]
      ,A.[MarketTier]
      ,A.[ServiceLevel]
      ,A.[BCDPropertyID]
      ,A.[ParentHotelKey]
      ,A.[StartDate]
      ,A.[EndDate]
      ,A.[CurrentRecord]
      ,A.[InferredMember]
      ,A.[DSSourceCode]
      ,A.[DSCreateDate]
      ,A.[DSCreateUser]
      ,A.[DSLastChangeDate]
      ,A.[DSLastChangeUser]
      ,A.[DSChangeReason]
--V3 Start
	  ,A.[LanyonID]
--V3 End
	FROM PreTripDataMart.dbo.dimHotelHMF A  (NOLOCK)
	--JOIN ODSMasterTables_Stage.dbo.HotelOrphanPurge P (NOLOCK)
	--ON A.HotelID = P.HotelID
	--WHERE P.RowID BETWEEN @MinRowID AND @MaxRowID  
	 JOIN dbo.#HotelOrphanPurge P
	 ON A.HotelID = P.HotelID

MERGE INTO [DSCommonLogArchive].[dbo].[dimHotelHMFOrphanArchivePreTrip] AS Target
USING [PreTripDM_Stage].[dbo].[STAGE_dimHotelHMFOrphanArchive] (NOLOCK)
    AS Source
ON Target.HotelID = Source.HotelID
WHEN MATCHED THEN
UPDATE SET 
	Target.[HotelKey]			= Source.[HotelKey],
	Target.[HotelChainKey]		= Source.[HotelChainKey],
	Target.[GDSPropertyNumber]	= Source.[GDSPropertyNumber],
	Target.[GeoKey]				= Source.[GeoKey],
	Target.[PropertyName]		= Source.[PropertyName],
	Target.[Address1]			= Source.[Address1],
	Target.[Address2]			= Source.[Address2],
	Target.[Address3]			= Source.[Address3],
	Target.[CityCode]			= Source.[CityCode],
	Target.[CityName]			= Source.[CityName],
	Target.[State]				= Source.[State],
	Target.[PostalCode]			= Source.[PostalCode],
	Target.[CountryKey]			= Source.[CountryKey],
	Target.[Phone]				= Source.[Phone],
	--Target.[HotelID]			= Source.[HotelID],
	Target.[ChkSum]				= Source.[ChkSum],
	Target.[BCDPropertyName]	= Source.[BCDPropertyName],
	Target.[StateProvinceName]	= Source.[StateProvinceName],
	Target.[PropertyLatitude]	= Source.[PropertyLatitude],
	Target.[PropertyLongitude]	= Source.[PropertyLongitude],
	Target.[GeoResolutionCode]	= Source.[GeoResolutionCode],
	Target.[GeoResolution]		= Source.[GeoResolution],
	Target.[BCDMultAptCityCode] = Source.[BCDMultAptCityCode],
	Target.[BCDMultAptCityName] = Source.[BCDMultAptCityName],
	Target.[MutiAptCityCode]	= Source.[MutiAptCityCode],
	Target.[AirportLatitude]	= Source.[AirportLatitude],
	Target.[AirportLongitude]	= Source.[AirportLongitude],
	Target.[DstMiles]			= Source.[DstMiles],
	Target.[DstKm]				= Source.[DstKm],
	Target.[PropApTyp]			= Source.[PropApTyp],
	Target.[PhoneCountryCode]	= Source.[PhoneCountryCode],
	Target.[PhoneCityCode]		= Source.[PhoneCityCode],
	Target.[PhoneExchange]		= Source.[PhoneExchange],
	Target.[Fax]				= Source.[Fax],
	Target.[FaxCountryCode]		= Source.[FaxCountryCode],
	Target.[FaxCityCode]		= Source.[FaxCityCode],
	Target.[FaxExchange]		= Source.[FaxExchange],
	Target.[AmadeusID]			= Source.[AmadeusID],
	Target.[AmadeusBrandCode]	= Source.[AmadeusBrandCode],
	Target.[WorldSpanID]		= Source.[WorldSpanID],
	Target.[WorldSpanBrandCode] = Source.[WorldSpanBrandCode],
	Target.[SabreID]			= Source.[SabreID],
	Target.[SabreBrandCode]		= Source.[SabreBrandCode],
	Target.[ApolloID]			= Source.[ApolloID],
	Target.[ApolloBrandCode]	= Source.[ApolloBrandCode],
	Target.[MarketTier]			= Source.[MarketTier],
	Target.[ServiceLevel]		= Source.[ServiceLevel],
	Target.[BCDPropertyID]		= Source.[BCDPropertyID],
	Target.[ParentHotelKey]		= Source.[ParentHotelKey],
	Target.[StartDate]			= Source.[StartDate],
	Target.[EndDate]			= Source.[EndDate],
	Target.[CurrentRecord]		= Source.[CurrentRecord],
	Target.[InferredMember]		= Source.[InferredMember],
	Target.[DSSourceCode]		= Source.[DSSourceCode],
	Target.[DSCreateDate]		= Source.[DSCreateDate],
	Target.[DSCreateUser]		= Source.[DSCreateUser],
	Target.[DSLastChangeDate]	= Source.[DSLastChangeDate],
	Target.[DSLastChangeUser]	= Source.[DSLastChangeUser],
	Target.[DSChangeReason]		= Source.[DSChangeReason],
--V3 Start
	Target.[LanyonID]			= Source.[LanyonID]
--V3 End
WHEN NOT MATCHED THEN
    INSERT ([HotelKey] , 
			[HotelChainKey] , 
			[GDSPropertyNumber] , 
			[GeoKey] , 
			[PropertyName] , 
			[Address1] , 
			[Address2] , 
			[Address3] , 
			[CityCode] , 
			[CityName] , 
			[State] , 
			[PostalCode] , 
			[CountryKey] , 
			[Phone] , 
			[HotelID] , 
			[ChkSum] , 
			[BCDPropertyName] , 
			[StateProvinceName] , 
			[PropertyLatitude] , 
			[PropertyLongitude] , 
			[GeoResolutionCode] , 
			[GeoResolution] , 
			[BCDMultAptCityCode] , 
			[BCDMultAptCityName] , 
			[MutiAptCityCode] , 
			[AirportLatitude] , 
			[AirportLongitude] , 
			[DstMiles] , 
			[DstKm] , 
			[PropApTyp] , 
			[PhoneCountryCode] , 
			[PhoneCityCode] , 
			[PhoneExchange] , 
			[Fax] , 
			[FaxCountryCode] , 
			[FaxCityCode] , 
			[FaxExchange] , 
			[AmadeusID] , 
			[AmadeusBrandCode] , 
			[WorldSpanID] , 
			[WorldSpanBrandCode] , 
			[SabreID] , 
			[SabreBrandCode] , 
			[ApolloID] , 
			[ApolloBrandCode] , 
			[MarketTier] , 
			[ServiceLevel] , 
			[BCDPropertyID] , 
			[ParentHotelKey] , 
			[StartDate] , 
			[EndDate] , 
			[CurrentRecord] , 
			[InferredMember] , 
			[DSSourceCode] , 
			[DSCreateDate] , 
			[DSCreateUser] , 
			[DSLastChangeDate] , 
			[DSLastChangeUser] , 
			[DSChangeReason] ,
--V3 Start
			[LanyonID]
--V3 End			
			)
VALUES (Source.[HotelKey] , 
		Source.[HotelChainKey] , 
		Source.[GDSPropertyNumber] , 
		Source.[GeoKey] , 
		Source.[PropertyName] , 
		Source.[Address1] , 
		Source.[Address2] , 
		Source.[Address3] , 
		Source.[CityCode] , 
		Source.[CityName] , 
		Source.[State] , 
		Source.[PostalCode] , 
		Source.[CountryKey] , 
		Source.[Phone] , 
		Source.[HotelID] , 
		Source.[ChkSum] , 
		Source.[BCDPropertyName] , 
		Source.[StateProvinceName] , 
		Source.[PropertyLatitude] , 
		Source.[PropertyLongitude] , 
		Source.[GeoResolutionCode] , 
		Source.[GeoResolution] , 
		Source.[BCDMultAptCityCode] , 
		Source.[BCDMultAptCityName] , 
		Source.[MutiAptCityCode] , 
		Source.[AirportLatitude] , 
		Source.[AirportLongitude] , 
		Source.[DstMiles] , 
		Source.[DstKm] , 
		Source.[PropApTyp] , 
		Source.[PhoneCountryCode] , 
		Source.[PhoneCityCode] , 
		Source.[PhoneExchange] , 
		Source.[Fax] , 
		Source.[FaxCountryCode] , 
		Source.[FaxCityCode] , 
		Source.[FaxExchange] , 
		Source.[AmadeusID] , 
		Source.[AmadeusBrandCode] , 
		Source.[WorldSpanID] , 
		Source.[WorldSpanBrandCode] , 
		Source.[SabreID] , 
		Source.[SabreBrandCode] , 
		Source.[ApolloID] , 
		Source.[ApolloBrandCode] , 
		Source.[MarketTier] , 
		Source.[ServiceLevel] , 
		Source.[BCDPropertyID] , 
		Source.[ParentHotelKey] , 
		Source.[StartDate] , 
		Source.[EndDate] , 
		Source.[CurrentRecord] , 
		Source.[InferredMember] , 
		Source.[DSSourceCode] , 
		Source.[DSCreateDate] , 
		Source.[DSCreateUser] , 
		Source.[DSLastChangeDate] , 
		Source.[DSLastChangeUser] , 
		Source.[DSChangeReason] ,
--V3 Start
		Source.[LanyonID]
--V3 End		
		) ;

		
--V2 Start
IF OBJECT_ID('tempdb.dbo.#ConflictParentkeyCancelledHotel') IS NOT NULL
DROP TABLE dbo.#ConflictParentkeyCancelledHotel;

SELECT odh.HotelID, odh.HotelKey
INTO   dbo.#ConflictParentkeyCancelledHotel
FROM   [PreTripDM_Stage].[dbo].[STAGE_dimHotelHMFOrphanArchive] odh WITH (NOLOCK)
JOIN   PreTripDataMart.dbo.dimHotelHMF cdh WITH (NOLOCK)
ON     odh.HotelKey = cdh.ParentHotelKey AND cdh.HotelKey <> cdh.ParentHotelKey
UNION
SELECT odh.HotelID, odh.HotelKey
FROM   [PreTripDM_Stage].[dbo].[STAGE_dimHotelHMFOrphanArchive] odh WITH (NOLOCK)
WHERE  EXISTS (  SELECT 1
					FROM   PreTripDataMart.dbo.factCancelledHotel WITH (NOLOCK)
					WHERE  HotelKey = odh.HotelKey );

IF EXISTS (SELECT TOP 1 HotelID FROM dbo.#ConflictParentkeyCancelledHotel)
BEGIN
	SET IDENTITY_INSERT [ODSMasterTables].[dbo].[ODSLkupHotel] ON;
	INSERT INTO [ODSMasterTables].[dbo].[ODSLkupHotel] WITH (TABLOCK)
	(
		   [HotelKey]
		  ,[System]
		  ,[HotelID]
		  ,[GDSHotelNumber]
		  ,[HotelChainCode]
		  ,[HotelChainName]
		  ,[HotelName]
		  ,[HotelAddr1]
		  ,[HotelAddr2]
		  ,[HotelAddr3]
		  ,[HotelCityCode]
		  ,[HotelCityName]
		  ,[HotelState]
		  ,[HotelCountryCode]
		  ,[HotelCountry]
		  ,[HotelPostalCode]
		  ,[HotelPhoneNumber]
		  ,[GeoKey]
		  ,[Latitude]
		  ,[Longitude]
		  ,[CreateDate]
		  ,[UpdateDate]
		  ,[isMasterData]
		  ,[colCheckSum]
		  ,[MasterHotelID]
		  --,[HotelPhoneNumberReversed]
		  ,[HotelPhoneNumberRight10]
		  ,[GDSCodeFormatted]
		  ,[CRSCode]
	)
	SELECT da.[HotelKey]
		  ,da.[System]
		  ,da.[HotelID]
		  ,da.[GDSHotelNumber]
		  ,da.[HotelChainCode]
		  ,da.[HotelChainName]
		  ,da.[HotelName]
		  ,da.[HotelAddr1]
		  ,da.[HotelAddr2]
		  ,da.[HotelAddr3]
		  ,da.[HotelCityCode]
		  ,da.[HotelCityName]
		  ,da.[HotelState]
		  ,da.[HotelCountryCode]
		  ,da.[HotelCountry]
		  ,da.[HotelPostalCode]
		  ,da.[HotelPhoneNumber]
		  ,da.[GeoKey]
		  ,da.[Latitude]
		  ,da.[Longitude]
		  ,da.[CreateDate]
		  ,da.[UpdateDate]
		  ,da.[isMasterData]
		  ,da.[colCheckSum]
		  ,da.[MasterHotelID]
		  --,da.[HotelPhoneNumberReversed]
		  ,da.[HotelPhoneNumberRight10]
		  ,da.[GDSCodeFormatted]
		  ,da.[CRSCode]
	FROM [DSCommonLogArchive].[dbo].[ODSLkupHotelOrphanArchive] da (NOLOCK)
	JOIN dbo.#ConflictParentkeyCancelledHotel ct
	ON da.HotelID = ct.HotelID
	WHERE NOT EXISTS (SELECT 1 FROM [ODSMasterTables].[dbo].[ODSLkupHotel] oh (NOLOCK) 
					  WHERE oh.HotelID = da.HotelID);

	SET IDENTITY_INSERT [ODSMasterTables].[dbo].[ODSLkupHotel] OFF;

	INSERT INTO [ODSMasterTables].[dbo].[ODSLkupHotelBCDMaster] WITH (ROWLOCK)
	(	   [HotelKey]
		  ,[BCDPropertyID]
		  ,[DSSourceCode]
		  ,[DSCreateDate]
		  ,[DSCreateUser]
		  ,[DSLastChangeDate]
		  ,[DSLastChangeUser]
		  ,[DSChangeReason]
	)
	SELECT da.[HotelKey]
		  ,da.[BCDPropertyID]
		  ,da.[DSSourceCode]
		  ,da.[DSCreateDate]
		  ,da.[DSCreateUser]
		  ,da.[DSLastChangeDate]
		  ,da.[DSLastChangeUser]
		  ,da.[DSChangeReason]
	FROM [DSCommonLogArchive].[dbo].[ODSLkupHotelBCDMasterOrphanArchive] da WITH (NOLOCK)
	JOIN ODSMasterTables.dbo.ODSLkupHotel oh WITH (NOLOCK)
	ON da.HotelKey = oh.HotelKey
	JOIN dbo.#ConflictParentkeyCancelledHotel ct
	ON oh.HotelID = ct.HotelID
	WHERE NOT EXISTS (SELECT 1 FROM [ODSMasterTables].[dbo].[ODSLkupHotelBCDMaster] br (NOLOCK) 
					  WHERE br.HotelKey = da.HotelKey);

	SET IDENTITY_INSERT [ConformingDimensions].[dbo].[dimHotelHMF] ON;
	INSERT INTO [ConformingDimensions].[dbo].[dimHotelHMF] WITH (TABLOCK)
	(
		   [HotelKey]
		  ,[HotelChainKey]
		  ,[GDSPropertyNumber]
		  ,[GeoKey]
		  ,[PropertyName]
		  ,[Address1]
		  ,[Address2]
		  ,[Address3]
		  ,[CityCode]
		  ,[CityName]
		  ,[State]
		  ,[PostalCode]
		  ,[CountryKey]
		  ,[Phone]
		  ,[HotelID]
		  ,[BCDPropertyName]
		  ,[StateProvinceName]
		  ,[PropertyLatitude]
		  ,[PropertyLongitude]
		  ,[GeoResolutionCode]
		  ,[GeoResolution]
		  ,[BCDMultAptCityCode]
		  ,[BCDMultAptCityName]
		  ,[MutiAptCityCode]
		  ,[AirportLatitude]
		  ,[AirportLongitude]
		  ,[DstMiles]
		  ,[DstKm]
		  ,[PropApTyp]
		  ,[PhoneCountryCode]
		  ,[PhoneCityCode]
		  ,[PhoneExchange]
		  ,[Fax]
		  ,[FaxCountryCode]
		  ,[FaxCityCode]
		  ,[FaxExchange]
		  ,[AmadeusID]
		  ,[AmadeusBrandCode]
		  ,[WorldSpanID]
		  ,[WorldSpanBrandCode]
		  ,[SabreID]
		  ,[SabreBrandCode]
		  ,[ApolloID]
		  ,[ApolloBrandCode]
		  ,[MarketTier]
		  ,[ServiceLevel]
		  ,[BCDPropertyID]
		  ,[ParentHotelKey]
		  ,[StartDate]
		  ,[EndDate]
		  ,[CurrentRecord]
		  ,[InferredMember]
		  ,[DSSourceCode]
		  ,[DSCreateDate]
		  ,[DSCreateUser]
		  ,[DSLastChangeDate]
		  ,[DSLastChangeUser]
		  ,[DSChangeReason]
		  ,[ChkSum]
--V3 Start
		  ,[LanyonID]
--V3 End
	)
	SELECT da.[HotelKey]
		  ,da.[HotelChainKey]
		  ,da.[GDSPropertyNumber]
		  ,da.[GeoKey]
		  ,da.[PropertyName]
		  ,da.[Address1]
		  ,da.[Address2]
		  ,da.[Address3]
		  ,da.[CityCode]
		  ,da.[CityName]
		  ,da.[State]
		  ,da.[PostalCode]
		  ,da.[CountryKey]
		  ,da.[Phone]
		  ,da.[HotelID]
		  ,da.[BCDPropertyName]
		  ,da.[StateProvinceName]
		  ,da.[PropertyLatitude]
		  ,da.[PropertyLongitude]
		  ,da.[GeoResolutionCode]
		  ,da.[GeoResolution]
		  ,da.[BCDMultAptCityCode]
		  ,da.[BCDMultAptCityName]
		  ,da.[MutiAptCityCode]
		  ,da.[AirportLatitude]
		  ,da.[AirportLongitude]
		  ,da.[DstMiles]
		  ,da.[DstKm]
		  ,da.[PropApTyp]
		  ,da.[PhoneCountryCode]
		  ,da.[PhoneCityCode]
		  ,da.[PhoneExchange]
		  ,da.[Fax]
		  ,da.[FaxCountryCode]
		  ,da.[FaxCityCode]
		  ,da.[FaxExchange]
		  ,da.[AmadeusID]
		  ,da.[AmadeusBrandCode]
		  ,da.[WorldSpanID]
		  ,da.[WorldSpanBrandCode]
		  ,da.[SabreID]
		  ,da.[SabreBrandCode]
		  ,da.[ApolloID]
		  ,da.[ApolloBrandCode]
		  ,da.[MarketTier]
		  ,da.[ServiceLevel]
		  ,da.[BCDPropertyID]
		  ,da.[ParentHotelKey]
		  ,da.[StartDate]
		  ,da.[EndDate]
		  ,da.[CurrentRecord]
		  ,da.[InferredMember]
		  ,da.[DSSourceCode]
		  ,da.[DSCreateDate]
		  ,da.[DSCreateUser]
		  ,da.[DSLastChangeDate]
		  ,da.[DSLastChangeUser]
		  ,da.[DSChangeReason]
		  ,da.[ChkSum]
--V3 Start
		  ,da.[LanyonID]
--V3 End
	FROM [DSCommonLogArchive].[dbo].[dimHotelHMFOrphanArchiveConfDim] da (NOLOCK)
	JOIN dbo.#ConflictParentkeyCancelledHotel ct
	ON da.HotelKey = ct.HotelKey
	WHERE NOT EXISTS (SELECT 1 FROM [ConformingDimensions].[dbo].[dimHotelHMF] dh (NOLOCK) 
					  WHERE dh.HotelKey = da.HotelKey);

	SET IDENTITY_INSERT [ConformingDimensions].[dbo].[dimHotelHMF] OFF;
END
--V2 End

DELETE A 
FROM PreTripDataMart.dbo.dimHotelHMF A  WITH (ROWLOCK)
JOIN  [PreTripDM_Stage].[dbo].[STAGE_dimHotelHMFOrphanArchive] B  (NOLOCK)
ON A.HotelID = B.HotelID 
WHERE NOT EXISTS (SELECt 1 FROM dbo.#ConflictParentkeyCancelledHotel ct WHERE ct.HotelKey = B.HotelKey)--V2

SELECT @RecsDeletedPreTrip = @@RowCount

TRUNCATE TABLE [PreTripDM_Stage].[dbo].[STAGE_dimHotelHMFOrphanArchive]
SET @EndDate = GETDATE()
-- Logging: PreTrip final							
	EXEC DMLogs.dbo.spiuPackageExecution
			@ExecutionID = @ExecIDPreTrip,	 
			@RowCount = @RecsDeletedPreTrip,
			@EndDate = @EndDate  
-- PreTrip End

-- PostTrip Begin
EXEC DMLogs.dbo.spiuPackageExecution 	
			@DataMart = @DataMart,
			@PackageType = @TaskNamePostTrip,
			@ParentExecutionID = @ExecutionID,
			@Version=@Version,
			@ExecutionID = @ExecIDPostTrip OUTPUT

TRUNCATE TABLE [PostTripDM_Stage].[dbo].[STAGE_dimHotelHMFOrphanArchive]
INSERT INTO [PostTripDM_Stage].[dbo].[STAGE_dimHotelHMFOrphanArchive]
           ([HotelKey]
           ,[HotelChainKey]
           ,[GDSPropertyNumber]
           ,[GeoKey]
           ,[PropertyName]
           ,[Address1]
           ,[Address2]
           ,[Address3]
           ,[CityCode]
           ,[CityName]
           ,[State]
           ,[PostalCode]
           ,[CountryKey]
           ,[Phone]
           ,[HotelID]
           ,[ChkSum]
           ,[BCDPropertyName]
           ,[StateProvinceName]
           ,[PropertyLatitude]
           ,[PropertyLongitude]
           ,[GeoResolutionCode]
           ,[GeoResolution]
           ,[BCDMultAptCityCode]
           ,[BCDMultAptCityName]
           ,[MutiAptCityCode]
           ,[AirportLatitude]
           ,[AirportLongitude]
           ,[DstMiles]
           ,[DstKm]
           ,[PropApTyp]
           ,[PhoneCountryCode]
           ,[PhoneCityCode]
           ,[PhoneExchange]
           ,[Fax]
           ,[FaxCountryCode]
           ,[FaxCityCode]
           ,[FaxExchange]
           ,[AmadeusID]
           ,[AmadeusBrandCode]
           ,[WorldSpanID]
           ,[WorldSpanBrandCode]
           ,[SabreID]
           ,[SabreBrandCode]
           ,[ApolloID]
           ,[ApolloBrandCode]
           ,[MarketTier]
           ,[ServiceLevel]
           ,[BCDPropertyID]
           ,[ParentHotelKey]
           ,[StartDate]
           ,[EndDate]
           ,[CurrentRecord]
           ,[InferredMember]
           ,[DSSourceCode]
           ,[DSCreateDate]
           ,[DSCreateUser]
           ,[DSLastChangeDate]
           ,[DSLastChangeUser]
           ,[DSChangeReason]
--V3 Start
		   ,[LanyonID]
--V3 End		   
		   )

	SELECT A.[HotelKey]
      ,A.[HotelChainKey]
      ,A.[GDSPropertyNumber]
      ,A.[GeoKey]
      ,A.[PropertyName]
      ,A.[Address1]
      ,A.[Address2]
      ,A.[Address3]
      ,A.[CityCode]
      ,A.[CityName]
      ,A.[State]
      ,A.[PostalCode]
      ,A.[CountryKey]
      ,A.[Phone]
      ,A.[HotelID]
      ,A.[ChkSum]
      ,A.[BCDPropertyName]
      ,A.[StateProvinceName]
      ,A.[PropertyLatitude]
      ,A.[PropertyLongitude]
      ,A.[GeoResolutionCode]
      ,A.[GeoResolution]
      ,A.[BCDMultAptCityCode]
      ,A.[BCDMultAptCityName]
      ,A.[MutiAptCityCode]
      ,A.[AirportLatitude]
      ,A.[AirportLongitude]
      ,A.[DstMiles]
      ,A.[DstKm]
      ,A.[PropApTyp]
      ,A.[PhoneCountryCode]
      ,A.[PhoneCityCode]
      ,A.[PhoneExchange]
      ,A.[Fax]
      ,A.[FaxCountryCode]
      ,A.[FaxCityCode]
      ,A.[FaxExchange]
      ,A.[AmadeusID]
      ,A.[AmadeusBrandCode]
      ,A.[WorldSpanID]
      ,A.[WorldSpanBrandCode]
      ,A.[SabreID]
      ,A.[SabreBrandCode]
      ,A.[ApolloID]
      ,A.[ApolloBrandCode]
      ,A.[MarketTier]
      ,A.[ServiceLevel]
      ,A.[BCDPropertyID]
      ,A.[ParentHotelKey]
      ,A.[StartDate]
      ,A.[EndDate]
      ,A.[CurrentRecord]
      ,A.[InferredMember]
      ,A.[DSSourceCode]
      ,A.[DSCreateDate]
      ,A.[DSCreateUser]
      ,A.[DSLastChangeDate]
      ,A.[DSLastChangeUser]
      ,A.[DSChangeReason]
--V3 Start
	  ,A.[LanyonID]
--V3 End
	FROM PostTripDM.dbo.dimHotelHMF A  (NOLOCK)
	--JOIN ODSMasterTables_Stage.dbo.HotelOrphanPurge P (NOLOCK)
	--ON A.HotelID = P.HotelID
	--WHERE P.RowID BETWEEN @MinRowID AND @MaxRowID 
	JOIN dbo.#HotelOrphanPurge P
	ON A.HotelID = P.HotelID

MERGE INTO [DSCommonLogArchive].[dbo].[dimHotelHMFOrphanArchivePostTrip] AS Target
USING [PostTripDM_Stage].[dbo].[STAGE_dimHotelHMFOrphanArchive] (NOLOCK)
    AS Source
ON Target.HotelID = Source.HotelID
WHEN MATCHED THEN
UPDATE SET 
	Target.[HotelKey]			= Source.[HotelKey],
	Target.[HotelChainKey]		= Source.[HotelChainKey],
	Target.[GDSPropertyNumber]	= Source.[GDSPropertyNumber],
	Target.[GeoKey]				= Source.[GeoKey],
	Target.[PropertyName]		= Source.[PropertyName],
	Target.[Address1]			= Source.[Address1],
	Target.[Address2]			= Source.[Address2],
	Target.[Address3]			= Source.[Address3],
	Target.[CityCode]			= Source.[CityCode],
	Target.[CityName]			= Source.[CityName],
	Target.[State]				= Source.[State],
	Target.[PostalCode]			= Source.[PostalCode],
	Target.[CountryKey]			= Source.[CountryKey],
	Target.[Phone]				= Source.[Phone],
	--Target.[HotelID]			= Source.[HotelID],
	Target.[ChkSum]				= Source.[ChkSum],
	Target.[BCDPropertyName]	= Source.[BCDPropertyName],
	Target.[StateProvinceName]	= Source.[StateProvinceName],
	Target.[PropertyLatitude]	= Source.[PropertyLatitude],
	Target.[PropertyLongitude]	= Source.[PropertyLongitude],
	Target.[GeoResolutionCode]	= Source.[GeoResolutionCode],
	Target.[GeoResolution]		= Source.[GeoResolution],
	Target.[BCDMultAptCityCode] = Source.[BCDMultAptCityCode],
	Target.[BCDMultAptCityName] = Source.[BCDMultAptCityName],
	Target.[MutiAptCityCode]	= Source.[MutiAptCityCode],
	Target.[AirportLatitude]	= Source.[AirportLatitude],
	Target.[AirportLongitude]	= Source.[AirportLongitude],
	Target.[DstMiles]			= Source.[DstMiles],
	Target.[DstKm]				= Source.[DstKm],
	Target.[PropApTyp]			= Source.[PropApTyp],
	Target.[PhoneCountryCode]	= Source.[PhoneCountryCode],
	Target.[PhoneCityCode]		= Source.[PhoneCityCode],
	Target.[PhoneExchange]		= Source.[PhoneExchange],
	Target.[Fax]				= Source.[Fax],
	Target.[FaxCountryCode]		= Source.[FaxCountryCode],
	Target.[FaxCityCode]		= Source.[FaxCityCode],
	Target.[FaxExchange]		= Source.[FaxExchange],
	Target.[AmadeusID]			= Source.[AmadeusID],
	Target.[AmadeusBrandCode]	= Source.[AmadeusBrandCode],
	Target.[WorldSpanID]		= Source.[WorldSpanID],
	Target.[WorldSpanBrandCode] = Source.[WorldSpanBrandCode],
	Target.[SabreID]			= Source.[SabreID],
	Target.[SabreBrandCode]		= Source.[SabreBrandCode],
	Target.[ApolloID]			= Source.[ApolloID],
	Target.[ApolloBrandCode]	= Source.[ApolloBrandCode],
	Target.[MarketTier]			= Source.[MarketTier],
	Target.[ServiceLevel]		= Source.[ServiceLevel],
	Target.[BCDPropertyID]		= Source.[BCDPropertyID],
	Target.[ParentHotelKey]		= Source.[ParentHotelKey],
	Target.[StartDate]			= Source.[StartDate],
	Target.[EndDate]			= Source.[EndDate],
	Target.[CurrentRecord]		= Source.[CurrentRecord],
	Target.[InferredMember]		= Source.[InferredMember],
	Target.[DSSourceCode]		= Source.[DSSourceCode],
	Target.[DSCreateDate]		= Source.[DSCreateDate],
	Target.[DSCreateUser]		= Source.[DSCreateUser],
	Target.[DSLastChangeDate]	= Source.[DSLastChangeDate],
	Target.[DSLastChangeUser]	= Source.[DSLastChangeUser],
	Target.[DSChangeReason]		= Source.[DSChangeReason],
--V3 Start
	Target.[LanyonID]			= Source.[LanyonID]
--V3 End
WHEN NOT MATCHED THEN
    INSERT ([HotelKey] , 
			[HotelChainKey] , 
			[GDSPropertyNumber] , 
			[GeoKey] , 
			[PropertyName] , 
			[Address1] , 
			[Address2] , 
			[Address3] , 
			[CityCode] , 
			[CityName] , 
			[State] , 
			[PostalCode] , 
			[CountryKey] , 
			[Phone] , 
			[HotelID] , 
			[ChkSum] , 
			[BCDPropertyName] , 
			[StateProvinceName] , 
			[PropertyLatitude] , 
			[PropertyLongitude] , 
			[GeoResolutionCode] , 
			[GeoResolution] , 
			[BCDMultAptCityCode] , 
			[BCDMultAptCityName] , 
			[MutiAptCityCode] , 
			[AirportLatitude] , 
			[AirportLongitude] , 
			[DstMiles] , 
			[DstKm] , 
			[PropApTyp] , 
			[PhoneCountryCode] , 
			[PhoneCityCode] , 
			[PhoneExchange] , 
			[Fax] , 
			[FaxCountryCode] , 
			[FaxCityCode] , 
			[FaxExchange] , 
			[AmadeusID] , 
			[AmadeusBrandCode] , 
			[WorldSpanID] , 
			[WorldSpanBrandCode] , 
			[SabreID] , 
			[SabreBrandCode] , 
			[ApolloID] , 
			[ApolloBrandCode] , 
			[MarketTier] , 
			[ServiceLevel] , 
			[BCDPropertyID] , 
			[ParentHotelKey] , 
			[StartDate] , 
			[EndDate] , 
			[CurrentRecord] , 
			[InferredMember] , 
			[DSSourceCode] , 
			[DSCreateDate] , 
			[DSCreateUser] , 
			[DSLastChangeDate] , 
			[DSLastChangeUser] , 
			[DSChangeReason] ,
--V3 Start
			[LanyonID]
--V3 End				
			)
VALUES (Source.[HotelKey] , 
		Source.[HotelChainKey] , 
		Source.[GDSPropertyNumber] , 
		Source.[GeoKey] , 
		Source.[PropertyName] , 
		Source.[Address1] , 
		Source.[Address2] , 
		Source.[Address3] , 
		Source.[CityCode] , 
		Source.[CityName] , 
		Source.[State] , 
		Source.[PostalCode] , 
		Source.[CountryKey] , 
		Source.[Phone] , 
		Source.[HotelID] , 
		Source.[ChkSum] , 
		Source.[BCDPropertyName] , 
		Source.[StateProvinceName] , 
		Source.[PropertyLatitude] , 
		Source.[PropertyLongitude] , 
		Source.[GeoResolutionCode] , 
		Source.[GeoResolution] , 
		Source.[BCDMultAptCityCode] , 
		Source.[BCDMultAptCityName] , 
		Source.[MutiAptCityCode] , 
		Source.[AirportLatitude] , 
		Source.[AirportLongitude] , 
		Source.[DstMiles] , 
		Source.[DstKm] , 
		Source.[PropApTyp] , 
		Source.[PhoneCountryCode] , 
		Source.[PhoneCityCode] , 
		Source.[PhoneExchange] , 
		Source.[Fax] , 
		Source.[FaxCountryCode] , 
		Source.[FaxCityCode] , 
		Source.[FaxExchange] , 
		Source.[AmadeusID] , 
		Source.[AmadeusBrandCode] , 
		Source.[WorldSpanID] , 
		Source.[WorldSpanBrandCode] , 
		Source.[SabreID] , 
		Source.[SabreBrandCode] , 
		Source.[ApolloID] , 
		Source.[ApolloBrandCode] , 
		Source.[MarketTier] , 
		Source.[ServiceLevel] , 
		Source.[BCDPropertyID] , 
		Source.[ParentHotelKey] , 
		Source.[StartDate] , 
		Source.[EndDate] , 
		Source.[CurrentRecord] , 
		Source.[InferredMember] , 
		Source.[DSSourceCode] , 
		Source.[DSCreateDate] , 
		Source.[DSCreateUser] , 
		Source.[DSLastChangeDate] , 
		Source.[DSLastChangeUser] , 
		Source.[DSChangeReason] ,
--V3 Start
		Source.[LanyonID]
--V3 End		
		) ;

--V2 Start
IF OBJECT_ID('tempdb.dbo.#ConflictParentkey') IS NOT NULL
DROP TABLE dbo.#ConflictParentkey;

SELECT odh.HotelID, odh.HotelKey
INTO   dbo.#ConflictParentkey
FROM   [PostTripDM_Stage].[dbo].[STAGE_dimHotelHMFOrphanArchive] odh WITH (NOLOCK)
JOIN   PostTripDM.dbo.dimHotelHMF cdh WITH (NOLOCK)
ON     odh.HotelKey = cdh.ParentHotelKey AND cdh.HotelKey <> cdh.ParentHotelKey
WHERE  NOT EXISTS (SELECT 1 FROM dbo.#ConflictParentkeyCancelledHotel ct WHERE ct.HotelID = odh.HotelID);

IF EXISTS (SELECT TOP 1 HotelID FROM dbo.#ConflictParentkey)
BEGIN
	SET IDENTITY_INSERT [ODSMasterTables].[dbo].[ODSLkupHotel] ON;
	INSERT INTO [ODSMasterTables].[dbo].[ODSLkupHotel] WITH (TABLOCK)
	(
		   [HotelKey]
		  ,[System]
		  ,[HotelID]
		  ,[GDSHotelNumber]
		  ,[HotelChainCode]
		  ,[HotelChainName]
		  ,[HotelName]
		  ,[HotelAddr1]
		  ,[HotelAddr2]
		  ,[HotelAddr3]
		  ,[HotelCityCode]
		  ,[HotelCityName]
		  ,[HotelState]
		  ,[HotelCountryCode]
		  ,[HotelCountry]
		  ,[HotelPostalCode]
		  ,[HotelPhoneNumber]
		  ,[GeoKey]
		  ,[Latitude]
		  ,[Longitude]
		  ,[CreateDate]
		  ,[UpdateDate]
		  ,[isMasterData]
		  ,[colCheckSum]
		  ,[MasterHotelID]
		  --,[HotelPhoneNumberReversed]
		  ,[HotelPhoneNumberRight10]
		  ,[GDSCodeFormatted]
		  ,[CRSCode]
	)
	SELECT da.[HotelKey]
		  ,da.[System]
		  ,da.[HotelID]
		  ,da.[GDSHotelNumber]
		  ,da.[HotelChainCode]
		  ,da.[HotelChainName]
		  ,da.[HotelName]
		  ,da.[HotelAddr1]
		  ,da.[HotelAddr2]
		  ,da.[HotelAddr3]
		  ,da.[HotelCityCode]
		  ,da.[HotelCityName]
		  ,da.[HotelState]
		  ,da.[HotelCountryCode]
		  ,da.[HotelCountry]
		  ,da.[HotelPostalCode]
		  ,da.[HotelPhoneNumber]
		  ,da.[GeoKey]
		  ,da.[Latitude]
		  ,da.[Longitude]
		  ,da.[CreateDate]
		  ,da.[UpdateDate]
		  ,da.[isMasterData]
		  ,da.[colCheckSum]
		  ,da.[MasterHotelID]
		  --,da.[HotelPhoneNumberReversed]
		  ,da.[HotelPhoneNumberRight10]
		  ,da.[GDSCodeFormatted]
		  ,da.[CRSCode]
	FROM [DSCommonLogArchive].[dbo].[ODSLkupHotelOrphanArchive] da (NOLOCK)
	JOIN dbo.#ConflictParentkey ct
	ON da.HotelID = ct.HotelID
	WHERE NOT EXISTS (SELECT 1 FROM [ODSMasterTables].[dbo].[ODSLkupHotel] oh (NOLOCK) 
					  WHERE oh.HotelID = da.HotelID);

	SET IDENTITY_INSERT [ODSMasterTables].[dbo].[ODSLkupHotel] OFF;

	INSERT INTO [ODSMasterTables].[dbo].[ODSLkupHotelBCDMaster] WITH (ROWLOCK)
	(	   [HotelKey]
		  ,[BCDPropertyID]
		  ,[DSSourceCode]
		  ,[DSCreateDate]
		  ,[DSCreateUser]
		  ,[DSLastChangeDate]
		  ,[DSLastChangeUser]
		  ,[DSChangeReason]
	)
	SELECT da.[HotelKey]
		  ,da.[BCDPropertyID]
		  ,da.[DSSourceCode]
		  ,da.[DSCreateDate]
		  ,da.[DSCreateUser]
		  ,da.[DSLastChangeDate]
		  ,da.[DSLastChangeUser]
		  ,da.[DSChangeReason]
	FROM [DSCommonLogArchive].[dbo].[ODSLkupHotelBCDMasterOrphanArchive] da WITH (NOLOCK)
	JOIN ODSMasterTables.dbo.ODSLkupHotel oh WITH (NOLOCK)
	ON da.HotelKey = oh.HotelKey
	JOIN dbo.#ConflictParentkey ct
	ON oh.HotelID = ct.HotelID
	WHERE NOT EXISTS (SELECT 1 FROM [ODSMasterTables].[dbo].[ODSLkupHotelBCDMaster] br (NOLOCK) 
					  WHERE br.HotelKey = da.HotelKey);

	SET IDENTITY_INSERT [ConformingDimensions].[dbo].[dimHotelHMF] ON;
	INSERT INTO [ConformingDimensions].[dbo].[dimHotelHMF] WITH (TABLOCK)
	(
		   [HotelKey]
		  ,[HotelChainKey]
		  ,[GDSPropertyNumber]
		  ,[GeoKey]
		  ,[PropertyName]
		  ,[Address1]
		  ,[Address2]
		  ,[Address3]
		  ,[CityCode]
		  ,[CityName]
		  ,[State]
		  ,[PostalCode]
		  ,[CountryKey]
		  ,[Phone]
		  ,[HotelID]
		  ,[BCDPropertyName]
		  ,[StateProvinceName]
		  ,[PropertyLatitude]
		  ,[PropertyLongitude]
		  ,[GeoResolutionCode]
		  ,[GeoResolution]
		  ,[BCDMultAptCityCode]
		  ,[BCDMultAptCityName]
		  ,[MutiAptCityCode]
		  ,[AirportLatitude]
		  ,[AirportLongitude]
		  ,[DstMiles]
		  ,[DstKm]
		  ,[PropApTyp]
		  ,[PhoneCountryCode]
		  ,[PhoneCityCode]
		  ,[PhoneExchange]
		  ,[Fax]
		  ,[FaxCountryCode]
		  ,[FaxCityCode]
		  ,[FaxExchange]
		  ,[AmadeusID]
		  ,[AmadeusBrandCode]
		  ,[WorldSpanID]
		  ,[WorldSpanBrandCode]
		  ,[SabreID]
		  ,[SabreBrandCode]
		  ,[ApolloID]
		  ,[ApolloBrandCode]
		  ,[MarketTier]
		  ,[ServiceLevel]
		  ,[BCDPropertyID]
		  ,[ParentHotelKey]
		  ,[StartDate]
		  ,[EndDate]
		  ,[CurrentRecord]
		  ,[InferredMember]
		  ,[DSSourceCode]
		  ,[DSCreateDate]
		  ,[DSCreateUser]
		  ,[DSLastChangeDate]
		  ,[DSLastChangeUser]
		  ,[DSChangeReason]
		  ,[ChkSum]
--V3 Start
		  ,[LanyonID]
--V3 End	
	)
	SELECT da.[HotelKey]
		  ,da.[HotelChainKey]
		  ,da.[GDSPropertyNumber]
		  ,da.[GeoKey]
		  ,da.[PropertyName]
		  ,da.[Address1]
		  ,da.[Address2]
		  ,da.[Address3]
		  ,da.[CityCode]
		  ,da.[CityName]
		  ,da.[State]
		  ,da.[PostalCode]
		  ,da.[CountryKey]
		  ,da.[Phone]
		  ,da.[HotelID]
		  ,da.[BCDPropertyName]
		  ,da.[StateProvinceName]
		  ,da.[PropertyLatitude]
		  ,da.[PropertyLongitude]
		  ,da.[GeoResolutionCode]
		  ,da.[GeoResolution]
		  ,da.[BCDMultAptCityCode]
		  ,da.[BCDMultAptCityName]
		  ,da.[MutiAptCityCode]
		  ,da.[AirportLatitude]
		  ,da.[AirportLongitude]
		  ,da.[DstMiles]
		  ,da.[DstKm]
		  ,da.[PropApTyp]
		  ,da.[PhoneCountryCode]
		  ,da.[PhoneCityCode]
		  ,da.[PhoneExchange]
		  ,da.[Fax]
		  ,da.[FaxCountryCode]
		  ,da.[FaxCityCode]
		  ,da.[FaxExchange]
		  ,da.[AmadeusID]
		  ,da.[AmadeusBrandCode]
		  ,da.[WorldSpanID]
		  ,da.[WorldSpanBrandCode]
		  ,da.[SabreID]
		  ,da.[SabreBrandCode]
		  ,da.[ApolloID]
		  ,da.[ApolloBrandCode]
		  ,da.[MarketTier]
		  ,da.[ServiceLevel]
		  ,da.[BCDPropertyID]
		  ,da.[ParentHotelKey]
		  ,da.[StartDate]
		  ,da.[EndDate]
		  ,da.[CurrentRecord]
		  ,da.[InferredMember]
		  ,da.[DSSourceCode]
		  ,da.[DSCreateDate]
		  ,da.[DSCreateUser]
		  ,da.[DSLastChangeDate]
		  ,da.[DSLastChangeUser]
		  ,da.[DSChangeReason]
		  ,da.[ChkSum]
--V3 Start
		  ,da.[LanyonID]
--V3 End	
	FROM [DSCommonLogArchive].[dbo].[dimHotelHMFOrphanArchiveConfDim] da (NOLOCK)
	JOIN dbo.#ConflictParentkey ct
	ON da.HotelKey = ct.HotelKey
	WHERE NOT EXISTS (SELECT 1 FROM [ConformingDimensions].[dbo].[dimHotelHMF] dh (NOLOCK) 
					  WHERE dh.HotelKey = da.HotelKey);

	SET IDENTITY_INSERT [ConformingDimensions].[dbo].[dimHotelHMF] OFF;



	SET IDENTITY_INSERT [PreTripDataMart].[dbo].[dimHotelHMF] ON;
	INSERT INTO [PreTripDataMart].[dbo].[dimHotelHMF] WITH (TABLOCK)
	(
		   [HotelKey]
		  ,[HotelChainKey]
		  ,[GDSPropertyNumber]
		  ,[GeoKey]
		  ,[PropertyName]
		  ,[Address1]
		  ,[Address2]
		  ,[Address3]
		  ,[CityCode]
		  ,[CityName]
		  ,[State]
		  ,[PostalCode]
		  ,[CountryKey]
		  ,[Phone]
		  ,[HotelID]
		  ,[BCDPropertyName]
		  ,[StateProvinceName]
		  ,[PropertyLatitude]
		  ,[PropertyLongitude]
		  ,[GeoResolutionCode]
		  ,[GeoResolution]
		  ,[BCDMultAptCityCode]
		  ,[BCDMultAptCityName]
		  ,[MutiAptCityCode]
		  ,[AirportLatitude]
		  ,[AirportLongitude]
		  ,[DstMiles]
		  ,[DstKm]
		  ,[PropApTyp]
		  ,[PhoneCountryCode]
		  ,[PhoneCityCode]
		  ,[PhoneExchange]
		  ,[Fax]
		  ,[FaxCountryCode]
		  ,[FaxCityCode]
		  ,[FaxExchange]
		  ,[AmadeusID]
		  ,[AmadeusBrandCode]
		  ,[WorldSpanID]
		  ,[WorldSpanBrandCode]
		  ,[SabreID]
		  ,[SabreBrandCode]
		  ,[ApolloID]
		  ,[ApolloBrandCode]
		  ,[MarketTier]
		  ,[ServiceLevel]
		  ,[BCDPropertyID]
		  ,[ParentHotelKey]
		  ,[StartDate]
		  ,[EndDate]
		  ,[CurrentRecord]
		  ,[InferredMember]
		  ,[DSSourceCode]
		  ,[DSCreateDate]
		  ,[DSCreateUser]
		  ,[DSLastChangeDate]
		  ,[DSLastChangeUser]
		  ,[DSChangeReason]
		  ,[ChkSum]
--V3 Start
		  ,[LanyonID]
--V3 End	
	)
	SELECT da.[HotelKey]
		  ,da.[HotelChainKey]
		  ,da.[GDSPropertyNumber]
		  ,da.[GeoKey]
		  ,da.[PropertyName]
		  ,da.[Address1]
		  ,da.[Address2]
		  ,da.[Address3]
		  ,da.[CityCode]
		  ,da.[CityName]
		  ,da.[State]
		  ,da.[PostalCode]
		  ,da.[CountryKey]
		  ,da.[Phone]
		  ,da.[HotelID]
		  ,da.[BCDPropertyName]
		  ,da.[StateProvinceName]
		  ,da.[PropertyLatitude]
		  ,da.[PropertyLongitude]
		  ,da.[GeoResolutionCode]
		  ,da.[GeoResolution]
		  ,da.[BCDMultAptCityCode]
		  ,da.[BCDMultAptCityName]
		  ,da.[MutiAptCityCode]
		  ,da.[AirportLatitude]
		  ,da.[AirportLongitude]
		  ,da.[DstMiles]
		  ,da.[DstKm]
		  ,da.[PropApTyp]
		  ,da.[PhoneCountryCode]
		  ,da.[PhoneCityCode]
		  ,da.[PhoneExchange]
		  ,da.[Fax]
		  ,da.[FaxCountryCode]
		  ,da.[FaxCityCode]
		  ,da.[FaxExchange]
		  ,da.[AmadeusID]
		  ,da.[AmadeusBrandCode]
		  ,da.[WorldSpanID]
		  ,da.[WorldSpanBrandCode]
		  ,da.[SabreID]
		  ,da.[SabreBrandCode]
		  ,da.[ApolloID]
		  ,da.[ApolloBrandCode]
		  ,da.[MarketTier]
		  ,da.[ServiceLevel]
		  ,da.[BCDPropertyID]
		  ,da.[ParentHotelKey]
		  ,da.[StartDate]
		  ,da.[EndDate]
		  ,da.[CurrentRecord]
		  ,da.[InferredMember]
		  ,da.[DSSourceCode]
		  ,da.[DSCreateDate]
		  ,da.[DSCreateUser]
		  ,da.[DSLastChangeDate]
		  ,da.[DSLastChangeUser]
		  ,da.[DSChangeReason]
		  ,da.[ChkSum]
--V3 Start
		  ,da.[LanyonID]
--V3 End	
	FROM [DSCommonLogArchive].[dbo].[dimHotelHMFOrphanArchivePreTrip] da (NOLOCK)
	JOIN dbo.#ConflictParentkey ct
	ON da.HotelKey = ct.HotelKey
	WHERE NOT EXISTS (SELECT 1 FROM [PreTripDataMart].[dbo].[dimHotelHMF] dh (NOLOCK) 
					  WHERE dh.HotelKey = da.HotelKey);

	SET IDENTITY_INSERT [PreTripDataMart].[dbo].[dimHotelHMF] OFF;
END
--V2 End

DELETE A 
FROM PostTripDM.dbo.dimHotelHMF A  WITH (ROWLOCK)
JOIN  [PostTripDM_Stage].[dbo].[STAGE_dimHotelHMFOrphanArchive] B  (NOLOCK)
ON A.HotelID = B.HotelID 
--V2 start
WHERE NOT EXISTS (SELECt 1 FROM dbo.#ConflictParentkeyCancelledHotel ct WHERE ct.HotelKey = B.HotelKey)
AND NOT EXISTS (SELECt 1 FROM dbo.#ConflictParentkey ct1 WHERE ct1.HotelKey = B.HotelKey)
--V2 End

SELECT @RecsDeletedPostTrip = @@RowCount

TRUNCATE TABLE [PostTripDM_Stage].[dbo].[STAGE_dimHotelHMFOrphanArchive]
SET @EndDate = GETDATE()
-- Logging: PostTrip final						
EXEC DMLogs.dbo.spiuPackageExecution
	@ExecutionID = @ExecIDPostTrip,	 
	@RowCount = @RecsDeletedPostTrip,
	@EndDate = @EndDate  

-- PostTrip End 
--V2 Start
IF OBJECT_ID('tempdb.dbo.#ConflictCancelledHotel') IS NOT NULL
DROP TABLE dbo.#ConflictCancelledHotel;

IF OBJECT_ID('tempdb.dbo.#ConflictParentkey') IS NOT NULL
DROP TABLE #ConflictParentkey
--V2 End

SET @EndDate = GETDATE()
-- Logging: Loop final
	EXEC DMLogs.dbo.spiuPackageExecution 
			@ExecutionID = @ExecIDLoop,	 
			@RowCount = 0,
			@EndDate = @EndDate 

IF OBJECT_ID('tempdb.dbo.#HotelOrphanPurge') IS NOT NULL
DROP TABLE dbo.#HotelOrphanPurge;

--IF @TranCount = 0
--COMMIT
WAITFOR DELAY '00:00:02'
 ;

END TRY 
BEGIN CATCH
	--ROLLBACK 
	PRINT 'ERROR_NUMBER() = ' + CAST (ERROR_NUMBER() AS NVARCHAR(50))  
	PRINT 'ERROR_MESSAGE() = ' + ERROR_MESSAGE() 
	PRINT 'ERROR_LINE() = ' + CAST (ERROR_LINE() AS NVARCHAR(50))  

	SET @ERROR_NUMBER = ERROR_NUMBER()   
	SET @ERROR_MESSAGE = ERROR_MESSAGE() 
	SET @ERROR_LINE  = ERROR_LINE()
	SET @ERROR_STATE = ERROR_STATE()
	SET @XSTATE = XACT_STATE()
	;

    --IF @XSTATE = -1
    --    ROLLBACK;
    --IF @XSTATE = 1 AND @TranCount = 0
    --    ROLLBACK
    --IF @XSTATE = 1 AND @TranCount > 0
    --    ROLLBACK TRANSACTION DeleteHotelOrphans_Tran;


	THROW  50000
	,@ERROR_MESSAGE
	,@ERROR_STATE;
END CATCH
  
END 


GO


