--Run at DSProdSSIS01
USE SSISDB
GO

	IF  EXISTS (
		SELECT 1 FROM [SSISDB].[catalog].[environments] env (NOLOCK)
		INNER JOIN    [SSISDB].[catalog].[folders] fold (NOLOCK) ON env.folder_id=fold.folder_id
     INNER JOIN [SSISDB].[catalog].[environment_variables] envvar ON env.environment_id = envvar.environment_id
     WHERE envvar.name = N'CON_DSNODS'  AND 
	    env.name=N'ODSConfigs_BCDHotelMaster' AND fold.name=N'BCDHotelMaster'
	  ) 
BEGIN
	 EXECUTE [catalog].[delete_environment_variable] 
	 @folder_name  = N'BCDHotelMaster'
	 ,@environment_name  = N'ODSConfigs_BCDHotelMaster'
	 ,@variable_name  = N'CON_DSNODS'
END
 GO

	IF  EXISTS (
		SELECT 1 FROM [SSISDB].[catalog].[environments] env (NOLOCK)
		INNER JOIN    [SSISDB].[catalog].[folders] fold (NOLOCK) ON env.folder_id=fold.folder_id
     INNER JOIN [SSISDB].[catalog].[environment_variables] envvar ON env.environment_id = envvar.environment_id
     WHERE envvar.name = N'VarAPICounter'  AND 
	    env.name=N'ODSConfigs_BCDHotelMaster' AND fold.name=N'BCDHotelMaster'
	  ) 
BEGIN
	 EXECUTE [catalog].[delete_environment_variable] 
	 @folder_name  = N'BCDHotelMaster'
	 ,@environment_name  = N'ODSConfigs_BCDHotelMaster'
	 ,@variable_name  = N'VarAPICounter'
END
 GO
