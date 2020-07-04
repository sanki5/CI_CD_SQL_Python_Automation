--run at DBP64CLU23SQLx1
USE [ODSMasterTables_Stage]
GO

IF NOT EXISTS (SELECT 1 FROM sys.Tables t JOIN sys.columns c ON t.object_id = c.object_id WHERE t.name = 'StageODSLkupHotelBCDMaster' AND c.name = 'LanyonID')
BEGIN
	ALTER TABLE dbo.StageODSLkupHotelBCDMaster ADD LanyonID VARCHAR (15)
END

