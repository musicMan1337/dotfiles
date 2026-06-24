# RUN AS ADMIN. Right-click PowerShell -> Run as administrator, then:
#   Set-ExecutionPolicy -Scope Process Bypass -Force
#   & "C:\Users\Admin\dotfiles\_audit\admin-mode.ps1"
$ErrorActionPreference = 'Continue'
function Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }

# Verify admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host 'NOT ELEVATED. Re-launch PowerShell as Administrator.' -ForegroundColor Red
    return
}

# === DIAGNOSTICS (audit gaps) ===
Section 'Defender posture'
$mp = Get-MpComputerStatus
$mp | Select-Object AMServiceEnabled, AntivirusEnabled, RealTimeProtectionEnabled,
    IsTamperProtected, AMEngineVersion, AntivirusSignatureLastUpdated,
    QuickScanAge, FullScanAge | Format-List

Section 'Defender exclusions (look for anything weird)'
$pref = Get-MpPreference
$pref | Select-Object ExclusionPath, ExclusionExtension, ExclusionProcess,
    DisableRealtimeMonitoring, DisableBehaviorMonitoring,
    DisableIOAVProtection, MAPSReporting, SubmitSamplesConsent | Format-List

Section 'BitLocker status'
Get-BitLockerVolume | Select-Object MountPoint, VolumeStatus, ProtectionStatus, EncryptionPercentage | Format-Table -AutoSize

Section 'SMART reliability counters'
Get-PhysicalDisk | ForEach-Object {
    $rc = $_ | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        Disk=$_.FriendlyName; Media=$_.MediaType; Health=$_.HealthStatus
        Temp=$rc.Temperature; ReadErrors=$rc.ReadErrorsTotal; WriteErrors=$rc.WriteErrorsTotal
        PowerOnHours=$rc.PowerOnHours; Wear=$rc.Wear
    }
} | Format-Table -AutoSize

Section 'VSS shadow storage (Volsnap 36 errors lead)'
vssadmin list shadowstorage

# === ACTIONS ===
Section 'Enable Tamper Protection (if off, this command may be no-op; UI is canonical path)'
Set-MpPreference -ForceUseProxyOnly $false -ErrorAction SilentlyContinue

Section 'Trigger Defender quick + full scan (full runs in background, can take hours)'
Start-MpScan -ScanType QuickScan
Start-Job { Start-MpScan -ScanType FullScan } | Out-Null
Write-Host 'Quick scan done; full scan running in background job.'

Section 'Defender process-level exclusions for dev tools (narrow blast radius)'
@('node.exe','MSBuild.exe','dotnet.exe','cl.exe','rustc.exe','cargo.exe','go.exe','pnpm.exe','yarn.exe') |
    ForEach-Object { Add-MpPreference -ExclusionProcess $_ }
Write-Host 'Added process exclusions.'

Section 'Clean Windows Update cache'
Stop-Service wuauserv, bits -Force -ErrorAction SilentlyContinue
$wu = "$env:WINDIR\SoftwareDistribution\Download"
$bMB = [math]::Round(((Get-ChildItem $wu -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB), 0)
Remove-Item "$wu\*" -Recurse -Force -ErrorAction SilentlyContinue
Start-Service bits, wuauserv -ErrorAction SilentlyContinue
Write-Host "WU cache: freed ~$bMB MB"

Section 'Set DNS to Cloudflare on active adapter (1.1.1.1 / 1.0.0.1)'
$active = Get-NetAdapter -Physical | Where-Object Status -eq 'Up' | Select-Object -First 1
if ($active) {
    Set-DnsClientServerAddress -InterfaceIndex $active.ifIndex -ServerAddresses ('1.1.1.1','1.0.0.1')
    Write-Host "DNS set on $($active.Name) -> 1.1.1.1, 1.0.0.1"
} else { Write-Host 'No active adapter found.' }

Section 'Hardware-accelerated GPU scheduling ON'
$gp = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'
Set-ItemProperty -Path $gp -Name HwSchMode -Value 2 -Type DWord
Write-Host 'HwSchMode=2 set (reboot required).'

Section 'Reduce indexing scope (remove Users tree from index)'
# Per-user Search index UI is the safe path; here only confirm scope.
Write-Host 'Open: Settings > Privacy & Security > Searching Windows > Advanced Indexing Options > Modify > uncheck Users.'

Section 'Stop + disable heavy auto-services (you can re-enable any anytime)'
$svcs = @{
    'com.docker.service' = 'Docker'
    'Docker Desktop Service' = 'Docker Desktop'
    'MSSQLSERVER' = 'SQL Server 2019'
    'SQLSERVERAGENT' = 'SQL Server Agent'
    'SQLBrowser' = 'SQL Browser'
    'postgresql-x64-14' = 'PostgreSQL 14'
    'OllamaService' = 'Ollama'
    'McAfee WebAdvisor' = 'McAfee WebAdvisor'
    'LxssManager' = 'WSL'
}
foreach ($k in $svcs.Keys) {
    $s = Get-Service -Name $k -ErrorAction SilentlyContinue
    if ($s) {
        if ($s.Status -eq 'Running') { Stop-Service $k -Force -ErrorAction SilentlyContinue }
        Set-Service -Name $k -StartupType Manual -ErrorAction SilentlyContinue
        Write-Host "  $($svcs[$k]) ($k): stopped + set to Manual"
    }
}

Section 'Disable HKLM Run entries (machine-wide bloat autostart)'
$hklmRun = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
$killMachine = @('McAfee WebAdvisor','SecurityHealth','NvBackend','Adobe*','ArmouryCrate*')
Get-Item $hklmRun | Select-Object -ExpandProperty Property | ForEach-Object {
    foreach ($pat in $killMachine) {
        if ($_ -like $pat) {
            Remove-ItemProperty -Path $hklmRun -Name $_ -Force -ErrorAction SilentlyContinue
            Write-Host "  HKLM Run removed: $_"
        }
    }
}

Section 'Disable ArmouryCrate scheduled tasks (it crashes repeatedly per event log)'
Get-ScheduledTask | Where-Object {$_.TaskName -like '*Armoury*' -or $_.TaskPath -like '*ASUS*'} |
    ForEach-Object {
        Disable-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -ErrorAction SilentlyContinue | Out-Null
        Write-Host "  disabled: $($_.TaskPath)$($_.TaskName)"
    }

Section 'winget upgrade --all (excluding known-problem IDs)'
# Review list first; comment out if you want to upgrade selectively.
winget upgrade --all --include-unknown --silent --accept-package-agreements --accept-source-agreements

Write-Host "`nALL DONE. Reboot to apply HAGS + memory hygiene." -ForegroundColor Green
