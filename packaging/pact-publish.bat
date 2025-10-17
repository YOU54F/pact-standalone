@echo off

SET RUNNING_PATH=%~dp0
IF "%~1"=="" (
    %RUNNING_PATH%pact.exe broker publish --help
    EXIT /B %ERRORLEVEL%
) ELSE (
    %RUNNING_PATH%pact.exe broker publish %*
    EXIT /B %ERRORLEVEL%
)
