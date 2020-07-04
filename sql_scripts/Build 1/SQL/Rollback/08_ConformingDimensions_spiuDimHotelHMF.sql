--run at DBP64CLU23SQLx2
USE [ConformingDimensions]
GO

/****** Object:  StoredProcedure [dbo].[spiuDimHotelHMF]    Script Date: 2/7/2020 2:00:54 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[spiuDimHotelHMF]
GO

/****** Object:  StoredProcedure [dbo].[spiuDimHotelHMF]    Script Date: 2/7/2020 2:00:54 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


  
  
CREATE PROCEDURE [dbo].[spiuDimHotelHMF]
AS 




/*
 ===============================================================================================================  
  spiuDimHotelHMF  
  Author:   Bob Pearson  
  Create date: 3/23/2008  
  Description: Updates or inserts records   
     into the dimHotel table from  
     the dbo.TEMP_dimHotelHMF table  
  Nisha Patel			02/27/2012	Added the h.Address3 = g.CityName to ge thte correct GEOKey for the small citynames 
	Prabhakar Dwivedi	05/18/2012	Modified the  where clause Phone column with HotelID as Unique Column
	James Voris			06/13/2012	Refactored logic to lookup dimGeo and include TypeCode.
									Added ChkSum
  Irfan Ismaily		10/10/2012	Added ChainName to the update.
  Ankur Adarsh		05/04/2015  Removed dimHotel with dimHotelHMF, added new columns and added PropertyName, Address1 to the update.
  Irfan Ismaily	    06/04/2015	Changed the default for ParentHotelKey to HotelKey
  Ankur Adarsh		09/17/2015  Modify the sproc to use dimCity instead of dimGeo (As per DS-1030)
  Ankur Adarsh		02/09/2016  Modify the sproc to use dimHotelBrand instead of dimHotelChain (As per DS-1211)
  Prabhakar Dwivedi	06/02/2016	Modified the sproc to handle the parentkey update for BCDPropertyID=1 where ParentHotelKey <> HotelKey DSP-1831
  Ankur Adarsh		12/29/2017  Modified the sproc to handle the deadlock (DSD-1110)	
  Ankur Adarsh		04/02/2018  Modified the sproc to add HotelChainKey/Countrykey in the WHERE clause of update statement (DSD-1143)
   

 Shashank Shukla   03/24/2019   V1 Added  logic for  replace  speacial character as per DN-234
 ================================================================================================================  
*/


SET TRAN ISOLATION LEVEL READ UNCOMMITTED; -- DSD-1110

    DECLARE @RC INT   
    DECLARE @UnknownGeoKey INT
	DECLARE @UnknownCntryKey INT
	DECLARE @UnknownHotelChainKey INT

	DECLARE @LastRunDate DATETIME
	SELECT  @LastRunDate = LastUpdate
	FROM    PostTripDM.dbo.LastUpdateDates
	WHERE   TableType = 'dimHotelHMF';
	-- We will need a new record created for dimHotel to store the last update date

    SELECT  @UnknownGeoKey = GeoKey
    FROM    dbo.dimCity g (NOLOCK)--dbo.dimGeo g
    WHERE   g.TypeCode = 'O'
            AND g.CityCode = 'ZZZ'

    SELECT  @UnknownCntryKey = CountryKey
    FROM    dbo.dimcountry c
    WHERE   c.CountryCode = 'ZZ'
--Ankur 02/09/2016  Modify the sproc to use dimHotelBrand instead of dimHotelChain
/*
	SELECT  @UnknownHotelChainKey = HotelChainKey
    FROM    dbo.dimHotelChain hc
    WHERE   hc.HotelChainID = 'Unknown'
*/
	SELECT  @UnknownHotelChainKey = HotelBrandKey
    FROM    dbo.dimHotelBrand hc
    WHERE   hc.HotelBrandID = 'Unknown'


    UPDATE  h
    SET     GeoKey = COALESCE(g.Geokey, @UnknownGeoKey)
    FROM    dbo.TEMP_dimHotelHMF h
	LEFT OUTER JOIN dbo.dimCity g ( NOLOCK ) ON ( h.CityCode = g.CityCode
                                                AND g.TypeCode = 'O'
                                            )

    --LEFT OUTER JOIN dbo.dimGeo g ( NOLOCK ) ON ( h.CityCode = g.CityCode
    --                                             AND g.TypeCode = 'O'
    --                                           )

--DSD-1143 Start
	UPDATE  h
    SET     HotelBrandKey = COALESCE(b.HotelBrandKey, @UnknownHotelChainKey)
    FROM    dbo.TEMP_dimHotelHMF h
	LEFT OUTER JOIN dbo.dimHotelBrand b ( NOLOCK ) 
	ON b.HotelBrandID = h.ChainCode 
	AND b.HotelBrandName = h.BrandName;

	
	UPDATE  h
    SET     CountryKey = COALESCE(c.CountryKey, @UnknownCntryKey)
    FROM    dbo.TEMP_dimHotelHMF h
	LEFT OUTER JOIN dbo.dimcountry c ( NOLOCK ) 
	ON c.CountryCode = h.CountryCode;
