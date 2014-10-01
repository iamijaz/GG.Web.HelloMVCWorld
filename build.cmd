rem Copy this file to start making use of the shared build script. There should be no need to edit it.
rem Confluence documentation: https://justgiving.atlassian.net/wiki/display/DD/A%3A+Building+and+Testing+with+Shared+Build+Script+and+TeamCity
@echo off

powershell.exe -NoProfile -ExecutionPolicy unrestricted -command ".\build.ps1 -task %1 ;exit $LASTEXITCODE"

if %ERRORLEVEL% == 0 goto OK
	echo Error running build. 
exit /B %ERRORLEVEL%

:OK