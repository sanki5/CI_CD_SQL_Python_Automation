--Run at DBP64CLU23SQLx2
USE [PreTripDataMart]
GO

/****** Object:  View [dbo].[dimHotel]    Script Date: 3/5/2020 9:30:19 PM ******/
DROP VIEW IF EXISTS [dbo].[dimHotel]
GO

/****** Object:  View [dbo].[dimHotel]    Script Date: 3/5/2020 9:30:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[dimHotel]
AS
/*
-- ==============================================================
-- Description: Renamed the dimHotel table to dimHotelHMF and 
--				created the dimHotel view to align attributes 
--				based on ParentHotelKey.
-- ==============================================================

V1 Modified by Prabhakar on 05/25/2018 as per DSD-1217
												Add the following columns to dimHotel view:
												1.HotelBrandName = dimHotelBrand.HotelBrandName
												2.HotelMasterChainName = dimHotelBrand.HotelMasterChainKey.dimHotelMasterChain.HotelMasterChainName
												3.BrandRollupName = dimHotelBrand.HotelBrandRollupName
V2 Modified by Shashank on 02/28/2019 as per DN-292 to remove the recurssion due to Join of Hotelkey with the ParentHotelKey
V3 Modified by Psrivastava on 07/22/2019 as per DN-1050 to remove REPLACE of special characters from the HotelMasterChainName
V4 Modified by Prabhakar on 03/05/2020 as per DN-1825 to Add LanyonID in the view
*/
    SELECT  hmf.HotelKey ,
            brnd.HotelBrandID AS ChainCode ,
            brnd.HotelBrandRollupName AS ChainName ,
            brnd.HotelBrandKey ,
--Start V1	
			brnd.HotelBrandName AS HotelBrandName,
--Start V3		
			--REPLACE( REPLACE( LTRIM(RTRIM( mstrchn.HotelMasterChainName)),',',''),'.','') AS HotelMasterChainName ,
			mstrchn.HotelMasterChainName AS HotelMasterChainName , 
			/* Accomodated Code Change for HotelMasterChainName (BCDETL-332 issue for the special characters) */
--End V3
			brnd.HotelBrandRollupName AS BrandRollupName,
--Start V2
            hmf.GDSPropertyNumber ,
            hmf.GeoKey ,
            CONVERT(VARCHAR(50), hmf.PropertyName) AS HotelName ,
            CONVERT(VARCHAR(50), hmf.Address1) AS AddressLine1 ,
            CONVERT(VARCHAR(50), hmf.Address2) AS AddressLine2 ,
            CONVERT(VARCHAR(40), hmf.Address3) AS City ,
            hmf.CityCode ,
            hmf.CityName ,
            CONVERT(VARCHAR(50), hmf.StateProvinceName) AS State ,
            CONVERT(VARCHAR(20), hmf.PostalCode) AS PostalCode ,
            CONVERT(VARCHAR(50), cntry.CountryName) AS Country ,
            CONVERT(VARCHAR(10), cntry.CountryCode) AS CountryCode ,
            CONVERT(VARCHAR(40), hmf.Phone) AS PhoneNumber ,
            hmf.PropertyLatitude ,
            hmf.PropertyLongitude ,
            hmf.BCDMultAptCityCode ,
            hmf.BCDMultAptCityName ,
            hmf.MutiAptCityCode ,
            hmf.DstMiles ,
            hmf.DstKm ,
            hmf.AmadeusID ,
            hmf.WorldSpanID ,
            hmf.SabreID ,
            hmf.ApolloID ,
            hmf.MarketTier ,
            hmf.ServiceLevel ,
            hmf.BCDPropertyID ,
            CONVERT(VARCHAR(25), hmf.HotelID) AS HotelID ,
            hmf.ChkSum ,
            hmf.StartDate ,
            hmf.EndDate ,
            hmf.CurrentRecord ,
            hmf.InferredMember,
--Start V4
			hmf.LanyonID
--End V4
    FROM    dbo.dimHotelHMF hmf WITH ( NOLOCK )
--Start V2
            --JOIN dbo.dimHotelHMF hmfP WITH ( NOLOCK ) ON hmf.ParentHotelKey = hmfP.HotelKey
--End V2
            JOIN dbo.dimHotelBrand brnd WITH ( NOLOCK ) ON hmf.HotelChainKey = brnd.HotelBrandKey
			--hmfP.HotelChainKey = brnd.HotelBrandKey
            JOIN dbo.dimHotelMasterChain mstrchn WITH ( NOLOCK ) ON brnd.HotelMasterChainKey = mstrchn.HotelMasterChainKey
            JOIN dbo.dimCountry cntry WITH ( NOLOCK ) ON hmf.CountryKey = cntry.CountryKey
			--hmfP.CountryKey = cntry.CountryKey
			;



GO


