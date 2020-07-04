--run at DBP64CLU23SQLx1
USE [ODSMasterTables_Stage]
GO

DROP PROCEDURE [dbo].[spgHMFSQL]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[spgHMFSQL]  
@LastRunDate DATETIME, @APICounter INT
AS   
  
/*  
	Stored Procedure: dbo.spgHMFSQL   
	Purpose: Prepare the inline sql to get the hotel data from EDM source AS per DN-1282.      
	Caller:  SSIS Package - EDMHMFWeeklyLoad.dtsx (EDMHMFWeeklyLoad)  
  
	Version  Updated By		Updated Date   Description  
	-------- -----------   -------------   ------------------------  
	V1   Ankur Adarsh		2-5-2020		Create  
	V2   SHARE				2-6-2020		Added column LanyonID as per DN-1651    
  
*/  
BEGIN  
	SET NOCOUNT ON;  
   
	DECLARE @SQL NVARCHAR(4000);  
 
	SELECT @LastRunDate = ISNULL
						(
							MAX(UpdateDt),
											(SELECT LastPull from ODSMasterTables.dbo.lastpulldate (NOLOCK) WHERE TableType='EDMHMFWeeklyLoad')
						) 
	FROM ODSMasterTables_Stage.dbo.ODSImportBCDHotelMaster (NOLOCK)
			 
	 SET @SQL =N''  
	 SELECT  @SQL = @SQL + 'SELECT   BCDPropertyId
				,CAST(COALESCE(BrandName, '''') AS varchar(50)) AS BrandName
				,CAST(COALESCE(BrandCode, ''ZZ'') AS varchar(2)) AS BrandCode
				,CAST(COALESCE(MasterChainName, '''') AS varchar(50)) AS MasterChainName
				,CAST(COALESCE(MasterChainCode, ''ZZ'') AS varchar(2)) AS MasterChainCode
				,CAST(COALESCE(LTRIM(RTRIM(ActualPropertyName)), '''') AS varchar(100)) AS ActualPropertyName
				,CAST(BCDPropertyName AS varchar(100)) AS BCDPropertyName
				,CAST(COALESCE(StreetAddress1, '''') AS varchar(100)) AS StreetAddress1
				,CAST(StreetAddress2 AS varchar(100)) AS StreetAddress2
				,CAST(COALESCE(City, '''') AS varchar(125)) AS City
				,CAST(StateProvinceName AS varchar(100)) AS StateProvinceName
				,CAST(COALESCE(StateProvinceCode, ''ZZ'') AS varchar(6)) AS StateProvinceCode
				,CAST(COALESCE(PostalCode, ''0000'') AS varchar(25)) AS PostalCode
				,CAST(PostalCodeLast4 AS varchar(10)) AS PostalCodeLast4
				,CAST(COALESCE(CountryName, '''') AS varchar(100)) AS CountryName
				,CAST(COALESCE(CountryCode2Char, ''ZZ'') AS varchar(02)) AS CountryCode2Char
				,CAST(CountryCode3Char AS varchar(03)) AS CountryCode3Char
				,CountryCodeDigit
				,PropertyLatitude
				,PropertyLongitude
				,CAST(GeoResolutionCode AS varchar(25)) AS GeoResolutionCode
				,CAST(GeoResolution AS varchar(100)) AS GeoResolution
				,CAST(COALESCE(AirportCode, ''ZZZ'') AS varchar(3)) AS AirportCode
				,CAST(bcdmultiairportcitycode AS varchar(3)) AS bcdmultiairportcitycode
				,CAST(bcdmultiairportcityname AS varchar(50)) AS bcdmultiairportcityname
				,CAST(multiairportcitycode AS varchar(3)) AS multiairportcitycode
				,airportlatitude AS airportlatitude 
				,airportlongitude AS airportlongitude
				,distancemiles AS distancemiles
				,distancekm
				,CAST(propertytype AS varchar(15)) AS propertytype
				,CAST(Phone AS varchar(30)) AS Phone
				,PhoneCountrycode
				,PhoneCityCode 
				,CAST(PhoneExchange AS varchar(25)) AS PhoneExchange
				,CAST(Fax AS varchar(30)) AS Fax
				,FaxCountryCode
				,FaxCityCode 
				,CAST(FaxExchange AS varchar(25)) AS FaxExchange
				,CAST(AmadeusID AS varchar(15)) AS AmadeusID
				,CAST(AmadeusBrandCode AS varchar(2)) AS AmadeusBrandCode
				,CAST(WorldSpanID AS varchar(15)) AS WorldSpanID
				,CAST(WorldSpanBrandCode AS varchar(2)) AS WorldSpanBrandCode
				,CAST(SabreID AS varchar(15)) AS SabreID
				,CAST(SabreBrandCode AS varchar(2)) AS SabreBrandCode
				,CAST(ApolloID AS varchar(15)) AS ApolloID
				,CAST(ApolloBrandCode AS varchar(2)) AS ApolloBrandCode
				,CAST(MarketTier AS varchar(20)) AS MarketTier
				,CAST(ServiceLevel AS varchar(20)) AS ServiceLevel
				,updatedate AS UpdateDt
				,CAST(COALESCE(Alternatebrandname, '''') AS varchar(100)) AS BrandRollupName 
				,CAST(LanyonID AS varchar(15)) AS LanyonID
		FROM bcdtravelselfservice.hotelproperty
		WHERE updatedate >= '''+CONVERT(VARCHAR(50),@LastRunDate,121)+ '''   
		ORDER BY  UPDATEDATE ASC
		LIMIT '+CONVERT(VARCHAR(50),@APICounter)+ ' 
		
		'  
  
	 SELECT  @SQL AS HMFSQL  
END  
  
  
GO


