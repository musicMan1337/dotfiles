# PHASE 2 — RUN AS ADMIN, AFTER REBOOT.
# Removes leftover .sys files, folders, and registry keys.
# Drivers are no longer loaded (services were deleted in phase 1).

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host 'NOT ELEVATED. Re-launch PowerShell as Administrator.' -ForegroundColor Red
    return
}
function Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }

Section 'Confirm ASUS drivers are unloaded'
$loaded = Get-CimInstance Win32_SystemDriver -ErrorAction SilentlyContinue |
    Where-Object {$_.Name -match 'Asus|atk|AsIO' -and $_.State -eq 'Running'}
if ($loaded) {
    Write-Host 'STILL LOADED:' -ForegroundColor Red
    $loaded | Select-Object Name, State, PathName | Format-Table -AutoSize
    Write-Host 'Did you reboot after phase 1? Aborting.' -ForegroundColor Red
    return
}
Write-Host '  Clean — no ASUS drivers loaded.' -ForegroundColor Green

Section 'Remove driver .sys files'
'AsIO2.sys','AsIO3.sys','AsIO.sys','AsUpIO.sys','asacpi.sys','atkacpi.sys','atkwmiacpi.sys' |
    ForEach-Object {
        $p = "$env:WINDIR\System32\drivers\$_"
        if (Test-Path $p) { Remove-Item $p -Force; Write-Host "  removed: $_" }
    }

Section 'Remove ASUS folders'
'C:\Program Files\ASUS','C:\Program Files (x86)\ASUS','C:\ProgramData\ASUS',
"$env:LOCALAPPDATA\ASUS","$env:APPDATA\ASUS" |
    ForEach-Object {
        if (Test-Path $_) { Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue; Write-Host "  $_" }
    }

Section 'Remove ASUS registry keys'
'HKLM:\SOFTWARE\ASUS',
'HKLM:\SOFTWARE\WOW6432Node\ASUS',
'HKCU:\SOFTWARE\ASUS',
'HKLM:\SYSTEM\CurrentControlSet\Services\Asusgio2',
'HKLM:\SYSTEM\CurrentControlSet\Services\Asusgio3',
'HKLM:\SYSTEM\CurrentControlSet\Services\AsIO2',
'HKLM:\SYSTEM\CurrentControlSet\Services\AsIO3',
'HKLM:\SYSTEM\CurrentControlSet\Services\AsusUpdateCheck' |
    ForEach-Object {
        if (Test-Path $_) { Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue; Write-Host "  $_" }
    }

Section 'Final ASUS state verification'
$res = [PSCustomObject]@{
    DriversLoaded   = (Get-CimInstance Win32_SystemDriver | Where-Object {$_.Name -match 'Asus|atk|AsIO'}).Count
    ServicesLeft    = (Get-Service | Where-Object {$_.Name -match 'Asus|Armoury|Aura|Lighting'}).Count
    SysFilesLeft    = (Get-ChildItem $env:WINDIR\System32\drivers\AsIO*.sys, $env:WINDIR\System32\drivers\Asus*.sys -ErrorAction SilentlyContinue).Count
    FoldersLeft     = @('C:\Program Files\ASUS','C:\Program Files (x86)\ASUS','C:\ProgramData\ASUS' | Where-Object { Test-Path $_ }).Count
    RegKeysLeft     = @('HKLM:\SOFTWARE\ASUS','HKLM:\SOFTWARE\WOW6432Node\ASUS' | Where-Object { Test-Path $_ }).Count
}
$res | Format-List
if ($res.DriversLoaded + $res.SysFilesLeft + $res.FoldersLeft + $res.RegKeysLeft -eq 0) {
    Write-Host "`nCLEAN. ASUS bloat fully removed." -ForegroundColor Green
} else {
    Write-Host "`nSome remnants persist — likely locked by another process. Manual inspection needed." -ForegroundColor Yellow
}
