--run at DBP64CLU23SQLx1

USE [ODSMasterTables]
GO

DROP PROCEDURE IF EXISTS [dbo].[spiStageODSLkupHotelBCDMaster]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
-- =============================================
-- Description:	Called by the Post trip dimHotel package
-- Change Tracking:
-- IAI 20150608 Modified to address the unmatched records that 
--			 are mapped to the Unknown BCDPropertyID.
--			 The attributes for the unmatched records will be 
--			 set based on the values in ODSLkupHotel.
-- IAI 20160331 Updated the brand data mapping
-- IAI 20160428 Modified the non-mastered logic for consistent 
--				brand name and rollupname mapping
--
--	Description: Modified the view to get CityName from vw_ODSLkupGeo (dimGeo). 
--				 Re-arranged CityName (olg.CityName, bhm.City, unkg.CityName) in COALESCE. 
--	Date: 07/14/2014 by Ankur
--	V1 - Prabhakar - on 07/19/2016 Modified the current view to show AirPortCode/CityCode from ODSLkupHotel 
--								   where BCDHotelMaster.AirportCode is blank as per DSP-1276
--	V2 - IAI	   - on 08/22/2016 Modified to get address3/city/state/country content from ODSLkupHotel 
--								   and ODSLkupGeo as necessary to fill in the missing values
--  V3 - IAI	   - on 09/27/2016 Fixed the case statement for Address3 to resolve blank values
-- V4 - 01202017 Jagdish Rathore Add GDS columns as per DSD-208
-- V5 - Ankur	   - on 04/19/2018 Modified the current view to exclude the orphan hotel records as per BCDETL-334.	 
-- =============================================
-- The comments above are from the view definition

 V1 - IAI - 20180823 - Converted the underlying code from 'vwODSLkupHotelBCDMaster' and 
				     'vwODSLkupHotelBCDMasterCheckSum' views into a stored procedure to 
				     optimize the query plan as per DN-23
 V02 - IAI - 20191025 - Modified to support delta processing (DN-1259)
 V02 - Shivanand - 20200204 -ConfDim dimHotelHMF - Delta Load Support (DN-1332) - parameterised the sproc (@LastRunDate) and 
																					Replaced the "Union" code part from V02-IAI with subsequent inserts for performance  
 V03 - SH - 20200206 - Added column LanyonID as per DN-1651
