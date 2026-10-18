# Batch C: drill one level into the biggest/unclear dirs found in A/B
# Usage: powershell -ExecutionPolicy Bypass -File batchC.ps1 -Targets "C:\path1","C:\path2"
param(
    [string[]]$Targets = @(),
    [string]$Out = "$env:TEMP\batchC.txt"
)
$ErrorActionPreference = 'SilentlyContinue'

function DirMB($p) {
    $s = (Get-ChildItem -LiteralPath $p -Recurse -File -Force -ErrorAction SilentlyContinue |
          Measure-Object -Property Length -Sum).Sum
    if ($null -eq $s) { return 0 }
    return [math]::Round($s / 1MB, 1)
}

foreach ($t in $Targets) {
    if (-not (Test-Path -LiteralPath $t)) { Write-Output "  [MISSING] $t"; continue }
    "== TARGET: $t =="
    $rows = foreach ($d in (Get-ChildItem -LiteralPath $t -Force -Directory | Where-Object { $_.LinkType -eq $null })) {
        [pscustomobject]@{ MB = DirMB $d.FullName; Name = $d.Name }
    }
    $rows | Sort-Object MB -Descending | Select-Object -First 12 |
        ForEach-Object { Write-Output ("  {0,10} MB  {1}" -f $_.MB, $_.Name) }
    Get-ChildItem -LiteralPath $t -Force -File | Sort-Object Length -Descending | Select-Object -First 5 |
        ForEach-Object { Write-Output ("  {0,10} MB  [FILE] {1}" -f [math]::Round($_.Length/1MB,1), $_.Name) }
}
Write-Output "DONE C"
