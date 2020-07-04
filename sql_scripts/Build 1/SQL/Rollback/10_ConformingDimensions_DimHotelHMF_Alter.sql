--run at DBP64CLU23SQLx2
USE [ConformingDimensions]
GO

IF EXISTS (SELECT 1 FROM sys.Tables t JOIN sys.columns c ON t.object_id = c.object_id WHERE t.name = 'TEMP_dimHotelHMF' AND c.name = 'LanyonID')
BEGIN
	ALTER TABLE dbo.TEMP_dimHotelHMF DROP COLUMN LanyonID  
END



IF EXISTS (SELECT 1 FROM sys.Tables t JOIN sys.columns c ON t.object_id = c.object_id WHERE t.name = 'dimHotelHMF' AND c.name = 'LanyonID')
BEGIN
	ALTER TABLE dbo.dimHotelHMF DROP COLUMN LanyonID 
END



