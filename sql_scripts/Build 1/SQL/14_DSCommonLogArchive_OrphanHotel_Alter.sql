--run at DBP64CLU23SQLx1
USE DSCommonLogArchive
GO

IF NOT EXISTS (SELECT 1 FROM sys.Tables t JOIN sys.columns c ON t.object_id = c.object_id WHERE t.name = 'dimHotelHMFOrphanArchiveConfDim' AND c.name = 'LanyonID')
BEGIN
	ALTER TABLE dbo.[dimHotelHMFOrphanArchiveConfDim] ADD LanyonID VARCHAR (15)
END

IF NOT EXISTS (SELECT 1 FROM sys.Tables t JOIN sys.columns c ON t.object_id = c.object_id WHERE t.name = 'dimHotelHMFOrphanArchivePreTrip' AND c.name = 'LanyonID')
BEGIN
	ALTER TABLE dbo.[dimHotelHMFOrphanArchivePreTrip] ADD LanyonID VARCHAR (15)
END

IF NOT EXISTS (SELECT 1 FROM sys.Tables t JOIN sys.columns c ON t.object_id = c.object_id WHERE t.name = 'dimHotelHMFOrphanArchivePostTrip' AND c.name = 'LanyonID')
BEGIN
	ALTER TABLE dbo.[dimHotelHMFOrphanArchivePostTrip] ADD LanyonID VARCHAR (15)
END




USE [ConformingDimensions]
GO

IF NOT EXISTS (SELECT 1 FROM sys.Tables t JOIN sys.columns c ON t.object_id = c.object_id WHERE t.name = 'STAGE_dimHotelHMFOrphanArchive' AND c.name = 'LanyonID')
BEGIN
	ALTER TABLE dbo.STAGE_dimHotelHMFOrphanArchive ADD LanyonID VARCHAR (15)
END


USE PreTripDM_Stage
GO

IF NOT EXISTS (SELECT 1 FROM sys.Tables t JOIN sys.columns c ON t.object_id = c.object_id WHERE t.name = 'STAGE_dimHotelHMFOrphanArchive' AND c.name = 'LanyonID')
BEGIN
	ALTER TABLE dbo.STAGE_dimHotelHMFOrphanArchive ADD LanyonID VARCHAR (15)
END



USE PostTripDM_Stage
GO

IF NOT EXISTS (SELECT 1 FROM sys.Tables t JOIN sys.columns c ON t.object_id = c.object_id WHERE t.name = 'STAGE_dimHotelHMFOrphanArchive' AND c.name = 'LanyonID')
BEGIN
	ALTER TABLE dbo.STAGE_dimHotelHMFOrphanArchive ADD LanyonID VARCHAR (15)
END

