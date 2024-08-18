@echo off
setlocal

@REM Bash symlinks
set "LINK=\Users\derek\.bashrc"
set "TARGET=\Users\derek\dotfiles\bash\.bashrc"
call :CheckAndCreateLink "%LINK%" "%TARGET%"

set "LINK=\Users\derek\.bashrc.d"
set "TARGET=\Users\derek\dotfiles\bash\.bashrc.d"
call :CheckAndCreateLink "%LINK%" "%TARGET%" true

set "LINK=\Users\derek\.config"
set "TARGET=\Users\derek\dotfiles\bash\.config"
call :CheckAndCreateLink "%LINK%" "%TARGET%" true

:CheckAndCreateLink
@REM %1 - LINK (the symbolic link path)
@REM %2 - TARGET (the target path)
@REM %3 - IS_DIR (true if the link is a directory, false if it is a file)
set LINK=%~1
set TARGET=%~2
set IS_DIR=%~3

if "%LINK%" == "" exit /b
if "%TARGET%" == "" exit /b

echo.

@REM Use PowerShell to check if the LINK points to the TARGET
for /f %%i in ('powershell -command "(Get-Item -Path \"%LINK%\").Target"') do set LINK_TARGET=%%i

@REM Compare the current link target with the desired target
if "%LINK_TARGET%" == "%TARGET%" (
  if "%IS_DIR%" == "true" (
    echo The dirictory %LINK% is already pointing to %TARGET%.
  ) else (
    echo The link %LINK% is already pointing to %TARGET%.
  )
  exit /b
)

if exist "%LINK%" (
  echo Deleting existing link: %LINK%
  if "%IS_DIR%" == "true" (
    rmdir /s /q "%LINK%"
  ) else (
    del "%LINK%"
  )
)

echo Creating new symlink...
if "%IS_DIR%" == "true" (
  mklink /d "%LINK%" "%TARGET%"
) else (
  mklink "%LINK%" "%TARGET%"
)
exit /b
