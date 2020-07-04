--Run at DBP64CLU23SQLx1
USE [ODSMasterTables_Stage]
GO

IF EXISTS ( SELECT  1
            FROM    sysobjects
            WHERE   id = OBJECT_ID('dbo.ODSImportBCDHotelMasterDenodo')
                    AND type = 'U' ) 
    DROP TABLE dbo.ODSImportBCDHotelMasterDenodo
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ODSImportBCDHotelMasterDenodo](
	[BCDPropertyId] [int] NOT NULL,
	[BrandName] [varchar](500) NOT NULL,
	[BrandCode] [char](500) NOT NULL,
	[MasterChainName] [varchar](500) NOT NULL,
	[MasterChainCode] [char](500) NOT NULL,
	[ActualPropertyName] [varchar](500) NULL,
	[BCDPropertyName] [varchar](500) NULL,
	[StreetAddress1] [varchar](500) NOT NULL,
	[StreetAddress2] [varchar](500) NULL,
	[City] [varchar](500) NOT NULL,
	[StateProvinceName] [varchar](500) NULL,
	[StateProvinceCode] [varchar](500) NULL,
	[PostalCode] [varchar](500) NOT NULL,
	[PostalCodeLast4] [varchar](500) NULL,
	[CountryName] [varchar](500) NOT NULL,
	[CountryCode2Char] [char](500) NOT NULL,
	[CountryCode3Char] [char](500) NULL,
	[CountryCodeDigit] [int] NULL,
	[PropertyLatitude] [numeric](15, 8) NULL,
	[PropertyLongitude] [numeric](15, 8) NULL,
	[GeoResolutionCode] [varchar](500) NULL,
	[GeoResolution] [varchar](500) NULL,
	[AirportCode] [char](500) NULL,
	[BCDMultAptCityCode] [varchar](500) NULL,
	[BCDMultAptCityName] [varchar](500) NULL,
	[MutiAptCityCode] [varchar](500) NULL,
	[AirportLatitude] [numeric](15, 8) NULL,
	[AirportLongitude] [numeric](15, 8) NULL,
	[DstMiles] [numeric](15, 2) NULL,
	[DstKm] [numeric](15, 2) NULL,
	[PropApTyp] [varchar](500) NULL,
	[Phone] [varchar](500) NULL,
	[PhoneCountrycode] [int] NULL,
	[PhoneCityCode] [int] NULL,
	[PhoneExchange] [varchar](500) NULL,
	[Fax] [varchar](500) NULL,
	[FaxCountryCode] [int] NULL,
	[FaxCityCode] [int] NULL,
	[FaxExchange] [varchar](500) NULL,
	[AmadeusID] [varchar](500) NULL,
	[AmadeusBrandCode] [char](500) NULL,
	[WorldSpanID] [varchar](500) NULL,
	[WorldSpanBrandCode] [char](500) NULL,
	[SabreID] [varchar](500) NULL,
	[SabreBrandCode] [char](500) NULL,
	[ApolloID] [varchar](500) NULL,
	[ApolloBrandCode] [char](500) NULL,
	[MarketTier] [varchar](500) NULL,
	[ServiceLevel] [varchar](500) NULL,
	[UpdateDt] [datetime] NULL,
	[HotelID] [varchar] (500) NULL,
	[HotelKey] [int] null,
	[HotelPhoneNumberRight10] [nvarchar] (500) NULL,
	[BrandRollupName] [varchar] (500) NOT NULL,
	[LanyonID] [varchar] (500) NULL
 ) ON [PRIMARY]

GO


