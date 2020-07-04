--run at DBP64CLU23SQLx2
USE [PreTripDataMart]
GO

/****** Object:  StoredProcedure [dbo].[spiuDimHotel]    Script Date: 2/7/2020 2:40:42 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[spiuDimHotel]
GO

/****** Object:  StoredProcedure [dbo].[spiuDimHotel]    Script Date: 2/7/2020 2:40:42 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[spiuDimHotel]
AS 
/*  
 =============================================
  spiuDimHotel
  Author:			Jagdish Rathore
  Create date:	12/10/2015
  Description:	 Modified to upsert from ConformingDimension.dbo.dimHotelHMF
  Modified By: V1 Ankur Adarsh on 03/17/2016 - Added EndDate, CurrentRecord  in the Update logic as DS-873.
  Ankur Adarsh		05/18/2016  Rearrange the upsert process (Insert followed by Update statement).
  Ankur Adarsh		12/08/2016  Modified the sproc to replace the stage table (Shared.PostTripDM_Stage.TEMP_dimHotel)								  with the comformingDimension.dbo.dimHotelHMF,to improve the performance as per DS-2527 (DSD-8)
  Ankur Adarsh		12/29/2017  Modified the sproc to handle the deadlock (DSD-1110)	
 =============================================
 */

 SET TRAN ISOLATION LEVEL READ UNCOMMITTED; -- DSD-1110

     DECLARE @RC INT   
    DECLARE @UnknownGeoKey INT
	DECLARE @UnknownCntryKey INT
	DECLARE @UnknownHotelChainKey INT

	SELECT  @UnknownGeoKey = GeoKey
    FROM    dbo.dimGeo g
    WHERE   g.TypeCode = 'O'
            AND g.CityCode = 'ZZZ'

    SELECT  @UnknownCntryKey = CountryKey
    FROM    dbo.dimcountry c
    WHERE   c.CountryCode = 'ZZ'

	--02/09/2016  Modify the sproc to use dimHotelBrand instead of dimHotelChain (As per DS-1211)
