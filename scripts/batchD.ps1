# Batch D: targeted temp/cache/system-residue paths (always check these)
# Usage: powershell -ExecutionPolicy Bypass -File batchD.ps1 [-Out C:\temp\batchD.txt]
param(
    [string]$Out = "$env:TEMP\batchD.txt"
)
$ErrorActionPreference = 'SilentlyContinue'

function DirMB($p) {
    $s = (Get-ChildItem -LiteralPath $p -Recurse -File -Force -ErrorAction SilentlyContinue |
          Measure-Object -Property Length -Sum).Sum
    if ($null -eq $s) { return 0 }
    return [math]::Round($s / 1MB, 1)
}

$targets = @(
    "$env:LOCALAPPDATA\Temp",
    'C:\Windows\Temp',
    'C:\Windows\SoftwareDistribution\Download',
    'C:\Windows\Logs',
    'C:\Windows\Minidump',
    'C:\Windows\LiveKernelReports',
    "$env:LOCALAPPDATA\pip\Cache",
    "$env:LOCALAPPDATA\uv\cache",
    "$env:LOCALAPPDATA\npm-cache",
    "$env:LOCALAPPDATA\CrashDumps",
    "$env:LOCALAPPDATA\Google\Chrome\User Data",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data",
    "$env:USERPROFILE\.cache",
    "$env:USERPROFILE\.config",
    "$env:USERPROFILE\.workbuddy",
    "$env:USERPROFILE\.gradle",
    "$env:USERPROFILE\.m2",
    "$env:USERPROFILE\.nuget",
    "$env:USERPROFILE\.codex",
    'C:\$Recycle.Bin',
    'C:\$WINDOWS.~BT',
    'C:\Windows.old',
    'C:\ProgramData\Package Cache',
    'C:\Windows\Installer'
)
foreach ($t in $targets) {
    if (Test-Path -LiteralPath $t) {
        $mb = DirMB $t
        $lw = (Get-Item -LiteralPath $t -Force).LastWriteTime
        Write-Output ("{0,10} MB  {1}  (last write {2})" -f $mb, $t, $lw)
    } else {
        Write-Output ("{0,10}     [MISSING] {1}" -f '', $t)
    }
}
Write-Output "DONE D"
