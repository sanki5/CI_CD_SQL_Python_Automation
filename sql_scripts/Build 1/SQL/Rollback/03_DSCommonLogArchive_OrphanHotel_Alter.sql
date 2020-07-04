--run at DBP64CLU23SQLx1
USE DSCommonLogArchive
GO

IF EXISTS (SELECT 1 FROM sys.Tables t JOIN sys.columns c ON t.object_id = c.object_id WHERE t.name = 'dimHotelHMFOrphanArchiveConfDim' AND c.name = 'LanyonID')
BEGIN
	ALTER TABLE dbo.[dimHotelHMFOrphanArchiveConfDim] DROP COLUMN LanyonID 
END

IF EXISTS (SELECT 1 FROM sys.Tables t JOIN sys.columns c ON t.object_id = c.object_id WHERE t.name = 'dimHotelHMFOrphanArchivePreTrip' AND c.name = 'LanyonID')
BEGIN
	ALTER TABLE dbo.[dimHotelHMFOrphanArchivePreTrip] DROP COLUMN LanyonID  
END

IF EXISTS (SELECT 1 FROM sys.Tables t JOIN sys.columns c ON t.object_id = c.object_id WHERE t.name = 'dimHotelHMFOrphanArchivePostTrip' AND c.name = 'LanyonID')
BEGIN
	ALTER TABLE dbo.[dimHotelHMFOrphanArchivePostTrip] DROP COLUMN LanyonID 
END




USE [ConformingDimensions]
GO

IF EXISTS (SELECT 1 FROM sys.Tables t JOIN sys.columns c ON t.object_id = c.object_id WHERE t.name = 'STAGE_dimHotelHMFOrphanArchive' AND c.name = 'LanyonID')
BEGIN
	ALTER TABLE dbo.STAGE_dimHotelHMFOrphanArchive DROP COLUMN LanyonID 
END


USE PreTripDM_Stage
GO

IF EXISTS (SELECT 1 FROM sys.Tables t JOIN sys.columns c ON t.object_id = c.object_id WHERE t.name = 'STAGE_dimHotelHMFOrphanArchive' AND c.name = 'LanyonID')
BEGIN
	ALTER TABLE dbo.STAGE_dimHotelHMFOrphanArchive DROP COLUMN LanyonID 
END



USE PostTripDM_Stage
GO

IF EXISTS (SELECT 1 FROM sys.Tables t JOIN sys.columns c ON t.object_id = c.object_id WHERE t.name = 'STAGE_dimHotelHMFOrphanArchive' AND c.name = 'LanyonID')
BEGIN
	ALTER TABLE dbo.STAGE_dimHotelHMFOrphanArchive DROP COLUMN LanyonID  
END

