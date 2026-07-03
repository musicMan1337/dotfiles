# User-mode audit/cleanup. Safe to re-run.
$ErrorActionPreference = 'Continue'

function Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }

Section 'Backup HKCU Run keys'
$bak = "$env:USERPROFILE\hkcu-run-backup-$(Get-Date -Format yyyyMMdd-HHmmss).reg"
reg.exe export 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' $bak /y | Out-Null
Write-Host "Backup: $bak"

Section 'Disable startup entries (HKCU Run)'
$toRemove = @(
    'DisplayFusion','Steam','JetBrains Toolbox','EpicGamesLauncher',
    'com.evernote.Evernote','Figma Agent','Docker Desktop','Discord',
    'Teams','Warp'
)
$run = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
foreach ($n in $toRemove) {
    if (Get-ItemProperty -Path $run -Name $n -ErrorAction SilentlyContinue) {
        Remove-ItemProperty -Path $run -Name $n -Force
        Write-Host "  removed: $n"
    }
}
Get-ItemProperty -Path $run | Get-Member -MemberType NoteProperty |
    Where-Object Name -like 'MicrosoftEdgeAutoLaunch*' | ForEach-Object {
        Remove-ItemProperty -Path $run -Name $_.Name -Force
        Write-Host "  removed: $($_.Name)"
    }
Write-Host 'Kept: OneDrive, LGHUB, GoogleDriveFS'

Section 'Create .wslconfig (8GB / 4 cores / 4GB swap)'
$wsl = "$env:USERPROFILE\.wslconfig"
@'
[wsl2]
memory=8GB
processors=4
swap=4GB
localhostForwarding=true
'@ | Set-Content -Path $wsl -Encoding ASCII
Write-Host "Wrote: $wsl"
wsl --shutdown 2>$null

Section 'Clean %TEMP%'
$temp = $env:TEMP
$bMB = [math]::Round(((Get-ChildItem $temp -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB), 0)
Get-ChildItem $temp -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
$aMB = [math]::Round(((Get-ChildItem $temp -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB), 0)
Write-Host ("TEMP: {0} MB -> {1} MB  (freed {2} MB)" -f $bMB, $aMB, ($bMB - $aMB))

Section 'Empty Recycle Bin'
try { Clear-RecycleBin -Force -ErrorAction Stop; Write-Host 'Recycle Bin emptied.' }
catch { Write-Host "Recycle Bin: $($_.Exception.Message)" }

Section 'Clear thumbnail cache'
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache_*.db" -Force -ErrorAction SilentlyContinue
Start-Process explorer.exe
Write-Host 'Thumbnail cache cleared, explorer restarted.'

Section 'Install Everything (voidtools)'
if (-not (Get-Command everything -ErrorAction SilentlyContinue)) {
    winget install --id voidtools.Everything --silent --accept-package-agreements --accept-source-agreements
} else { Write-Host 'Already installed.' }

Write-Host "`nDone." -ForegroundColor Green
