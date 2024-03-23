@echo off

SET RUNNING_PATH=%~dp0
echo %RUNNING_PATH%

:: Tell Bundler where the Gemfile and gems are.
set BUNDLE_IGNORE_CONFIG=
set RUBYGEMS_GEMDEPS=
set BUNDLE_APP_CONFIG=
set BUNDLE_FROZEN=1
set RACK_ENV=production

:: Run the actual app using the bundled Ruby interpreter, with Bundler activated.
@"%RUNNING_PATH%\..\bin\ruby.exe" "%RUNNING_PATH%\pact-broker-app.rb" %*

GOTO :EOF

:RESOLVE
SET %2=%~f1
GOTO :EOF