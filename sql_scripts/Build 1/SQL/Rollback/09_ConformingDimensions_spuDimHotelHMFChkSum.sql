--run at DBP64CLU23SQLx2
USE [ConformingDimensions]
GO

/****** Object:  StoredProcedure [dbo].[spuDimHotelHMFChkSum]    Script Date: 2/7/2020 1:57:58 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[spuDimHotelHMFChkSum]
GO

/****** Object:  StoredProcedure [dbo].[spuDimHotelHMFChkSum]    Script Date: 2/7/2020 1:57:58 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*
-- ===============================================================================================================  
--  spuDimHotelHMFChkSum  
Created By: Ankur Adarsh
Created On: 09-Sep-2016
Description: Updated the column Chksum at dbo.Temp_dimHotelHMF in a batch by using HashBytes logic .

-- ================================================================================================================  
*/  
  
  
CREATE PROCEDURE [dbo].[spuDimHotelHMFChkSum]
AS 
BEGIN
	
UPDATE  tdh
--SET		tdh.[ChkSum] = HASHBYTES('SHA1',
--		ISNULL([ChainCode],'') + ISNULL([ChainName],'') + ISNULL([GDSPropertyNumber],'') + 
--		ISNULL(CONVERT(VARCHAR(6),[GeoKey]),'') + ISNULL([PropertyName],'') + ISNULL([Address1],'') +	
--		ISNULL([Address2],'') + ISNULL([Address3],'') + ISNULL([CityCode],'') + ISNULL([CityName],'') + 
--		ISNULL([State],'') + ISNULL([PostalCode],'') + ISNULL([Country],'') + ISNULL([CountryCode],'') + 
--		ISNULL([Phone],'') + ISNULL([HotelID],'') + ISNULL([BCDPropertyName],'') + ISNULL([StateProvinceName],'') + 
--		ISNULL(CONVERT(VARCHAR(20),[PropertyLatitude]),'') + ISNULL(CONVERT(VARCHAR(13),[PropertyLongitude]),'') + 
--		ISNULL([GeoResolutionCode],'') + ISNULL([GeoResolution],'') + ISNULL([BCDMultAptCityCode],'') + 
--		ISNULL([BCDMultAptCityName],'') + ISNULL([MutiAptCityCode],'') + ISNULL(CONVERT(VARCHAR(12),[AirportLatitude]),'') + 
--		ISNULL(CONVERT(VARCHAR(13),[AirportLongitude]),'') + ISNULL(CONVERT(VARCHAR(8),[DstMiles]),'') +  
--		ISNULL(CONVERT(VARCHAR(8),[DstKm]),'') + ISNULL([PropApTyp],'') + ISNULL(CONVERT(VARCHAR(6),[PhoneCountryCode]),'') + 
--		ISNULL(CONVERT(VARCHAR(5),[PhoneCityCode]),'') + ISNULL([PhoneExchange],'') + ISNULL(CONVERT(VARCHAR(18),[Fax]),'') +
--		ISNULL(CONVERT(VARCHAR(3),[FaxCountryCode]),'') + ISNULL(CONVERT(VARCHAR(5),[FaxCityCode]),'') + 
--		ISNULL([FaxExchange],'') + ISNULL([AmadeusID],'') + ISNULL([AmadeusBrandCode],'') + ISNULL([WorldSpanID],'') + 
--		ISNULL([WorldSpanBrandCode],'') + ISNULL([SabreID],'') + ISNULL([SabreBrandCode],'') + ISNULL([ApolloID],'') + 
--		ISNULL([ApolloBrandCode],'') + ISNULL([MarketTier],'') + ISNULL([ServiceLevel],'') + 
--		ISNULL(CONVERT(VARCHAR(8),[BCDPropertyID]),'') + ISNULL([BrandName],'')
--		)
  SET	tdh.[ChkSum] = HASHBYTES('MD5',
						(SELECT ChainCode, ChainName, GDSPropertyNumber, PropertyName, Address1, Address2, Address3, CityCode, CityName, State, Country, CountryCode, PostalCode, Phone, BCDPropertyName, StateProvinceName, PropertyLatitude, PropertyLongitude, GeoResolutionCode, GeoResolution, BCDMultAptCityCode, BCDMultAptCityName, MutiAptCityCode, AirportLatitude, AirportLongitude, DstMiles, DstKm, PropApTyp, PhoneCountryCode, PhoneCityCode, PhoneExchange, Fax, FaxCountryCode, FaxCityCode, FaxExchange, AmadeusID, AmadeusBrandCode, WorldSpanID, WorldSpanBrandCode, SabreID, SabreBrandCode, ApolloID, ApolloBrandCode, MarketTier, ServiceLevel, BCDPropertyID, BrandName  FOR XML RAW
						))
FROM	dbo.Temp_dimHotelHMF tdh


END


GO