--DSD-1143 END
                                          

 										   
    UPDATE  h1
    SET     --ChainCode = h2.ChainCode ,
--Ankur 02/09/2016  Modify the sproc to use dimHotelBrand instead of dimHotelChain
/*
			HotelChainKey = ISNULL((SELECT HotelChainKey 
									FROM dbo.dimHotelChain c (NOLOCK) 
									WHERE c.HotelChainID = h2.ChainCode
								   )
								  , @UnknownHotelChainKey),
*/
--DSD-1143 Start
/*
            HotelChainKey = ISNULL((SELECT HotelBrandKey 
									FROM dbo.dimHotelBrand c (NOLOCK) 
									WHERE c.HotelBrandID = h2.ChainCode 
									AND c.HotelBrandName = h2.BrandName
								   )
								  , @UnknownHotelChainKey),
*/
			HotelChainKey = h2.HotelBrandKey,
--DSD-1143 END
			GDSPropertyNumber = h2.GDSPropertyNumber ,
            GeoKey = h2.GeoKey ,
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
--DSD-1143 Start
/*				
			CountryKey = ISNULL((SELECT CountryKey 
								 FROM dbo.dimCountry c (NOLOCK) 
								 WHERE c.CountryCode = h2.CountryCode
								)
								, @UnknownCntryKey),
*/
			CountryKey = h2.CountryKey,
--DSD-1143 End
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
            StartDate = '01/01/2005',--GETDATE() ,
            ChkSum = h2.ChkSum ,
			DSLastChangeDate = GETDATE() ,
            DSLastChangeUser = SUSER_NAME() ,
            DSChangeReason = 'UPDATE'			
    FROM    dbo.dimHotelHMF h1  WITH (ROWLOCK) --DSD-1110
		 ,  dbo.TEMP_dimHotelHMF h2
    WHERE   h1.HotelID = h2.HotelID 
	AND		(h1.ChkSum != h2.ChkSum
			OR h1.ChkSum IS NULL
			OR h1.GeoKey != h2.GeoKey
--DSD-1143 Start
			OR h1.HotelChainKey != h2.HotelBrandKey
			OR h1.CountryKey != h2.CountryKey
--DSD-1143 END
			)
	AND NOT EXISTS( SELECT 1 FROM  [ConformingDimensions].[dbo].[STAGE_dimHotelHMFOrphanArchive] B  (NOLOCK)
	WHERE h1.HotelID = B.HotelID
	)
  
    SET @RC = @@RowCount  
  
    INSERT  INTO dbo.dimHotelHMF  WITH (ROWLOCK) --DSD-1110
            ( 
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
			  --DSChangeToKey,
              DSCreateDate,
              DSCreateUser,
              DSLastChangeDate,
              DSLastChangeUser,
              DSChangeReason
            )
            SELECT  --ChainCode ,
                    --ChainName ,
--Ankur 02/09/2016  Modify the sproc to use dimHotelBrand instead of dimHotelChain
/*
					ISNULL((SELECT HotelChainKey 
							FROM dbo.dimHotelChain c (NOLOCK) 
							WHERE c.HotelChainID = h1.ChainCode
						   )
						  , @UnknownHotelChainKey),
*/
--DSD-1143 Start
/*
                    ISNULL((SELECT HotelBrandKey 
							FROM dbo.dimHotelBrand c (NOLOCK) 
							WHERE c.HotelBrandID = h1.ChainCode 
							AND c.HotelBrandName = h1.BrandName
							)
							, @UnknownHotelChainKey),
*/
					HotelBrandKey,
--DSD-1143 End
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
--DSD-1143 Start
/*
					ISNULL((SELECT CountryKey 
							FROM dbo.dimCountry c (NOLOCK) 
							WHERE c.CountryCode = h1.CountryCode
						   )
						  , @UnknownCntryKey),
*/
					CountryKey,
--DSD-1143 End
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
					1,
                    '01/01/2005', --GETDATE() ,
                    '12/31/2099' ,
                    1 ,
                    0 ,
                    HotelID,
                    ChkSum,
					'ODSMasterTables' as DSSourceCode,
					--0 AS DSChangeToKey,
					GETDATE() AS DSCreateDate,
					SUSER_NAME() AS DSCreateUser,
					GETDATE() AS DSLastChangeDate,
					SUSER_NAME() AS DSLastChangeUser,
					'INSERT' AS DSChangeReason	
            FROM    dbo.TEMP_dimHotelHMF h1 
            WHERE   NOT EXISTS ( SELECT 1
                                 FROM   dbo.dimHotelHMF h2 
                                 WHERE  h1.HotelID = h2.HotelID )  
				AND NOT EXISTS( SELECT 1 FROM  [ConformingDimensions].[dbo].[STAGE_dimHotelHMFOrphanArchive] B  (NOLOCK)
			WHERE h1.HotelID = B.HotelID
			)
  
    SET @RC = @RC + @@RowCount  
