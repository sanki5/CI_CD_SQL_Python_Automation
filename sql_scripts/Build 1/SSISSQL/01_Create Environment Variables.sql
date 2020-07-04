 -- RUN AT  DSProdSSIS01
USE SSISDB
GO
 
  
-- Create variables for environment: ODSConfigs_BCDHotelMaster - CON_DSNODS
	IF NOT EXISTS (
		SELECT 1 FROM [SSISDB].[catalog].[environments] env (NOLOCK)
		INNER JOIN    [SSISDB].[catalog].[folders] fold (NOLOCK) ON env.folder_id=fold.folder_id
     INNER JOIN [SSISDB].[catalog].[environment_variables] envvar ON env.environment_id = envvar.environment_id
     WHERE envvar.name = N'CON_DSNODS'  AND 
	    env.name=N'ODSConfigs_BCDHotelMaster' AND fold.name=N'BCDHotelMaster'
	  ) 
BEGIN
DECLARE @var sql_variant = N'Dsn=Denodo_ODS;'
EXEC		[SSISDB].[catalog].[create_environment_variable]
			@variable_name=N'CON_DSNODS'
,			@sensitive=False
,			@description=N''
,			@environment_name=N'ODSConfigs_BCDHotelMaster'
,			@folder_name=N'BCDHotelMaster'
,			@value=@var
,			@data_type=N'String'
END
ELSE
BEGIN
DECLARE @var1 sql_variant = N'Dsn=Denodo_ODS;'
EXEC		[SSISDB].[catalog].[set_environment_variable_value]  
			@variable_name=N'CON_DSNODS'
,			@environment_name=N'ODSConfigs_BCDHotelMaster'
,			@folder_name=N'BCDHotelMaster'
,			@value=@var1
END
GO
 


-- Create variables for environment: ODSConfigs_BCDHotelMaster - VarAPICounter
	IF NOT EXISTS (
		SELECT 1 FROM [SSISDB].[catalog].[environments] env (NOLOCK)
		INNER JOIN    [SSISDB].[catalog].[folders] fold (NOLOCK) ON env.folder_id=fold.folder_id
     INNER JOIN [SSISDB].[catalog].[environment_variables] envvar ON env.environment_id = envvar.environment_id
     WHERE envvar.name = N'VarAPICounter'  AND 
	    env.name=N'ODSConfigs_BCDHotelMaster' AND fold.name=N'BCDHotelMaster'
	  ) 
BEGIN
DECLARE @var sql_variant = 50000
EXEC		[SSISDB].[catalog].[create_environment_variable]
			@variable_name=N'VarAPICounter'
,			@sensitive=False
,			@description=N''
,			@environment_name=N'ODSConfigs_BCDHotelMaster'
,			@folder_name=N'BCDHotelMaster'
,			@value=@var
,			@data_type=N'Int32'
END
ELSE
BEGIN
DECLARE @var1 sql_variant = 50000
EXEC		[SSISDB].[catalog].[set_environment_variable_value]  
			@variable_name=N'VarAPICounter'
,			@environment_name=N'ODSConfigs_BCDHotelMaster'
,			@folder_name=N'BCDHotelMaster'
,			@value=@var1
END
GO


