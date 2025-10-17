@echo off

SET RUNNING_PATH=%~dp0
IF "%~1"=="" (
    %RUNNING_PATH%pact.exe broker --help
    EXIT /B %ERRORLEVEL%
) ELSE (
    %RUNNING_PATH%pact.exe broker %*
    EXIT /B %ERRORLEVEL%
)
