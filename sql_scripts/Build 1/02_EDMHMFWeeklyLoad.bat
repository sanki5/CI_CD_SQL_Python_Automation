@echo off
echo Project deployment started ...
set variscap="%~dp0%SSIS\EDMHMFWeeklyLoad.ispac" 
FOR /F "usebackq" %%i IN (`hostname`) DO SET VARDestServer=%%i
set varDestFolder="/SSISDB/BCDHotelMaster/EDMHMFWeeklyLoad"


SET PATH="C:\Program Files\Microsoft SQL Server\130\DTS\Binn"
IsDeploymentWizard.exe /S /SP:%variscap% /DS:%varDestServer% /DP:%varDestFolder%

echo Project has been Deployed
PAUSE


