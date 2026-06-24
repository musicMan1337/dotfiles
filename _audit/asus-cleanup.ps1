# RUN AS ADMIN. Removes ASUS / ArmouryCrate remnants left after Apps uninstall.
# Notable: AsIO2/AsIO3 drivers have CVEs (CVE-2018-18537, CVE-2020-15368) -
# arbitrary kernel R/W from unprivileged users. Remove these for real security wins.

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host 'NOT ELEVATED. Re-launch PowerShell as Administrator.' -ForegroundColor Red
    return
}

Write-Host 'Stopping services...' -ForegroundColor Yellow
'asComSvc','AsusCertService','LightingService','asus','asusm','AsusUpdateCheck' |
    ForEach-Object { Stop-Service -Name $_ -Force -ErrorAction SilentlyContinue }

Write-Host 'Deleting services...' -ForegroundColor Yellow
'asComSvc','AsusCertService','LightingService','asus','asusm','AsusUpdateCheck',
'AsIO2','AsIO3' |
    ForEach-Object { sc.exe delete $_ | Out-Null }

Write-Host 'Disabling/removing scheduled tasks...' -ForegroundColor Yellow
Get-ScheduledTask | Where-Object { $_.TaskPath -match '\\ASUS\\' -or $_.TaskName -match 'Asus|Armoury|Aura' } |
    ForEach-Object {
        try { Unregister-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -Confirm:$false -ErrorAction Stop }
        catch { Disable-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -ErrorAction SilentlyContinue | Out-Null }
        Write-Host "  $($_.TaskPath)$($_.TaskName)"
    }

Write-Host 'Removing driver .sys files...' -ForegroundColor Yellow
'AsIO2.sys','AsIO3.sys','AsIO.sys','AsUpIO.sys','asacpi.sys','atkacpi.sys','atkwmiacpi.sys' |
    ForEach-Object { Remove-Item "$env:WINDIR\System32\drivers\$_" -Force -ErrorAction SilentlyContinue }

Write-Host 'Removing ASUS folders...' -ForegroundColor Yellow
'C:\Program Files\ASUS','C:\Program Files (x86)\ASUS','C:\ProgramData\ASUS',
"$env:LOCALAPPDATA\ASUS","$env:APPDATA\ASUS",
'C:\Program Files\Armoury Crate','C:\Program Files (x86)\Armoury Crate Lite Service' |
    ForEach-Object { if (Test-Path $_) { Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue; Write-Host "  $_" } }

Write-Host 'Removing registry keys...' -ForegroundColor Yellow
'HKLM:\SOFTWARE\ASUS','HKLM:\SOFTWARE\WOW6432Node\ASUS','HKCU:\SOFTWARE\ASUS',
'HKLM:\SYSTEM\CurrentControlSet\Services\AsIO2',
'HKLM:\SYSTEM\CurrentControlSet\Services\AsIO3',
'HKLM:\SYSTEM\CurrentControlSet\Services\AsusCertService',
'HKLM:\SYSTEM\CurrentControlSet\Services\asComSvc',
'HKLM:\SYSTEM\CurrentControlSet\Services\LightingService' |
    ForEach-Object { if (Test-Path $_) { Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue; Write-Host "  $_" } }

Write-Host "`nDone. REBOOT to unload AsIO2/AsIO3 from kernel memory." -ForegroundColor Green
