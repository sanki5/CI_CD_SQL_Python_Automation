--run at DBP64CLU23SQLx2
USE PreTripDataMart
GO


IF EXISTS (SELECT 1 FROM sys.Tables t JOIN sys.columns c ON t.object_id = c.object_id WHERE t.name = 'dimHotelHMF' AND c.name = 'LanyonID')
BEGIN
	ALTER TABLE dbo.dimHotelHMF DROP COLUMN LanyonID  
END
