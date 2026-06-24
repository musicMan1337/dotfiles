# PHASE 1 — RUN AS ADMIN, THEN REBOOT.
# Marks ASUS kernel drivers for deletion (they can't be unloaded while running).
# Also wraps up the round-1 follow-ups.

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host 'NOT ELEVATED. Re-launch PowerShell as Administrator.' -ForegroundColor Red
    return
}

function Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }

Section 'Mark ASUS kernel drivers + service for removal'
'Asusgio2','Asusgio3','AsusUpdateCheck' | ForEach-Object {
    sc.exe config $_ start= disabled | Out-Null
    sc.exe delete $_ 2>&1 | Out-Null
    Write-Host "  $_ : disabled + delete-pending"
}

Section 'Stop + Manual: postgresql-x64-14'
Stop-Service postgresql-x64-14 -Force -ErrorAction SilentlyContinue
Set-Service  postgresql-x64-14 -StartupType Manual -ErrorAction SilentlyContinue
Write-Host '  postgresql-x64-14: stopped, Manual'

Section 'Clean TEMP again (winget cache bloat)'
$bMB = [math]::Round(((Get-ChildItem $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB), 0)
Get-ChildItem $env:TEMP -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
$aMB = [math]::Round(((Get-ChildItem $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB), 0)
Write-Host ("  TEMP: {0} MB -> {1} MB" -f $bMB, $aMB)

Section 'Re-run winget upgrade --all (anything left from round 1)'
winget upgrade --all --include-unknown --silent --accept-package-agreements --accept-source-agreements

Write-Host "`nPHASE 1 DONE. REBOOT NOW. Then run phase 2:" -ForegroundColor Green
Write-Host '   & "C:\Users\Admin\dotfiles\_audit\asus-phase2.ps1"' -ForegroundColor Yellow
