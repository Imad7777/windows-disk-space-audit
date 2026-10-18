# Batch A: direct children of USERPROFILE, AppData\Local, AppData\Roaming
# Usage: powershell -ExecutionPolicy Bypass -File batchA.ps1
# Output goes to stdout; redirect or tee it if the tool host swallows stdout.
param()

function DirMB($p) {
    $s = (Get-ChildItem -LiteralPath $p -Recurse -File -Force -ErrorAction SilentlyContinue |
          Measure-Object -Property Length -Sum).Sum
    if ($null -eq $s) { return 0 }
    return [math]::Round($s / 1MB, 1)
}

$parents = @($env:USERPROFILE, $env:LOCALAPPDATA, $env:APPDATA)
foreach ($p in $parents) {
    "== PARENT: $p =="
    # junctions / symlinks at this level (excluded from size sums)
    $links = Get-ChildItem -LiteralPath $p -Force -Directory | Where-Object { $_.LinkType -ne $null }
    foreach ($l in $links) { Write-Output ("  [LINK] {0} ({1} -> {2})" -f $l.Name, $l.LinkType, ($l.Target -join ';')) }
    # child dirs with sizes (junctions excluded, listed separately above)
    $rows = foreach ($d in (Get-ChildItem -LiteralPath $p -Force -Directory | Where-Object { $_.LinkType -eq $null })) {
        [pscustomobject]@{ MB = DirMB $d.FullName; Name = $d.FullName }
    }
    $rows | Sort-Object MB -Descending | ForEach-Object { Write-Output ("  {0,10} MB  {1}" -f $_.MB, $_.Name) }
    # big loose files directly under the parent
    Get-ChildItem -LiteralPath $p -Force -File | Where-Object { $_.Length -gt 100MB } |
        ForEach-Object { Write-Output ("  {0,10} MB  [FILE] {1}" -f [math]::Round($_.Length/1MB,1), $_.FullName) }
}
Write-Output "DONE A"
