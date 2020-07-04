--run at DBP64CLU23SQLx1
USE [ODSMasterTables_Stage]
GO

/****** Object:  StoredProcedure [dbo].[spuHotelID]    Script Date: 2/17/2020 2:42:44 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[spuHotelID]
GO

/****** Object:  StoredProcedure [dbo].[spuHotelID]    Script Date: 2/17/2020 2:42:44 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* 
 ===============================================================================================================  
spuHotelID
Author: Ankur Adarsh
Create date: 01/19/2015  
Description: Updates HotelID in ODSImportBCDHotelMaster

Version		Updated By			Updated Date			Description
------		-----------			-------------			------------------------
V1			SH					02-07-2020				Added logic to avoid the invalid Phone to get updated in the column HotelID as per DN-1282 
 ================================================================================================================  
 */ 
  
  
CREATE PROCEDURE [dbo].[spuHotelID]
AS 
    BEGIN

    SET NOCOUNT ON ;

	;WITH CTE
	AS
	(
		SELECT 	row_number() over (Partition By h.Phone Order by h.BCDPropertyID DESC) row_num, h.Phone, h.BCDPropertyID
		FROM    ODSMasterTables_Stage.dbo.ODSImportBCDHotelMaster h
		WHERE h.Phone IS NOT NULL
--V1 Start
		AND Len(h.Phone) < 21 AND ISNUMERIC(h.Phone) = 1 AND h.Phone NOT LIKE '+%' AND  h.Phone NOT LIKE '-%'	
--V1 End
	)UPDATE h
	SET h.HotelID = x.Phone
	--select h.HotelID , x.Phone 
	FROM ODSMasterTables_Stage.dbo.ODSImportBCDHotelMaster h
	INNER JOIN CTE x
	ON h.BCDPropertyId = x.BCDPropertyId  
	WHERE x.row_num =1 

    END


GO


