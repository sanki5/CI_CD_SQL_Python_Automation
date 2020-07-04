--Run at DSProdSSIS01 
USE SSISDB
GO
 
-- Reference variable CON_DSNODS to parameter CON_DSNODS
EXEC		[SSISDB].[catalog].[set_object_parameter_value]
			@object_type=20
,			@parameter_name=N'CON_DSNODS'
,			@object_name=N'EDMHMFWeeklyLoad'
,			@folder_name=N'BCDHotelMaster'
,			@project_name=N'EDMHMFWeeklyLoad'
,			@value_type=R
,			@parameter_value=N'CON_DSNODS'
GO
 
-- Reference variable VarAPICounter to parameter VarAPICounter
EXEC		[SSISDB].[catalog].[set_object_parameter_value]
			@object_type=20
,			@parameter_name=N'VarAPICounter'
,			@object_name=N'EDMHMFWeeklyLoad'
,			@folder_name=N'BCDHotelMaster'
,			@project_name=N'EDMHMFWeeklyLoad'
,			@value_type=R
,			@parameter_value=N'VarAPICounter'
GO
 