# windows-disk-space-audit

[简体中文](README.md) | [English](README.en.md)

---

A [WorkBuddy](https://www.workbuddy.cn) agent skill for **read-only Windows disk space auditing** (focused on the C: drive), with a graded cleanup report and battle-tested execution pitfalls.

---

## How to use

### 1. Install

Copy the whole folder into your WorkBuddy skills directory:

```
C:\Users\<you>\.workbuddy\skills\windows-disk-space-audit\
├── SKILL.md        # Main skill file (workflow + grading standard + pitfalls)
└── scripts\
    ├── batchA.ps1   # Scan direct children of USERPROFILE / AppData
    ├── batchB.ps1   # Windows / Program Files / ProgramData / Users
    ├── batchC.ps1   # Drill one level deeper into >1 GB directories
    └── batchD.ps1   # Targeted: temp dirs / caches / recycle bin / system leftovers
```

No dependencies — only PowerShell 5.1 and Python (optional, for Unicode-safe name checks).

### 2. Prompt triggers

Once installed, just talk to your WorkBuddy agent in plain language:

| Scenario | Prompt example |
|---|---|
| Audit (read-only by default) | *"My C: drive is almost full, what can be cleaned up?"* |
| Audit | *"Help me investigate disk usage"* |
| Audit | *"C: is running out of space, what should we do?"* |
| Cleanup (after review) | *"Clean up the class-B items"* |
| Cleanup | *"Remove this program"* (backs up first) |

The skill defaults to a **read-only audit**; deletion happens only after you review the report and explicitly confirm the targets.

### 3. Typical workflow

```
You say "C: is almost full"
   ↓
Agent scans in 4 batches (3–5 min each, run in background)
   ↓
Produces a graded report:
  🟢 zero-risk caches / 🟡 delete-after-confirm / 🔵 migrate-or-uninstall /
  🔴 never touch / ⚙️ admin-level recovery
   ↓
You pick the items to delete (e.g. "clean class B")
   ↓
Agent backs up → deletes in batches (≤10 each) → verifies free space
per batch → empties the recycle bin
```

---

## What it does

**1. Audit (default)** — Read-only scan producing a graded report; the report opens with an explicit statement that nothing was deleted or moved.

- 🟢 **Class A** — Zero-risk caches and temp files (pip/npm caches, Temp, CrashDumps, stale migration backups)
- 🟡 **Class B** — Removable leftovers after confirmation (stale `*-updater` installers, extracted setup caches, coexisting version dirs)
- 🔵 **Class C** — Big consumers that are real data/software (chats, games, dev tools → suggest migrating or uninstalling)
- 🔴 **Class D** — Never touch (`Windows\Installer`, `WinSxS`, `Package Cache`, `swapfile.sys`)
- ⚙️ **Class E** — Admin-level recovery (DISM component cleanup; `$WINDOWS.~BT` handled via Windows Settings)

**2. Cleanup (only after explicit confirmation)** — Personal directories are **backed up to another drive first** (robocopy + per-file-count verification) → deleted in batches (≤10 each) → verified per batch → recycle bin emptied.

## Why not just run a disk-cleaner?

This skill captures non-obvious pitfalls learned from real runs:

- **The PowerShell tool's stdout can silently come back empty** — probe first; on failure, write output to a file with `Out-File` and read it back.
- **Aggregating the whole drive into one hashtable can OOM** — instead sum per parent directory with batched `Measure-Object` (scripts included).
- **Junctions/alias links lie** (`.codex → E:`, `All Users → ProgramData`) — detect with `LinkType` to avoid double counting.
- **Deleted ≠ freed**: sandbox delete hooks may redirect deletions into the recycle bin — in one real run, 15 GB deleted with zero free-space change; 13.76 GB was later found in `C:\$Recycle.Bin`. Re-measure free space after every batch, and empty the recycle bin with user consent at the end.
- **Unidentifiable large directories** (e.g. `%LOCALAPPDATA%\<GUID>\…`) — report facts without guessing; suggest renaming and observing for a week.
- **Respect permission blocks**: when the agent app's own data dirs (e.g. `.workbuddy\logs`) are protected by rules, don't retry or route around them.

## Safety guarantees

- Read-only by default; never deletes anything without explicit user confirmation.
- Personal directories MUST be fully backed up to another drive and file-count-verified before deletion.
- `Windows\Installer`, `WinSxS`, `System32`, and `ProgramData\Package Cache` are hard no-go zones.
- Fine-grained judgment calls (e.g. leaving `$WINDOWS.~BT` to Windows Settings when it was recently written) are documented in `SKILL.md`.

## License

MIT
