@echo off
setlocal

::::::::::
:: Bash ::
::::::::::
set "LINK=\Users\derek\.bashrc"
set "TARGET=\Users\derek\dotfiles\bash\.bashrc"
call :CheckAndCreateLink "%LINK%" "%TARGET%"

set "LINK=\Users\derek\.bashrc.d"
set "TARGET=\Users\derek\dotfiles\bash\.bashrc.d"
call :CheckAndCreateDirectoryLink "%LINK%" "%TARGET%"

set "LINK=\Users\derek\.config"
set "TARGET=\Users\derek\dotfiles\bash\.config"
call :CheckAndCreateDirectoryLink "%LINK%" "%TARGET%"

:::::::::
:: Git ::
:::::::::
set "LINK=\Users\derek\.gitconfig"
set "TARGET=\Users\derek\dotfiles\git\.gitconfig"
call :CheckAndCreateLink "%LINK%" "%TARGET%"

set "LINK=\Users\derek\.gitattributes"
set "TARGET=\Users\derek\dotfiles\git\.gitattributes"
call :CheckAndCreateLink "%LINK%" "%TARGET%"

:::::::::::::::
:: Languages ::
:::::::::::::::
set "LINK=\Users\derek\language-configs"
set "TARGET=\Users\derek\dotfiles\language-configs"
call :CheckAndCreateDirectoryLink "%LINK%" "%TARGET%"

::::::::::
:: Misc ::
::::::::::
set "LINK=\Users\derek\hereDocs"
set "TARGET=\Users\derek\dotfiles\hereDocs"
call :CheckAndCreateDirectoryLink "%LINK%" "%TARGET%"

REM Keep the command prompt window open
echo =======================================================================
echo.
set /p "pause=Symlinks created! Press any key to close this window..."

:::::::::::::::
:: Functions ::
:::::::::::::::
:CheckAndCreateDirectoryLink
call :CheckAndCreateLink %1 %2 true
exit /b

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
