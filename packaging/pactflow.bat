@echo off

SET RUNNING_PATH=%~dp0
IF "%~1"=="" (
    %RUNNING_PATH%pact.exe pactflow --help
    EXIT /B %ERRORLEVEL%
) ELSE (
    %RUNNING_PATH%pact.exe pactflow %*
    EXIT /B %ERRORLEVEL%
)