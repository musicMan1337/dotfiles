@echo off
setlocal enabledelayedexpansion

REM dlink.bat - Create symbolic links to sync files/folders to Google Drive
REM Usage: dlink <source> -d <destination> [-r]
REM Example: dlink . -d path\to\destination -r
REM source can be a file or directory
REM -d: destination relative to C:\drive-sync\
REM -r: recursively link all items in source directory

set "BASE_SYNC_DIR=C:\drive-sync"
set "SOURCE_DIR="
set "DEST_PATH="
set "RECURSIVE=0"

REM Parse arguments
:parse_args
if "%~1"=="" goto validate_args
if "%~1"=="-d" (
    set "DEST_PATH=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="-r" (
    set "RECURSIVE=1"
    shift
    goto parse_args
)
if "!SOURCE_DIR!"=="" (
    set "SOURCE_DIR=%~1"
    shift
    goto parse_args
)
shift
goto parse_args

:validate_args
if "!SOURCE_DIR!"=="" (
    echo Error: Missing source directory
    goto usage
)
if "!DEST_PATH!"=="" (
    echo Error: Missing destination path
    goto usage
)

REM Convert source to absolute path
if "!SOURCE_DIR!"=="." (
    set "SOURCE_DIR=%CD%"
) else (
    REM Check if it's already an absolute path
    echo !SOURCE_DIR! | findstr /R "^[A-Za-z]:" >nul
    if errorlevel 1 (
        set "SOURCE_DIR=%CD%\!SOURCE_DIR!"
    )
)

REM Build full destination path
set "FULL_DEST_DIR=%BASE_SYNC_DIR%\!DEST_PATH!"

REM Create destination directory if it doesn't exist
if not exist "!FULL_DEST_DIR!" mkdir "!FULL_DEST_DIR!"

echo Source: !SOURCE_DIR!
echo Destination: !FULL_DEST_DIR!
echo Recursive: !RECURSIVE!
echo.

REM Check if source exists
if not exist "!SOURCE_DIR!" (
    echo Error: Source directory/file does not exist: !SOURCE_DIR!
    exit /b 1
)

REM Execute linking
if "!RECURSIVE!"=="1" (
    echo Linking all items recursively from source directory...
    call :link_recursive "!SOURCE_DIR!" "!FULL_DEST_DIR!"
) else (
    REM Non-recursive: link the source itself
    if exist "!SOURCE_DIR!\*" (
        REM It's a directory
        echo Creating directory junction: !FULL_DEST_DIR! -^> !SOURCE_DIR!
        mklink /J "!FULL_DEST_DIR!" "!SOURCE_DIR!"
    ) else (
        REM It's a file
        echo Creating file symlink: !FULL_DEST_DIR! -^> !SOURCE_DIR!
        mklink "!FULL_DEST_DIR!" "!SOURCE_DIR!"
    )
)

echo.
echo Linking complete!
goto :eof

:link_recursive
set "SRC_DIR=%~1"
set "DEST_DIR=%~2"

REM Ensure destination exists
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

REM Link all items in source directory
for /f "delims=" %%i in ('dir /b /a "%SRC_DIR%"') do (
    call :process_item "%%i"
)
goto :eof

:process_item
set "ITEM_NAME=%~1"
set "SRC_ITEM=%SRC_DIR%\%~1"
set "DEST_ITEM=%DEST_DIR%\%~1"

if exist "%SRC_ITEM%\*" (
    REM It's a directory
    echo Creating directory junction: "%DEST_ITEM%" -^> "%SRC_ITEM%"
    mklink /J "%DEST_ITEM%" "%SRC_ITEM%"
) else (
    REM It's a file
    echo Creating file symlink: "%DEST_ITEM%" -^> "%SRC_ITEM%"
    mklink "%DEST_ITEM%" "%SRC_ITEM%"
)
goto :eof

:usage
echo Usage: dlink ^<source^> -d ^<destination^> [-r]
echo Example: dlink . -d path\to\destination -r
echo.
echo Arguments:
echo   source        Source directory or file (use . for current directory)
echo   -d dest       Destination path relative to C:\drive-sync\
echo   -r            Recursive mode (link all items in source directory)
exit /b 1