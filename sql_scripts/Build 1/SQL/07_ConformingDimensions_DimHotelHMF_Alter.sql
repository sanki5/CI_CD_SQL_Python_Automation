--run at DBP64CLU23SQLx2
USE [ConformingDimensions]
GO

IF NOT EXISTS (SELECT 1 FROM sys.Tables t JOIN sys.columns c ON t.object_id = c.object_id WHERE t.name = 'TEMP_dimHotelHMF' AND c.name = 'LanyonID')
BEGIN
	ALTER TABLE dbo.TEMP_dimHotelHMF ADD LanyonID VARCHAR (15)
END

IF NOT EXISTS (SELECT 1 FROM sys.Tables t JOIN sys.columns c ON t.object_id = c.object_id WHERE t.name = 'dimHotelHMF' AND c.name = 'LanyonID')
BEGIN
	ALTER TABLE dbo.dimHotelHMF ADD LanyonID VARCHAR (15)
END


