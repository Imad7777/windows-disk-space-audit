# Batch B: direct children of system + program dirs, plus C:\ root overview
# Usage: powershell -ExecutionPolicy Bypass -File batchB.ps1 [-Out C:\temp\batchB.txt]
param(
    [string]$Out = "$env:TEMP\batchB.txt"
)
$ErrorActionPreference = 'SilentlyContinue'

function DirMB($p) {
    $s = (Get-ChildItem -LiteralPath $p -Recurse -File -Force -ErrorAction SilentlyContinue |
          Measure-Object -Property Length -Sum).Sum
    if ($null -eq $s) { return 0 }
    return [math]::Round($s / 1MB, 1)
}

$parents = @('C:\Windows', 'C:\Program Files', 'C:\Program Files (x86)', 'C:\ProgramData', 'C:\Users')
foreach ($p in $parents) {
    "== PARENT: $p =="
    $links = Get-ChildItem -LiteralPath $p -Force -Directory | Where-Object { $_.LinkType -ne $null }
    foreach ($l in $links) { Write-Output ("  [LINK] {0} ({1} -> {2})" -f $l.Name, $l.LinkType, ($l.Target -join ';')) }
    $rows = foreach ($d in (Get-ChildItem -LiteralPath $p -Force -Directory | Where-Object { $_.LinkType -eq $null })) {
        [pscustomobject]@{ MB = DirMB $d.FullName; Name = $d.FullName }
    }
    $rows | Sort-Object MB -Descending | Select-Object -First 25 |
        ForEach-Object { Write-Output ("  {0,10} MB  {1}" -f $_.MB, $_.Name) }
}

"== C:\ ROOT FILES =="
Get-ChildItem -LiteralPath 'C:\' -Force -File | ForEach-Object {
    Write-Output ("  {0,10} MB  [FILE] {1}  (last write {2})" -f [math]::Round($_.Length/1MB,1), $_.Name, $_.LastWriteTime)
}

"== OTHER TOP-LEVEL DIRS ON C:\ =="
$known = @('Windows','Program Files','Program Files (x86)','ProgramData','Users','$Recycle.Bin')
$rows2 = foreach ($d in (Get-ChildItem -LiteralPath 'C:\' -Force -Directory | Where-Object { $known -notcontains $_.Name })) {
    [pscustomobject]@{ MB = DirMB $d.FullName; Name = $d.FullName }
}
$rows2 | Sort-Object MB -Descending | Select-Object -First 15 |
    ForEach-Object { Write-Output ("  {0,10} MB  {1}" -f $_.MB, $_.Name) }
Write-Output "DONE B"