/*DSD-1110 start*/  
/* Changed the default value for ParentHotelKey to HotelKey
*/

    --UPDATE  dbo.dimHotelHMF  
    --SET     ParentHotelKey = HotelKey
    --WHERE   ParentHotelKey = 1


	UPDATE  dh
	SET     dh.ParentHotelKey = dh.HotelKey
	FROM	dbo.dimHotelHMF dh WITH (ROWLOCK)     
    WHERE   dh.ParentHotelKey = 1

/* Changed the default value for ParentHotelKey to HotelKey when ParentHotelKey <> HotelKey
	AND     BCDPropertyID=1 as Per DSP-1831
*/	
	--UPDATE  dbo.dimHotelHMF 
	--SET     ParentHotelKey = HotelKey
	--WHERE   ParentHotelKey <> HotelKey
	--AND     BCDPropertyID=1

	UPDATE  dh
	SET     dh.ParentHotelKey = dh.HotelKey
	FROM	dbo.dimHotelHMF dh WITH (ROWLOCK) 
	WHERE   dh.ParentHotelKey <> dh.HotelKey
	AND     dh.BCDPropertyID=1
/*DSD-1110 End*/	       

/* For the mapping changes in the bridge table, 
   update BCDPropertyID in the dimHotelHMF table 
*/
;WITH    NewMappings_CTE
          AS ( SELECT   olh.HotelID ,
                        brdg.BCDPropertyID
               FROM     Shared.ODSMasterTables.ODSLkupHotel olh
                        JOIN Shared.ODSMasterTables.ODSLkupHotelBCDMaster brdg ON olh.HotelKey = brdg.HotelKey
               WHERE    brdg.DSLastChangeDate >= @LastRunDate
             )
    UPDATE  dhmf
    SET     BCDPropertyID = newmap.BCDPropertyID ,
            DSLastChangeDate = GETDATE() ,
            DSLastChangeUser = SUSER_NAME() ,
            DSChangeReason = 'BCDPropertyID updated'
    FROM    dbo.dimHotelHMF dhmf WITH (ROWLOCK) --DSD-1110
            JOIN NewMappings_CTE newmap ON dhmf.HotelID = newmap.HotelID
    WHERE   dhmf.BCDPropertyID <> newmap.BCDPropertyID

/* Realign the child-parent relationship
*/
;WITH    Parent_CTE
          AS ( SELECT   BCDPropertyID ,
                        MIN(HotelKey) AS HotelKey
               FROM     dbo.dimHotelHMF
			   WHERE 	BCDPropertyID <> 1 -- It is not null column so during initial load BCDProprtyID defaulted to 1
               GROUP BY BCDPropertyID
             )
    UPDATE  dhmf
    SET     ParentHotelKey = ISNULL(Parent.HotelKey, dhmf.HotelKey) ,
            DSLastChangeDate = GETDATE() ,
            DSLastChangeUser = SUSER_NAME() ,
            DSChangeReason = 'ParentHotelKey mapping updated'
    FROM    dbo.dimHotelHMF dhmf WITH (ROWLOCK) --DSD-1110
            LEFT JOIN Parent_CTE Parent ON dhmf.BCDPropertyID = Parent.BCDPropertyID
    WHERE   dhmf.ParentHotelKey <> Parent.HotelKey

	
	
	UPDATE  ld
    SET     ld.LastUpdate = GETDATE()
    FROM    PostTripDM.dbo.LastUpdateDates ld
	WHERE   ld.TableType = 'dimHotelHMF';
	
	SELECT  @RC AS RowCnt  
	
--Start V1

	SELECT dhf.HotelKey INTO dbo.#dimHotelHMF
	FROM dbo.dimHotelHMF dhf WITH (NOLOCk) 
	WHERE 
	Address1 Like '%~%'OR Address2 Like '%~%' OR Address3 Like '%~%' OR PropertyName Like '%~%'   
	OR BCDPropertyName Like '%~%' or StateProvinceName Like '%~%' 

	UPDATE dhf
	 SET 
		  dhf.Address1  = REPLACE(Address1, '~', '') 
		, dhf.Address2  = REPLACE(Address2, '~', '')  
		, dhf.Address3  = REPLACE(Address3, '~', '')   
		, dhf.PropertyName  = REPLACE(PropertyName, '~', '') 
		, dhf.BCDPropertyName  = REPLACE(BCDPropertyName, '~', '') 
		, dhf.StateProvinceName  = REPLACE(StateProvinceName, '~', '') 
	 
	FROM dbo.dimHotelHMF dhf WITH (ROWLOCK) 
	JOIN dbo.#dimHotelHMF h ON dhf.HotelKey = h.HotelKey

--END  V1


GO


