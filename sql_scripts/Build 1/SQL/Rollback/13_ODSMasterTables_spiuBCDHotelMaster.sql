--run at DBP64CLU23SQLx1

USE [ODSMasterTables]
GO

/****** Object:  StoredProcedure [dbo].[spiuBCDHotelMaster]    Script Date: 2/7/2020 4:44:32 PM ******/
DROP PROCEDURE [dbo].[spiuBCDHotelMaster]
GO

/****** Object:  StoredProcedure [dbo].[spiuBCDHotelMaster]    Script Date: 2/7/2020 4:44:32 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[spiuBCDHotelMaster]
AS
/* 
 ===============================================================================================================  
  spiuBCDHotelMaster  
  Author: Subrat Shashank   
  Create date: 01/09/2015  
  Description: Updates or inserts records   
     into the BCDHotelMaster table 
 Modified: By Ankur on 05-Oct-2015 Added ETL tracking column - DSP-290
 Modified: By Ankur on 03-Feb-2016 Added New column BrandRollupName - DS-1211
 Modified: By Ankur on 16-Jun-2017 To Handle Carriage Return Issue - DSD-870

Version		Updated By			Updated Date			Description
--------	-----------			-------------			------------------------
V1			Ankur Adarsh		12-26-2017				Added ROWLOCK on BCDHotelMaster while insert/update as per DSD-1110 
 ================================================================================================================  
*/ 
 
