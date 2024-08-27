@echo off
setlocal

:: Note: mklink exoects the arg order to be "link" (new file/dir) then "target" (existing file/dir)

:::::::::::::::
:: Run Links ::
:::::::::::::::
call :create_links "%USERPROFILE%\dotfiles\bash"
call :create_links "%USERPROFILE%\dotfiles\zsh"
call :create_links "%USERPROFILE%\dotfiles\git"

call :AutoLink "%USERPROFILE%\dotfiles\language-configs\javascript\.eslintrc.json"

call :AutoDirectoryLink "%USERPROFILE%\dotfiles\hereDocs"
call :AutoDirectoryLink "%USERPROFILE%\dotfiles\language-configs"

REM Keep the command prompt window open
echo =======================================================================
echo.
set /p "pause=Symlinks created! Press any key to close this window..."

:::::::::::::::
:: Functions ::
:::::::::::::::
REM Function to loop over the contents of a directory
:create_links
set "SOURCE_DIR=%~1"

for /d %%d in ("%SOURCE_DIR%\*") do (
  set "LINK=%USERPROFILE%\%%~nxd"
  set "TARGET=%%d"
  call :check_and_create_directory_link "%LINK%" "%TARGET%"
)

for %%f in ("%SOURCE_DIR%\*") do (
  if not exist "%%f\" (
    set "LINK=%USERPROFILE%\%%~nxf"
    set "TARGET=%%f"
    call :check_and_create_link "%LINK%" "%TARGET%"
  )
)
exit /b

:::::::::::::::::::::::::

:AutoDirectoryLink
set "TARGET=%~1"

@REM Sets the link to the target path minus the "dotfiles\" part
for /f "tokens=2,* delims=dotfiles\" %%a in ("%TARGET%") do (
  set "LINK=%USERPROFILE%\%%b"
)

call :CheckAndCreateDirectoryLink "%LINK%" "%TARGET%"
exit /b

:::::::::::::::::::::::::

:AutoLink
set "TARGET=%~1"

@REM Sets the link to the target path minus the "dotfiles\" part
for /f "tokens=2,* delims=dotfiles\" %%a in ("%TARGET%") do (
  set "LINK=%USERPROFILE%\%%b"
)

call :CheckAndCreateLink "%LINK%" "%TARGET%"
exit /b

:::::::::::::::::::::::::

:CheckAndCreateDirectoryLink
call :CheckAndCreateLink %1 %2 true
exit /b

:::::::::::::::::::::::::

:CheckAndCreateLink
@REM %1 - LINK (the symbolic link path)
@REM %2 - TARGET (the target path)
@REM %3 - IS_DIR (true if the link is a directory, false if it is a file)
set LINK=%~1
set TARGET=%~2
set IS_DIR=%~3

if "%LINK%" == "" (
  echo Link is missing!
  exit /b
)

if "%TARGET%" == "" (
  echo Target is missing!
  exit /b
)

@REM Use PowerShell to check if the LINK points to the TARGET
for /f %%i in ('powershell -command "(Get-Item -Path \"%LINK%\").Target"') do set LINK_TARGET=%%i

@REM Compare the current link target with the desired target
if "%LINK_TARGET%" == "%TARGET%" (
  if "%IS_DIR%" == "true" (
    echo Linked directory already exists:
  ) else (
    echo Linked file already exists:
  )
  echo     %LINK% ^<===^> %TARGET%
  echo.
  exit /b
)

if exist "%LINK%" (
  echo Deleting %LINK%
  if "%IS_DIR%" == "true" (
    rmdir /s /q "%LINK%"
  ) else (
    del     "%LINK%"
  )
)

echo Creating new symlink...
if "%IS_DIR%" == "true" (
  mklink /d "%LINK%" "%TARGET%"
) else (
  mklink "%LINK%" "%TARGET%"
)
echo.
exit /b
