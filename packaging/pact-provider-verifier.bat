@echo off

SET RUNNING_PATH=%~dp0

IF "%~1"=="" (
    %RUNNING_PATH%pact.exe verifier --help
    EXIT /B %ERRORLEVEL%
) ELSE (
    %RUNNING_PATH%pact.exe verifier %*
    EXIT /B %ERRORLEVEL%
)