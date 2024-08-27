# Function to create symlinks for all files and directories within a given directory
function Create-Links ($SourceDir) {
    $SourceDir = Resolve-Path -Path $SourceDir

    # Process directories
    Get-ChildItem -Path $SourceDir -Directory | ForEach-Object {
        $Link = Join-Path -Path $env:USERPROFILE -ChildPath $_.Name
        $Target = $_.FullName
        Check-And-Create-Link -Link $Link -Target $Target -IsDir $true
    }

    # Process files
    Get-ChildItem -Path $SourceDir -File | ForEach-Object {
        $Link = Join-Path -Path $env:USERPROFILE -ChildPath $_.Name
        $Target = $_.FullName
        Check-And-Create-Link -Link $Link -Target $Target -IsDir $false
    }
}

# Function to create a symlink for a single file
function Auto-Link ($Target) {
    $Target = Resolve-Path -Path $Target
    $Link = $Target.Path.Replace("$env:USERPROFILE\dotfiles\", "$env:USERPROFILE\")
    Check-And-Create-Link -Link $Link -Target $Target -IsDir $false
}

# Function to create a symlink for a directory
function Auto-Directory-Link ($Target) {
    $Target = Resolve-Path -Path $Target
    $Link = $Target.Path.Replace("$env:USERPROFILE\dotfiles\", "$env:USERPROFILE\")
    Check-And-Create-Link -Link $Link -Target $Target -IsDir $true
}

# Function to check and create a symlink
function Check-And-Create-Link ($Link, $Target, $IsDir) {
    if (-not $Link) {
        Write-Host "Link is missing!" -ForegroundColor Red
        return
    }

    if (-not $Target) {
        Write-Host "Target is missing!" -ForegroundColor Red
        return
    }

    $LinkExists = Test-Path -Path $Link

    if ($LinkExists) {
        $LinkTarget = (Get-Item -Path $Link).Target

        if ($LinkTarget -eq $Target) {
            if ($IsDir) {
                Write-Host "Linked directory already exists:"
            } else {
                Write-Host "Linked file already exists:"
            }
            Write-Host "$Link <=== $Target"
            Write-Host
            return
        } else {
            Write-Host "Deleting $Link"
            if ($IsDir) {
                Remove-Item -Path $Link -Recurse -Force
            } else {
                Remove-Item -Path $Link -Force
            }
        }
    }

    Write-Host "Creating new symlink..."
    if ($IsDir) {
        New-Item -ItemType Junction -Path $Link -Target $Target
    } else {
        New-Item -ItemType SymbolicLink -Path $Link -Target $Target
    }
    Write-Host
}

# Run Links
Create-Links "$env:USERPROFILE\dotfiles\bash"
Create-Links "$env:USERPROFILE\dotfiles\zsh"
Create-Links "$env:USERPROFILE\dotfiles\git"

Auto-Link "$env:USERPROFILE\dotfiles\language-configs\javascript\.eslintrc.json"

Auto-Directory-Link "$env:USERPROFILE\dotfiles\hereDocs"
Auto-Directory-Link "$env:USERPROFILE\dotfiles\language-configs"

# Start-Process to keep the window open at the end
function KeepWindowOpen {
    Write-Host "======================================================================="
    Write-Host
    Read-Host "Symlinks created! Press any key to close this window..."
}

# Keep the command prompt window open
KeepWindowOpen