-- =============================================
*/
CREATE PROCEDURE [dbo].[spiStageODSLkupHotelBCDMaster]
@LastRunDate DATETIME --V02
AS
BEGIN

    SET NOCOUNT ON;
    SET TRAN ISOLATION LEVEL READ UNCOMMITTED;
	
	--V02  start 
	TRUNCATE TABLE ODSMasterTables_stage.dbo.TempHotelKeyDelta;
	
	-- 1. Delta based on changes in Bridge Table and BCDHotelMaster
	INSERT INTO ODSMasterTables_stage.dbo.TempHotelKeyDelta(HotelKey)
	SELECT  a.HotelKey
	FROM    dbo.ODSLkupHotel a
			JOIN dbo.ODSLkupHotelBCDMaster b ON b.HotelKey = a.HotelKey
			JOIN dbo.BCDHotelMaster c ON c.BCDPropertyId = b.BCDPropertyID
	WHERE   ( b.DSLastChangeDate >= @LastRunDate
			  OR c.DSLastChangeDate >= @LastRunDate
			)
	GROUP by  a.HotelKey;


	--2. Delta based on changes in Brand data (BCDHotelMaster.BrandCode)
	INSERT INTO ODSMasterTables_stage.dbo.TempHotelKeyDelta(HotelKey)
	SELECT  a.HotelKey
	FROM    dbo.ODSLkupHotel a
			JOIN dbo.ODSLkupHotelBCDMaster b ON b.HotelKey = a.HotelKey
			JOIN dbo.BCDHotelMaster c ON c.BCDPropertyId = b.BCDPropertyID
			JOIN dbo.ODSLkupHotelBrand d1 ON d1.HotelBrandCode = c.BrandCode
	WHERE   d1.DSLastChangeDate >= @LastRunDate
	AND		NOT EXISTS (SELECT 1 FROM ODSMasterTables_stage.dbo.TempHotelKeyDelta  T WITH (NOLOCK) WHERE T.HotelKey=a.HotelKey)
	GROUP by  a.HotelKey;

	--3. Delta based on changes in Brand data (ODSLkupHotel.HotelChainCode)
	INSERT INTO ODSMasterTables_stage.dbo.TempHotelKeyDelta(HotelKey)
	SELECT  a.HotelKey
	FROM    dbo.ODSLkupHotel a
			JOIN dbo.ODSLkupHotelBCDMaster b ON b.HotelKey = a.HotelKey
			JOIN dbo.BCDHotelMaster c ON c.BCDPropertyId = b.BCDPropertyID
			JOIN dbo.ODSLkupHotelBrand d2 ON d2.HotelBrandCode = a.HotelChainCode
	WHERE   d2.DSLastChangeDate >= @LastRunDate
	AND		NOT EXISTS (SELECT 1 FROM ODSMasterTables_stage.dbo.TempHotelKeyDelta  T WITH (NOLOCK) WHERE T.HotelKey=a.HotelKey)
	GROUP by  a.HotelKey;

	--4. Delta based on changes in City data (BCDHotelMaster.AirportCode)
	INSERT INTO ODSMasterTables_stage.dbo.TempHotelKeyDelta(HotelKey)
	SELECT  a.HotelKey
	FROM    dbo.ODSLkupHotel a
			JOIN dbo.ODSLkupHotelBCDMaster b ON b.HotelKey = a.HotelKey
			JOIN dbo.BCDHotelMaster c ON c.BCDPropertyId = b.BCDPropertyID
			JOIN ODSLkupCity e1 ON e1.CityCode = c.AirportCode
								   AND e1.TypeCode = 'O'
	WHERE   e1.UpdateDate >= @LastRunDate
	AND		NOT EXISTS (SELECT 1 FROM ODSMasterTables_stage.dbo.TempHotelKeyDelta  T WITH (NOLOCK) WHERE T.HotelKey=a.HotelKey)
	GROUP by  a.HotelKey;

	--5. Delta based on changes in City data (ODSLkupHotel.HotelCityCode)
	INSERT INTO ODSMasterTables_stage.dbo.TempHotelKeyDelta(HotelKey)
	SELECT  a.HotelKey
	FROM    dbo.ODSLkupHotel a
			JOIN dbo.ODSLkupHotelBCDMaster b ON b.HotelKey = a.HotelKey
			JOIN dbo.BCDHotelMaster c ON c.BCDPropertyId = b.BCDPropertyID
			JOIN ODSLkupCity e2 ON e2.CityCode = a.HotelCityCode
								   AND e2.TypeCode = 'O'
	WHERE   e2.UpdateDate >= @LastRunDate
	AND		NOT EXISTS (SELECT 1 FROM ODSMasterTables_stage.dbo.TempHotelKeyDelta  T WITH (NOLOCK) WHERE T.HotelKey=a.HotelKey)
	GROUP by  a.HotelKey;

	-- V02 - Code Ends
    -- =========================================================================================
    -- SQL code from vw_ODSLkupGeo
    -- 09/26/2012	NAP	Added ODSLKupStateProvince 
    -- 05/23/2013 ODSMasterTables ODScitylkup citycode dataype changed from varchar to nvarchar , however in view it is still converting varchar
    -- 7/23/2013 Prabhakar Modified the column [Description] to have length VARCHAR(30) instead of VARCHAR(10), so the desciption can not be truncated more
    -- 02/13/2014 LLH Added Description (StateFullName)
    -- =========================================================================================
    SELECT CONVERT(VARCHAR(10), cty.CityCode) AS CityCode,
           cty.TypeCode,
           cty.CityName,
           CONVERT(VARCHAR(30), COALESCE(cty.AirportName, cty.CityCode)) AS [Description],
           CONVERT(VARCHAR(10), COALESCE(cityreg.CityCode, 'ZZZ')) AS CityRegionCode,
           COALESCE(cityreg.CityName, 'Not Provided') AS CityRegionName,
           --COALESCE(cty.StateProvinceCode, '') AS [State] ,
           COALESCE(c.StateProvinceCode, '') AS [State],
           CONVERT(VARCHAR(60), COALESCE(c.Description, '')) AS [StateFullName],
           '' AS PostalCode,
           COALESCE(cty.Latitude, 0) AS Latitude,
           COALESCE(cty.Longitude, 0) AS Longitude,
           cty.TimeZoneDiff,
           cty.CountryCode,
           ctry.ISOCtryNum AS ISOCtryNum,
           ctry.CtryName AS Country,
           ctry.CurrencyCode AS DefaultCurrencyCode,
           ctry.ContinentCode AS Continent,
           reg.RegionName AS Region,
           reg.ShortRegionName,
           '1900-01-01' AS StartDate,
           '2099-12-31' AS EndDate,
           CONVERT(BIT, 1) AS CurrentRecord,
           CASE
                WHEN cty.[isMasterData] = CONVERT(BIT, 1) THEN CONVERT(BIT, 0)
                ELSE CONVERT(BIT, 1) END AS InferredMember,
           cty.[CreateDate],
           cty.[UpdateDate],
           cty.ChkSum
    INTO   #tmp_vw_ODSLkupGeo
      FROM dbo.ODSLkupCity cty
     INNER JOIN dbo.ODSLkupCountry ctry
        ON cty.CountryCode          = ctry.CtryCode
     INNER JOIN dbo.ODSLkupRegion reg
        ON cty.CountryCode          = reg.CountryCode
      LEFT JOIN dbo.ODSLkupCity cityreg
        ON (   cty.RegionCode       = cityreg.CityCode
         AND   cty.TypeCode         = cityreg.TypeCode
         AND   cityreg.isMasterData = 1)
      LEFT OUTER JOIN dbo.ODSLkupStateProvince c (NOLOCK)
        ON cty.StateProvinceCode    = c.StateProvinceCode
       AND cty.CountryCode          = c.CountryCode;


    -- IAI 20160331 Start
    SELECT CONVERT(VARCHAR(10), COALESCE(NULLIF(bhm.BrandCode, ''), unkc.HotelBrandCode)) AS ChainCode,
           CONVERT(
               VARCHAR(100), COALESCE(NULLIF(bhm.BrandRollupName, ''), NULLIF(bhm.BrandCode, ''), unkc.HotelBrandCode)) AS ChainName, -- BrandRollupName
           CONVERT(VARCHAR(100), COALESCE(NULLIF(bhm.BrandName, ''), NULLIF(bhm.BrandCode, ''), unkc.HotelBrandCode)) AS BrandName,
           -- IAI 20160331 End
           CONVERT(VARCHAR(50), COALESCE(olh.GDSHotelNumber, '')) AS GDSPropertyNumber,
           CONVERT(VARCHAR(255), COALESCE(bhm.ActualPropertyName, '')) AS PropertyName,
           CONVERT(VARCHAR(255), COALESCE(bhm.StreetAddress1, '')) AS Address1,
           CONVERT(VARCHAR(255), COALESCE(bhm.StreetAddress2, '')) AS Address2,
           -- ==================================================================================================
           -- IAI 20160822 V2 Start
           /*
            CONVERT(VARCHAR(255), CASE WHEN COALESCE(LTRIM(RTRIM(bhm.City)),
                                                     '') = ''
                                       THEN COALESCE(olg.CityName,
                                                     unkg.CityName)
                                       ELSE LTRIM(RTRIM(bhm.City))
                                  END) AS Address3 ,
            --CONVERT(VARCHAR(10), COALESCE(olg.CityCode, unkg.CityCode)) AS CityCode ,
			--Start V1
			CONVERT(VARCHAR(10), COALESCE(olg.CityCode, 
											CASE WHEN olh.HotelCityCode='' THEN NULL
											ELSE olh.HotelCityCode
											END,	
											 unkg.CityCode)) AS CityCode,
			--End V1
            CONVERT(VARCHAR(125), COALESCE(olg.CityName, bhm.City,
                                           unkg.CityName)) AS CityName ,
            CONVERT(VARCHAR(20), COALESCE(LTRIM(RTRIM(bhm.StateProvinceCode)),
                                          unkg.[State])) AS [State] ,
            CONVERT(VARCHAR(75), COALESCE(bhm.CountryName, unkg.Country)) AS Country ,
            CONVERT(VARCHAR(10), COALESCE(bhm.CountryCode2Char, unkg.Country)) AS CountryCode ,
            CONVERT(VARCHAR(25), COALESCE(bhm.PostalCode, '')) AS PostalCode ,
*/
           CONVERT(
               VARCHAR(255),
               CASE
                    WHEN (   (LTRIM(RTRIM(bhm.City)) = (CASE
                                                             WHEN ISNULL(bhm.AirportCode, '') = '' THEN
                             (CASE
                                   WHEN ISNULL(olh.HotelCityCode, '') = '' THEN unkg.CityCode
                                   ELSE olh.HotelCityCode END)
                                                             ELSE bhm.AirportCode END))
                        OR   ISNULL(LTRIM(RTRIM(bhm.City)), '') = '') THEN
               (CASE
                     WHEN ISNULL(olh.HotelCityName, '') = '' THEN
               (CASE
                     WHEN ISNULL(olg.CityName, '') = '' THEN unkg.CityName
                     ELSE olg.CityName END)
                     ELSE olh.HotelCityName END)
                    ELSE LTRIM(RTRIM(bhm.City)) END) AS Address3,
           CONVERT(
               VARCHAR(10),
               CASE
                    WHEN ISNULL(bhm.AirportCode, '') = '' THEN
               (CASE
                     WHEN ISNULL(olh.HotelCityCode, '') = '' THEN unkg.CityCode
                     ELSE olh.HotelCityCode END)
                    ELSE bhm.AirportCode END) AS CityCode,
           CONVERT(
               VARCHAR(125),
               CASE
                    WHEN ISNULL(olg.CityName, '') = '' THEN (CASE
                                                                  WHEN ISNULL(bhm.City, '') = '' THEN unkg.CityName
                                                                  ELSE bhm.City END)
                    ELSE olg.CityName END) AS CityName,
           CONVERT(
               VARCHAR(20),
               CASE
                    WHEN ISNULL(LTRIM(RTRIM(bhm.StateProvinceCode)), '') = '' THEN
               (CASE
                     WHEN ISNULL(olg.State, '') = '' THEN unkg.State
                     ELSE olg.State END)
                    ELSE LTRIM(RTRIM(bhm.StateProvinceCode)) END) AS [State],
           CONVERT(
               VARCHAR(75),
               CASE
                    WHEN ISNULL(bhm.CountryName, '') = '' THEN
               (CASE
                     WHEN ISNULL(olg.Country, '') = '' THEN
               (CASE
                     WHEN ISNULL(olh.HotelCountry, '') = '' THEN unkg.Country
                     ELSE olh.HotelCountry END)
                     ELSE olg.Country END)
                    ELSE bhm.CountryName END) AS Country,
           CONVERT(
               VARCHAR(75),
               CASE
                    WHEN ISNULL(bhm.CountryCode2Char, '') IN ( '', 'ZZ' ) THEN
               (CASE
                     WHEN ISNULL(olg.CountryCode, '') IN ( '', 'ZZ' ) THEN
               (CASE
                     WHEN ISNULL(olh.HotelCountryCode, '') IN ( '', 'ZZ' ) THEN unkg.CountryCode
                     ELSE olh.HotelCountryCode END)
                     ELSE olg.CountryCode END)
                    ELSE bhm.CountryCode2Char END) AS CountryCode,
           CONVERT(
               VARCHAR(25),
               CASE
                    WHEN ISNULL(bhm.PostalCode, '') = '' THEN
               (CASE
                     WHEN ISNULL(olh.HotelPostalCode, '') = '' THEN unkg.PostalCode
                     ELSE olh.HotelPostalCode END)
                    ELSE bhm.PostalCode END) AS PostalCode,
           -- IAI 20160822 V2 End
           -- ==================================================================================================
           CONVERT(VARCHAR(30), COALESCE(bhm.Phone, '')) AS Phone,
           BCDPropertyName,
           -- ==================================================================================================
           -- IAI 20160822 V2 Start
           /*
            StateProvinceName ,
*/
           CONVERT(
               VARCHAR(100),
               CASE
                    WHEN ISNULL(bhm.StateProvinceName, '') = '' THEN
               (CASE
                     WHEN ISNULL(olg.StateFullName, '') = '' THEN unkg.StateFullName
                     ELSE olg.StateFullName END)
                    ELSE bhm.StateProvinceName END) AS StateProvinceName,
           -- IAI 20160822 V2 End
           -- ==================================================================================================
           PropertyLatitude,
           PropertyLongitude,
           GeoResolutionCode,
           GeoResolution,
           BCDMultAptCityCode,
           BCDMultAptCityName,
           MutiAptCityCode,
           AirportLatitude,
           AirportLongitude,
           DstMiles,
           DstKm,
           PropApTyp,
           PhoneCountrycode,
           PhoneCityCode,
           PhoneExchange,
           Fax,
           FaxCountryCode,
           FaxCityCode,
           FaxExchange,
           --Start V4
           bhm.AmadeusID,
           --End v4
           AmadeusBrandCode,
           --Start V4
           bhm.WorldSpanID,
           --End v4
           WorldSpanBrandCode,
           --Start V4
           bhm.SabreID,
           --End v4
           SabreBrandCode,
           --Start V4
           bhm.ApolloID,
           --End v4
           ApolloBrandCode,
           MarketTier,
           ServiceLevel,
           bhm.BCDPropertyId,
           CONVERT(DATETIME, '1900-01-01') AS StartDate,
           CONVERT(DATETIME, '2099-12-31') AS EndDate,
           CONVERT(BIT, 1) AS CurrentRecord,
           CASE
                WHEN olh.isMasterData = CONVERT(BIT, 1) THEN CONVERT(BIT, 0)
                ELSE CONVERT(BIT, 1) END AS InferredMember,
           CONVERT(VARCHAR(20), olh.HotelID) AS HotelID,
           olh.colCheckSum AS ChkSum,
		   --Start V03
		   bhm.LanyonID
		   --End V03
    INTO   #tmp_HotelResults
      FROM dbo.ODSLkupHotel olh WITH (NOLOCK)
	  -- Start of V02
	  /*-- Start of V02
	  JOIN #TempHotelKeyDelta  t ON t.HotelKey = olh.HotelKey
	  -- End of V02
	  */
	  JOIN ODSMasterTables_stage.dbo.TempHotelKeyDelta  t WITH (NOLOCK) ON t.HotelKey = olh.HotelKey
		-- End of V02
      JOIN dbo.ODSLkupHotelBCDMaster brdg WITH (NOLOCK)
        ON olh.HotelKey                        = brdg.HotelKey
      JOIN dbo.BCDHotelMaster bhm WITH (NOLOCK)
        ON brdg.BCDPropertyID                  = bhm.BCDPropertyId
      JOIN dbo.ODSLkupHotelBrand unkc WITH (NOLOCK)
        ON (unkc.HotelBrandCode = N'Unknown') -- IAI 20160331
      -- IAI 20160822 V2 Start
      /*
            LEFT JOIN dbo.vw_ODSLkupGeo olg WITH ( NOLOCK ) ON ( bhm.AirportCode = olg.CityCode
                                                              AND olg.TypeCode = 'O'
                                                              )
*/
      LEFT JOIN #tmp_vw_ODSLkupGeo olg -- dbo.vw_ODSLkupGeo olg WITH (NOLOCK)
        ON (   (CASE
                     WHEN ISNULL(bhm.AirportCode, '') = '' THEN olh.HotelCityCode
                     ELSE bhm.AirportCode END) = olg.CityCode
         AND   olg.TypeCode                    = 'O')
      -- IAI 20160822 V2 End
      JOIN #tmp_vw_ODSLkupGeo unkg -- dbo.vw_ODSLkupGeo unkg WITH (NOLOCK)
        ON (   unkg.CityCode                   = 'ZZZ'
         AND   unkg.TypeCode                   = 'O')
     WHERE brdg.BCDPropertyID > 1;


    -- Address the unmatched hotel records
    -- IAI 20160331 Start
    WITH Brand_CTE
      AS (
         -- IAI 20160428 Start
         SELECT b1.HotelBrandCode AS BrandCode,
                HotelBrandName AS BrandName,
                HotelBrandRollupName AS BrandRollupName
           FROM dbo.ODSLkupHotelBrand b1 WITH (NOLOCK)
           JOIN (   SELECT HotelBrandCode,
                           MIN(HotelBrandKey) AS HotelBrandKey
                      FROM dbo.ODSLkupHotelBrand WITH (NOLOCK)
                     GROUP BY HotelBrandCode) b2
             ON b1.HotelBrandKey = b2.HotelBrandKey
    -- IAI 20160428 End
    )
    INSERT INTO #tmp_HotelResults
    SELECT CONVERT(VARCHAR(10), COALESCE(NULLIF(bhm.BrandCode, ''), unkc.HotelBrandCode)) AS ChainCode,
           CONVERT(
               VARCHAR(100), COALESCE(NULLIF(bhm.BrandRollupName, ''), NULLIF(bhm.BrandCode, ''), unkc.HotelBrandCode)) AS ChainName, -- BrandRollupName
           CONVERT(VARCHAR(100), COALESCE(NULLIF(bhm.BrandName, ''), NULLIF(bhm.BrandCode, ''), unkc.HotelBrandCode)) AS BrandName,
           -- IAI 20160331 End
           CONVERT(VARCHAR(50), COALESCE(olh.GDSHotelNumber, '')) AS GDSPropertyNumber,
           CONVERT(VARCHAR(255), COALESCE(olh.HotelName, '')) AS PropertyName,
           CONVERT(VARCHAR(255), COALESCE(olh.HotelAddr1, '')) AS Address1,
           CONVERT(VARCHAR(255), COALESCE(olh.HotelAddr2, '')) AS Address2,
           -- ==================================================================================================
           -- IAI 20160822 V2 Start
           /*
            CONVERT(VARCHAR(255), CASE WHEN COALESCE(LTRIM(RTRIM(olh.HotelCityName)),
                                                     '') = ''
                                       THEN COALESCE(olg.CityName,
                                                     unkg.CityName)
                                       ELSE LTRIM(RTRIM(olh.HotelCityName))
                                  END) AS Address3 ,
            CONVERT(VARCHAR(10), COALESCE(olg.CityCode, unkg.CityCode)) AS CityCode ,
            CONVERT(VARCHAR(100), COALESCE(olg.CityName, unkg.CityName)) AS CityName ,
            CONVERT(VARCHAR(20), COALESCE(LTRIM(RTRIM(olh.HotelState)),
                                          unkg.[State])) AS [State] ,
            CONVERT(VARCHAR(75), COALESCE(olh.HotelCountry, unkg.Country)) AS Country ,
            CONVERT(VARCHAR(10), COALESCE(olh.HotelCountryCode, unkg.Country)) AS CountryCode ,
            CONVERT(VARCHAR(15), COALESCE(olh.HotelPostalCode, '')) AS PostalCode ,
*/
           CONVERT(
               VARCHAR(255),
               CASE
                    WHEN (   ISNULL(LTRIM(RTRIM(olh.HotelCityName)), '') = (CASE
                                                                                 WHEN ISNULL(olg.CityCode, '') = '' THEN
                                                                                     unkg.CityCode
                                                                                 ELSE olh.HotelCityCode END)
                        OR   ISNULL(LTRIM(RTRIM(olh.HotelCityName)), '') = '') THEN
               (CASE
                     WHEN ISNULL(olg.CityName, '') = '' THEN unkg.CityName
                     ELSE olg.CityName END)
                    ELSE LTRIM(RTRIM(olh.HotelCityName)) END) AS Address3,
           CONVERT(VARCHAR(10),
                   CASE
                        WHEN ISNULL(olg.CityCode, '') = '' THEN unkg.CityCode
                        ELSE olh.HotelCityCode END) AS CityCode,
           CONVERT(VARCHAR(100),
                   CASE
                        WHEN ISNULL(olg.CityName, '') = '' THEN unkg.CityName
                        ELSE olg.CityName END) AS CityName,
           CONVERT(
               VARCHAR(20),
               CASE
                    WHEN ISNULL(olg.State, '') = '' THEN
               (CASE
                     WHEN ISNULL(LTRIM(RTRIM(olh.HotelState)), '') = '' THEN unkg.[State]
                     ELSE LTRIM(RTRIM(olh.HotelState)) END)
                    ELSE olg.State END) AS [State],
           CONVERT(
               VARCHAR(75),
               CASE
                    WHEN ISNULL(olg.Country, '') = '' THEN
               (CASE
                     WHEN ISNULL(olh.HotelCountry, '') = '' THEN unkg.Country
                     ELSE olh.HotelCountry END)
                    ELSE olg.Country END) AS Country,
           CONVERT(
               VARCHAR(75),
               CASE
                    WHEN ISNULL(olg.CountryCode, '') IN ( '', 'ZZ' ) THEN
               (CASE
                     WHEN ISNULL(olh.HotelCountryCode, '') IN ( '', 'ZZ' ) THEN unkg.CountryCode
                     ELSE olh.HotelCountryCode END)
                    ELSE olg.CountryCode END) AS CountryCode,
           CONVERT(VARCHAR(15),
                   CASE
                        WHEN ISNULL(olh.HotelPostalCode, '') = '' THEN unkg.PostalCode
                        ELSE olh.HotelPostalCode END) AS PostalCode,
           -- IAI 20160822 V2 End
           -- ==================================================================================================
           CONVERT(VARCHAR(20), COALESCE(olh.HotelPhoneNumber, '')) AS Phone,
           NULL AS BCDPropertyName,
           -- ==================================================================================================
           -- IAI 20160822 V2 Start
           /*
            NULL AS StateProvinceName ,
*/
           CONVERT(VARCHAR(100),
                   CASE
                        WHEN ISNULL(olg.StateFullName, '') = '' THEN unkg.StateFullName
                        ELSE olg.StateFullName END) AS StateProvinceName,
           -- IAI 20160822 V2 End
           -- ==================================================================================================
           NULL AS PropertyLatitude,
           NULL AS PropertyLongitude,
           NULL AS GeoResolutionCode,
           NULL AS GeoResolution,
           NULL AS BCDMultAptCityCode,
           NULL AS BCDMultAptCityName,
           NULL AS MutiAptCityCode,
           NULL AS AirportLatitude,
           NULL AS AirportLongitude,
           NULL AS DstMiles,
           NULL AS DstKm,
           NULL AS PropApTyp,
           NULL AS PhoneCountryCode,
           NULL AS PhoneCityCode,
           NULL AS PhoneExchange,
           NULL AS Fax,
           NULL AS FaxCountryCode,
           NULL AS FaxCityCode,
           NULL AS FaxExchange,
           --Start V4
           --NULL AS AmadeusID
           CASE
                WHEN olh.CRSCode = 'A' THEN olh.GDSCodeFormatted END AS AmadeusID,
           --End v4
           NULL AS AmadeusBrandCode,
           --Start V4
           --NULL  AS WorldSpanID
           CASE
                WHEN olh.CRSCode = 'W' THEN olh.GDSCodeFormatted END AS WorldSpanID,
           --End v4
           NULL AS WorldSpanBrandCode,
           --Start V4
           --NULL AS SabreID 
           CASE
                WHEN olh.CRSCode = 'S' THEN olh.GDSCodeFormatted END AS SabreID,
           --End v4
           NULL AS SabreBrandCode,
           --Start V4
           --NULL AS ApolloID
           CASE
                WHEN olh.CRSCode = 'P' THEN olh.GDSCodeFormatted END AS ApolloID,
           --END V4
           NULL AS ApolloBrandCode,
           NULL AS MarketTier,
           NULL AS ServiceLevel,
           brdg.BCDPropertyID,
           CONVERT(DATETIME, '1900-01-01') AS StartDate,
           CONVERT(DATETIME, '2099-12-31') AS EndDate,
           CONVERT(BIT, 1) AS CurrentRecord,
           CASE
                WHEN olh.isMasterData = CONVERT(BIT, 1) THEN CONVERT(BIT, 0)
                ELSE CONVERT(BIT, 1) END AS InferredMember,
           CONVERT(VARCHAR(20), olh.HotelID) AS HotelID,
           olh.colCheckSum AS ChkSum,
		   --Start V03
		   NULL AS LanyonID
		   --End V03
      FROM dbo.ODSLkupHotel olh WITH (NOLOCK)
	  -- Start of V02
	  /*-- Start of V02
	  JOIN #TempHotelKeyDelta  t ON t.HotelKey = olh.HotelKey
	  -- End of V02
	  */
	  JOIN ODSMasterTables_stage.dbo.TempHotelKeyDelta  t WITH (NOLOCK) ON t.HotelKey = olh.HotelKey
	  -- End of V02
      JOIN dbo.ODSLkupHotelBCDMaster brdg WITH (NOLOCK)
        ON olh.HotelKey          = brdg.HotelKey
      LEFT JOIN Brand_CTE bhm
        ON olh.HotelChainCode    = bhm.BrandCode
      JOIN dbo.ODSLkupHotelBrand unkc WITH (NOLOCK)
        ON unkc.HotelBrandCode   = N'Unknown' -- IAI 20160331
      LEFT JOIN dbo.vw_ODSLkupGeo olg WITH (NOLOCK)
        ON (   olh.HotelCityCode = olg.CityCode
         AND   olg.TypeCode      = 'O')
      JOIN dbo.vw_ODSLkupGeo unkg WITH (NOLOCK)
        ON (   unkg.CityCode     = 'ZZZ'
         AND   unkg.TypeCode     = 'O')
     --LEFT JOIN ODSMasterTables_Stage.[dbo].[TempConfDimHotelOrphan] o WITH (NOLOCK)
     --ON o.HotelKeyODS = olh.HotelKey
     WHERE brdg.BCDPropertyID = 1
       --AND o.HotelID IS NULL
       --V5 Start
       AND NOT EXISTS (   SELECT 1
                            FROM ODSMasterTables_Stage.[dbo].[TempConfDimHotelOrphan] o 
                           WHERE o.HotelKeyODS = olh.HotelKey);
    --V5 End


    INSERT INTO ODSMasterTables_Stage.dbo.StageODSLkupHotelBCDMaster
	
	SELECT [ChainCode],
           [ChainName],
           [GDSPropertyNumber],
           [PropertyName],
           [Address1],
           [Address2],
           [Address3],
           [CityCode],
           [CityName],
           [State],
           [PostalCode],
           [Country],
           [CountryCode],
           [Phone],
           [HotelID],
           [BCDPropertyName],
           [StateProvinceName],
           [PropertyLatitude],
           [PropertyLongitude],
           [GeoResolutionCode],
           [GeoResolution],
           [BCDMultAptCityCode],
           [BCDMultAptCityName],
           [MutiAptCityCode],
           [AirportLatitude],
           [AirportLongitude],
           [DstMiles],
           [DstKm],
           [PropApTyp],
           [PhoneCountryCode],
           [PhoneCityCode],
           [PhoneExchange],
           [Fax],
           [FaxCountryCode],
           [FaxCityCode],
           [FaxExchange],
           [AmadeusID],
           [AmadeusBrandCode],
           [WorldSpanID],
           [WorldSpanBrandCode],
           [SabreID],
           [SabreBrandCode],
           [ApolloID],
           [ApolloBrandCode],
           [MarketTier],
           [ServiceLevel],
           [BCDPropertyID],
           [BrandName],
		   [ChkSum],
		   --Start V03
		   [LanyonID]
		   --End V03
		   FROM
				(
					   SELECT
					   [ChainCode],
					   [ChainName],
					   [GDSPropertyNumber],
					   [PropertyName],
					   [Address1],
					   [Address2],
					   [Address3],
					   [CityCode],
					   [CityName],
					   [State],
					   [PostalCode],
					   [Country],
					   [CountryCode],
					   [Phone],
					   [HotelID],
					   [BCDPropertyName],
					   [StateProvinceName],
					   [PropertyLatitude],
					   [PropertyLongitude],
					   [GeoResolutionCode],
					   [GeoResolution],
					   [BCDMultAptCityCode],
					   [BCDMultAptCityName],
					   [MutiAptCityCode],
					   [AirportLatitude],
					   [AirportLongitude],
					   [DstMiles],
					   [DstKm],
					   [PropApTyp],
					   [PhoneCountryCode],
					   [PhoneCityCode],
					   [PhoneExchange],
					   [Fax],
					   [FaxCountryCode],
					   [FaxCityCode],
					   [FaxExchange],
					   [AmadeusID],
					   [AmadeusBrandCode],
					   [WorldSpanID],
					   [WorldSpanBrandCode],
					   [SabreID],
					   [SabreBrandCode],
					   [ApolloID],
					   [ApolloBrandCode],
					   [MarketTier],
					   [ServiceLevel],
					   [BCDPropertyID],
					   [BrandName], -- AA 20160331 Added new column as per DS-1211
					   CHECKSUM(
						   [ChainCode],
						   --[ChainName],
						   [BrandName], -- AA 20160331 Added new column as per DS-1211
						   [GDSPropertyNumber],
						   [PropertyName],
						   [Address1],
						   [Address2],
						   [Address3],
						   [CityCode],
						   [CityName],
						   [State],
						   [Country],
						   [CountryCode],
						   [PostalCode],
						   [Phone],
						   [BCDPropertyName],
						   [StateProvinceName],
						   [PropertyLatitude],
						   [PropertyLongitude],
						   [GeoResolutionCode],
						   [GeoResolution],
						   [BCDMultAptCityCode],
						   [BCDMultAptCityName],
						   [MutiAptCityCode],
						   [AirportLatitude],
						   [AirportLongitude],
						   [DstMiles],
						   [DstKm],
						   [PropApTyp],
						   [PhoneCountryCode],
						   [PhoneCityCode],
						   [PhoneExchange],
						   [Fax],
						   [FaxCountryCode],
						   [FaxCityCode],
						   [FaxExchange],
						   [AmadeusID],
						   [AmadeusBrandCode],
						   [WorldSpanID],
						   [WorldSpanBrandCode],
						   [SabreID],
						   [SabreBrandCode],
						   [ApolloID],
						   [ApolloBrandCode],
						   [MarketTier],
						   [ServiceLevel],
						   [BCDPropertyID],
						   [StartDate],
						   [EndDate],
						   [CurrentRecord],
						   [InferredMember],
							--Start V03
							[LanyonID]
							--End V03
						   ) AS [ChkSum],
							--Start V03
							LanyonID
							--End V03
						   ,ROW_NUMBER() OVER ( PARTITION BY HotelID ORDER BY HotelID) AS HotelID_Rank
				  FROM #tmp_HotelResults 
				  ) X
				  WHERE X.HotelID_Rank=1
	  
	  ;

    DROP TABLE #tmp_HotelResults;
    DROP TABLE #tmp_vw_ODSLkupGeo;

END;


GO