--	SELECT  @UnknownHotelChainKey = HotelChainKey
--   FROM    dbo.dimHotelChain hc
--   WHERE   hc.HotelChainID = 'Unknown'
	
	SELECT  @UnknownHotelChainKey = HotelBrandKey
    FROM    dbo.dimHotelBrand hc
    WHERE   hc.HotelBrandID = 'Unknown'
					   
    INSERT  INTO dbo.dimHotelHMF WITH (ROWLOCK) -- DSD-1110
            ( 
			  HotelKey,
			  --ChainCode ,
              --ChainName ,
			  HotelChainKey ,
              GDSPropertyNumber ,
              PropertyName ,
              GeoKey ,
              Address1 ,
              Address2 ,
              Address3 ,
              CityCode ,
              CityName ,
              [State] ,
              PostalCode ,
              --Country ,
              --CountryCode ,
			  CountryKey ,
              Phone ,
			  BCDPropertyName ,
			  StateProvinceName ,
			  PropertyLatitude ,
			  PropertyLongitude ,
			  GeoResolutionCode ,
			  GeoResolution ,
			  BCDMultAptCityCode ,
			  BCDMultAptCityName ,
			  MutiAptCityCode ,
			  AirportLatitude ,
			  AirportLongitude ,
			  DstMiles ,
			  DstKm ,
			  PropApTyp ,
			  PhoneCountryCode ,
			  PhoneCityCode ,
			  PhoneExchange ,
			  Fax ,
			  FaxCountryCode ,
			  FaxCityCode ,
			  FaxExchange ,
			  AmadeusID ,
			  AmadeusBrandCode ,
			  WorldSpanID ,
			  WorldSpanBrandCode ,
			  SabreID ,
			  SabreBrandCode ,
			  ApolloID ,
			  ApolloBrandCode ,
			  MarketTier ,
			  ServiceLevel ,
			  BCDPropertyID ,
			  ParentHotelKey,
              StartDate ,
              EndDate ,
              CurrentRecord ,
              InferredMember ,
              HotelID,
              ChkSum ,
			  DSSourceCode,
              DSCreateDate,
              DSCreateUser,
              DSLastChangeDate,
              DSLastChangeUser,
              DSChangeReason
            )
            SELECT  HotelKey,
					--ChainCode ,
                    --ChainName ,
					ISNULL(HotelChainKey, @UnknownHotelChainKey),
                    GDSPropertyNumber ,
                    PropertyName ,
                    GeoKey ,
                    Address1 ,
                    Address2 ,
                    Address3 ,
                    CityCode ,
                    CityName ,
                    [State] ,
                    PostalCode ,
                    --Country ,
                    --CountryCode ,
					ISNULL(CountryKey, @UnknownCntryKey),
                    Phone ,
					BCDPropertyName ,
					StateProvinceName ,
					PropertyLatitude ,
					PropertyLongitude ,
					GeoResolutionCode ,
					GeoResolution ,
					BCDMultAptCityCode ,
					BCDMultAptCityName ,
					MutiAptCityCode ,
					AirportLatitude ,
					AirportLongitude ,
					DstMiles ,
					DstKm ,
					PropApTyp ,
					PhoneCountryCode ,
					PhoneCityCode ,
					PhoneExchange ,
					Fax ,
					FaxCountryCode ,
					FaxCityCode ,
					FaxExchange ,
					AmadeusID ,
					AmadeusBrandCode ,
					WorldSpanID ,
					WorldSpanBrandCode ,
					SabreID ,
					SabreBrandCode ,
					ApolloID ,
					ApolloBrandCode ,
					MarketTier ,
					ServiceLevel ,
					BCDPropertyID ,
					ParentHotelKey,
					StartDate ,
					EndDate ,
					CurrentRecord ,
					InferredMember ,
					HotelID,
					ChkSum ,
					DSSourceCode,
					DSCreateDate,
					DSCreateUser,
					DSLastChangeDate,
					DSLastChangeUser,
					'INSERT' AS DSChangeReason	
            --FROM    Shared.PreTripDM_Stage.TEMP_dimHotelHMF h1 ( NOLOCK )
			FROM	Shared.ConformingDimensions.dimHotelHMF h1 (NOLOCK) -- DS-2527
            WHERE   NOT EXISTS ( SELECT 1
                                 FROM   dbo.dimHotelHMF h2 ( NOLOCK )
                                 WHERE  h1.HotelKey = h2.HotelKey )  
   
  
    SET @RC = @@RowCount  
  
	UPDATE  h1
    SET     --ChainCode = h2.ChainCode ,
			HotelID = h2.HotelID,
			HotelChainKey = ISNULL(h2.HotelChainKey , @UnknownHotelChainKey),
            GDSPropertyNumber = h2.GDSPropertyNumber ,
            GeoKey = ISNULL(h2.GeoKey , @UnknownGeoKey), 
			PropertyName= h2.PropertyName,  --  Ankur Adarsh	01/15/2015  Added PropertyName, Address1 to the update.
			Address1 = h2.Address1 , --  Ankur Adarsh		01/15/2015  Added PropertyName, Address1 to the update.
            Address2 = h2.Address2 ,
            Address3 = h2.Address3 ,
            CityCode = h2.CityCode ,
            CityName = h2.CityName ,
            [State] = h2.[State] ,
            PostalCode = h2.PostalCode ,
            --Country = h2.Country ,
            --CountryCode = h2.CountryCode ,	
			CountryKey = ISNULL(h2.CountryKey, @UnknownCntryKey),		
            Phone = h2.Phone ,
			BCDPropertyName = h2.BCDPropertyName ,
			StateProvinceName = h2.StateProvinceName ,
			PropertyLatitude = h2.PropertyLatitude ,
			PropertyLongitude = h2.PropertyLongitude ,
			GeoResolutionCode = h2.GeoResolutionCode ,
			GeoResolution = h2.GeoResolution ,
			BCDMultAptCityCode = h2.BCDMultAptCityCode ,
			BCDMultAptCityName = h2.BCDMultAptCityName ,
			MutiAptCityCode = h2.MutiAptCityCode ,
			AirportLatitude = h2.AirportLatitude ,
			AirportLongitude = h2.AirportLongitude ,
			DstMiles = h2.DstMiles ,
			DstKm = h2.DstKm ,
			PropApTyp = h2.PropApTyp ,
			PhoneCountryCode = h2.PhoneCountryCode ,
			PhoneCityCode = h2.PhoneCityCode ,
			PhoneExchange = h2.PhoneExchange ,
			Fax = h2.Fax ,
			FaxCountryCode = h2.FaxCountryCode ,
			FaxCityCode = h2.FaxCityCode ,
			FaxExchange = h2.FaxExchange ,
			AmadeusID = h2.AmadeusID ,
			AmadeusBrandCode = h2.AmadeusBrandCode ,
			WorldSpanID = h2.WorldSpanID ,
			WorldSpanBrandCode = h2.WorldSpanBrandCode ,
			SabreID = h2.SabreID ,
			SabreBrandCode = h2.SabreBrandCode ,
			ApolloID = h2.ApolloID ,
			ApolloBrandCode = h2.ApolloBrandCode ,
			MarketTier = h2.MarketTier ,
			ServiceLevel = h2.ServiceLevel ,
			BCDPropertyID = h2.BCDPropertyID ,
            StartDate = h2.StartDate ,
            ChkSum = h2.ChkSum ,
			DSLastChangeDate = h2.DSLastChangeDate ,
            DSLastChangeUser = h2.DSLastChangeUser ,
            DSChangeReason = 'UPDATE',
			ParentHotelKey = h2.ParentHotelKey,		--AA	11/19/2015 	
			EndDate = h2.EndDate, -- V1 AA		03/17/2016
			CurrentRecord = h2.CurrentRecord -- v1 AA		03/17/2016
    FROM    dimHotelHMF h1  WITH (ROWLOCK),-- DSD-1110
            --Shared.PreTripDM_Stage.TEMP_dimHotelHMF h2
			Shared.ConformingDimensions.dimHotelHMF h2 (NOLOCK) -- DS-2527
    WHERE   h1.HotelKey = h2.HotelKey 
	AND		(h1.ChkSum != h2.ChkSum
			OR h1.ChkSum IS NULL
			OR h1.GeoKey != h2.GeoKey
			OR h2.DSLastChangeDate <> h1.DSLastChangeDate --AA	11/19/2015 
			OR h1.ParentHotelKey <> h2.ParentHotelKey) --AA	11/19/2015 


    SET @RC = @RC + @@RowCount  
  	
	SELECT  @RC AS RowCnt  

GO