BEGIN

    SET NOCOUNT ON ;

	DECLARE @RC INT
 -- Start DSD-870
		EXEC [ODSMasterTables_Stage].[dbo].[spuBCDHotelMaster_ASCIICharacters] -- DSD-870
 -- End DSD-870


		UPDATE  h1
		SET     BrandName = h2.BrandName,
				BrandCode = h2.BrandCode,
				MasterChainName = h2.MasterChainName,
				MasterChainCode = h2.MasterChainCode,
				ActualPropertyName = h2.ActualPropertyName,
				BcdPropertyName = h2.BcdPropertyName,
				StreetAddress1 = h2.StreetAddress1,
				StreetAddress2 = h2.StreetAddress2,
				City = h2.City,
				StateProvinceName = h2.StateProvinceName,
				StateProvinceCode = h2.StateProvinceCode,
				PostalCode = h2.PostalCode,
				PostalCodeLast4  = h2.PostalCodeLast4,
				CountryName = h2.CountryName,
				CountryCode2Char = h2.CountryCode2Char,
				CountryCode3Char = h2.CountryCode3Char,
				CountryCodeDigit = h2.CountryCodeDigit,
				PropertyLatitude = h2.PropertyLatitude,
				PropertyLongitude = h2.PropertyLongitude,
				GeoResolutionCode = h2.GeoResolutionCode,
				GeoResolution = h2.GeoResolution,
				AirportCode = h2.AirportCode,
				BCDMultAptCityCode = h2.BCDMultAptCityCode,
				BCDMultAptCityName = h2.BCDMultAptCityName,
				MutiAptCityCode = h2.MutiAptCityCode,
				AirportLatitude = h2.AirportLatitude,
				AirportLongitude = h2.AirportLongitude,
				DstMiles = h2.DstMiles,
				DstKm = h2.DstKm,
				PropApTyp = h2.PropApTyp,
				Phone = h2.Phone,
				PhoneCountryCode = h2.PhoneCountryCode,
				PhoneCityCode = h2.PhoneCityCode,
				PhoneExchange = h2.PhoneExchange,
				Fax = h2.Fax,
				FaxCountryCode = h2.FaxCountryCode,
				FaxCityCode = h2.FaxCityCode,
				FaxExchange = h2.FaxExchange,
				AmadeusId = h2.AmadeusId,
				AmadeusBrandCode = h2.AmadeusBrandCode,
				WorldspanId = h2.WorldspanId,
				WorldspanBrandCode = h2.WorldspanBrandCode,
				SabreId = h2.SabreId,
				SabreBrandCode = h2.SabreBrandCode,
				ApolloId = h2.ApolloId,
				ApolloBrandCode  = h2.ApolloBrandCode,
				MarketTier  = h2.MarketTier,
				ServiceLevel = h2.ServiceLevel,
				UpdateDt = h2.UpdateDt,
				DSChangeReason= 'PKG-UPDATE',
				DSLastChangeDate = GETDATE(),
				DSLastChangeUser = 'PKG - EDMHMFWeeklyLoad',
				BrandRollupName = h2.BrandRollupName --By Ankur on 03-Feb-2016 Added New column BrandRollupName DS-1211
		FROM    BCDHotelMaster h1 WITH (ROWLOCK) -- V1
		INNER JOIN ODSMasterTables_Stage.dbo.ODSImportBCDHotelMaster h2
		ON    h1.BCDPropertyId = h2.BCDPropertyId
		--WHERE h2.Updated = 1
		WHERE h1.UpdateDt <> h2.UpdateDt

    SET @RC = @@RowCount  
  
		INSERT  INTO dbo.BCDHotelMaster WITH (ROWLOCK) -- V1
		(
				BCDPropertyId  ,
				BrandName ,
				BrandCode ,
				MasterChainName ,
				MasterChainCode ,
				ActualPropertyName ,
				BcdPropertyName ,
				StreetAddress1 ,
				StreetAddress2 ,
				City ,
				StateProvinceName ,
				StateProvinceCode ,
				PostalCode ,
				PostalCodeLast4  ,
				CountryName ,
				CountryCode2Char ,
				CountryCode3Char ,
				CountryCodeDigit ,
				PropertyLatitude ,
				PropertyLongitude ,
				GeoResolutionCode ,
				GeoResolution ,
				AirportCode ,
				BCDMultAptCityCode ,
				BCDMultAptCityName ,
				MutiAptCityCode ,
				AirportLatitude ,
				AirportLongitude ,
				DstMiles ,
				DstKm ,
				PropApTyp ,
				Phone ,
				PhoneCountryCode ,
				PhoneCityCode ,
				PhoneExchange ,
				Fax ,
				FaxCountryCode ,
				FaxCityCode ,
				FaxExchange ,
				AmadeusId ,
				AmadeusBrandCode ,
				WorldspanId ,
				WorldspanBrandCode ,
				SabreId ,
				SabreBrandCode ,
				ApolloId ,
				ApolloBrandCode  ,
				MarketTier  ,
				ServiceLevel ,
				UpdateDt,
				BrandRollupName --By Ankur on 03-Feb-2016 Added New column BrandRollupName DS-1211
		)
		SELECT  BCDPropertyId  ,
				BrandName ,
				BrandCode ,
				MasterChainName ,
				MasterChainCode ,
				ActualPropertyName ,
				BcdPropertyName ,
				StreetAddress1 ,
				StreetAddress2 ,
				City ,
				StateProvinceName ,
				StateProvinceCode ,
				PostalCode ,
				PostalCodeLast4  ,
				CountryName ,
				CountryCode2Char ,
				CountryCode3Char ,
				CountryCodeDigit ,
				PropertyLatitude ,
				PropertyLongitude ,
				GeoResolutionCode ,
				GeoResolution ,
				AirportCode ,
				BCDMultAptCityCode ,
				BCDMultAptCityName ,
				MutiAptCityCode ,
				AirportLatitude ,
				AirportLongitude ,
				DstMiles ,
				DstKm ,
				PropApTyp ,
				Phone ,
				PhoneCountryCode ,
				PhoneCityCode ,
				PhoneExchange ,
				Fax ,
				FaxCountryCode ,
				FaxCityCode ,
				FaxExchange ,
				AmadeusId ,
				AmadeusBrandCode ,
				WorldspanId ,
				WorldspanBrandCode ,
				SabreId ,
				SabreBrandCode ,
				ApolloId ,
				ApolloBrandCode  ,
				MarketTier  ,
				ServiceLevel ,
				UpdateDt,
				BrandRollupName --By Ankur on 03-Feb-2016 Added New column BrandRollupName DS-1211
		FROM    ODSMasterTables_Stage.dbo.ODSImportBCDHotelMaster h1 ( NOLOCK )
		WHERE   NOT EXISTS ( SELECT 1
								FROM   dbo.BCDHotelMaster h2 ( NOLOCK )
								WHERE  h1.BCDPropertyId = h2.BCDPropertyId )  
  
  
    SET @RC = @RC + @@RowCount  
  
    SELECT  @RC AS RowCnt  
  

    END


GO


