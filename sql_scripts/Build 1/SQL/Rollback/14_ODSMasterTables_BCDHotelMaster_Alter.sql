--run at DBP64CLU23SQLx1
USE [ODSMasterTables]
GO

IF EXISTS (SELECT 1 FROM sys.Tables t JOIN sys.columns c ON t.object_id = c.object_id WHERE t.name = 'BCDHotelMaster' AND c.name = 'LanyonID')
BEGIN
	ALTER TABLE dbo.BCDHotelMaster DROP COLUMN LanyonID 
END
