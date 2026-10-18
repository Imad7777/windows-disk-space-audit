# windows-disk-space-audit

A [WorkBuddy](https://www.workbuddy.cn) agent skill for **read-only Windows disk space auditing** (focused on the C: drive), with a graded cleanup report and battle-tested execution pitfalls.

一个 WorkBuddy Agent 技能：**只读审查 Windows 磁盘（尤其 C 盘）空间占用**，产出分级清理报告，并沉淀了执行清理阶段的实战坑。

## What it does / 做什么

1. **Audit (default) / 默认只审查** — scans in 4 batches (user profile → system dirs → drill-down → targeted cache paths), then produces a graded report:
   - 🟢 A — zero-risk caches/temp (pip/npm cache, Temp, CrashDumps…)
   - 🟡 B — residue to delete after confirmation (`*-updater` dirs, installer caches, old migration backups)
   - 🔵 C — big-but-valuable data/software (chat history, games, dev tools → migrate or uninstall)
   - 🔴 D — never touch (`Windows\Installer`, `WinSxS`, `Package Cache`, `swapfile.sys`)
   - ⚙️ E — system-level reclaim needing admin (DISM component cleanup, `$WINDOWS.~BT` via Settings)
2. **Cleanup (only after explicit user confirmation) / 用户确认后才清理** — backup personal dirs to another drive first (robocopy + file-count verification), batch ≤10 items, verify after each batch.

## Why not just run a disk-cleaner? / 为什么不用现成清理工具

The skill encodes non-obvious pitfalls found in real runs:

- **PowerShell tool stdout may silently return empty** — probe first, fall back to `Out-File` + Read.
- **Whole-disk hashtable aggregation OOMs** — scan by batches of `Measure-Object` sums instead (scripts included).
- **Junctions/aliases lie** (`.codex → E:`, `All Users → ProgramData`) — detect via `LinkType` to avoid double counting.
- **Deletion ≠ freed space**: sandboxed delete hooks may route removals into the Recycle Bin — 15 GB deleted, 0 GB freed, then 13.76 GB found in `C:\$Recycle.Bin`. Always re-measure free space per batch and finish with `Clear-RecycleBin` (with user consent).
- **Unknown big dirs** (e.g. `%LOCALAPPDATA%\<GUID>\…`) — report facts, suggest rename-and-observe for a week instead of guessing.

## Install / 安装

Copy to the WorkBuddy skills directory:

```
C:\Users\<you>\.workbuddy\skills\windows-disk-space-audit\
├── SKILL.md
└── scripts\
    ├── batchA.ps1   # user profile / AppData direct children
    ├── batchB.ps1   # Windows / Program Files / ProgramData / Users
    ├── batchC.ps1   # drill-down into >1 GB dirs
    └── batchD.ps1   # targeted temp/cache/system-residue paths
```

Then just ask your agent: "C盘快满了，看看哪些能清理".

## Safety / 安全约定

- Default is **read-only**. No deletions without explicit user confirmation of a listed target.
- Personal-directory deletions are always preceded by a full backup to another drive + file-count verification.
- `Windows\Installer`, `WinSxS`, `System32`, `ProgramData\Package Cache` are hard no-go zones.

## License

MIT
