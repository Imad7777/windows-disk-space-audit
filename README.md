# windows-disk-space-audit

A [WorkBuddy](https://www.workbuddy.cn) agent skill for **read-only Windows disk space auditing** (focused on the C: drive), with a graded cleanup report and battle-tested execution pitfalls.

一个 [WorkBuddy](https://www.workbuddy.cn) Agent 技能：**只读审查 Windows 磁盘（尤其 C 盘）空间占用**，产出分级清理报告，并沉淀了执行清理阶段的实战坑。

---

# 🇬🇧 English

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

---

# 🇨🇳 中文

## 使用方法

### 1. 安装

把整个文件夹复制到 WorkBuddy 技能目录：

```
C:\Users\<你>\.workbuddy\skills\windows-disk-space-audit\
├── SKILL.md        # 技能主文件（流程 + 分级标准 + 实战坑）
└── scripts\
    ├── batchA.ps1   # 用户目录 / AppData 直接子目录扫描
    ├── batchB.ps1   # Windows / Program Files / ProgramData / Users
    ├── batchC.ps1   # 对 >1 GB 大目录再钻一层
    └── batchD.ps1   # 定点：临时目录 / 缓存 / 回收站 / 系统残留
```

无任何依赖——只需要 PowerShell 5.1 和 Python（可选，用于 Unicode 安全的目录名检查）。

### 2. 触发提示词

装好后在 WorkBuddy 里对 Agent 用自然语言说一句话即可触发：

| 场景 | 提示词示例 |
|---|---|
| 审查（默认只读） | 「C盘快满了，看看哪些能清理」 |
| 审查 | 「帮我排查一下磁盘占用」 |
| 审查 | 「看看 C 盘空间不够了怎么办」 |
| 清理（审查确认后） | 「B 类帮我清理掉」 |
| 清理 | 「把这个软件删了」（会先备份再删） |

技能默认**只读审查**；只有当你看过报告、明确确认要删的目标之后，才会执行删除。

### 3. 典型工作流

```
你说「C盘快满了」
   ↓
Agent 分四批扫描（每批 3~5 分钟，后台运行）
   ↓
产出分级报告：🟢 零风险缓存 / 🟡 确认后删 / 🔵 建议迁移卸载 / 🔴 绝对不碰 / ⚙️ 系统级回收
   ↓
你勾选要删的项目（如「B 类清掉」）
   ↓
Agent 备份 → 分批删除（每批 ≤10 个）→ 逐批核对剩余空间 → 清空回收站
```

## 它做什么

**1. 审查（默认）** — 只读扫描，产出分级报告，报告开头明确"仅审查，未做任何删除或移动"。

- 🟢 **A 类** — 零风险缓存与临时文件（pip/npm 缓存、Temp、CrashDumps、旧迁移备份）
- 🟡 **B 类** — 确认后可删的残留（`*-updater` 旧安装包、安装解压缓存、多版本并存目录）
- 🔵 **C 类** — 大户但是数据/软件（聊天记录、游戏、开发工具 → 建议迁移或卸载）
- 🔴 **D 类** — 绝对不要碰（`Windows\Installer`、`WinSxS`、`Package Cache`、`swapfile.sys`）
- ⚙️ **E 类** — 需管理员的系统级回收（DISM 组件清理、`$WINDOWS.~BT` 交系统设置）

**2. 清理（用户明确确认后）** — 个人目录**先备份到另一块盘**（robocopy + 文件数逐项校验）→ 分批删除（每批 ≤10 个）→ 逐批验证 → 清空回收站。

## 为什么不用现成清理工具

这个技能沉淀了真实跑出来的非显而易见的坑：

- **PowerShell 工具 stdout 可能静默为空** — 先探测，失败就 `Out-File` 落盘再用 Read 读。
- **全盘 hashtable 聚合会内存溢出** — 改用"按父目录分批 Measure-Object 求和"（脚本已附带）。
- **junction/别名链接会骗人**（`.codex → E:`、`All Users → ProgramData`）— 用 `LinkType` 识别，避免重复计算。
- **删了 ≠ 释放了**：沙箱删除钩子可能把删除转进回收站——实测删 15 GB 空间纹丝不动，最后在 `C:\$Recycle.Bin` 里翻出 13.76 GB。每批删除后必须重新量剩余空间，收尾经用户同意 `Clear-RecycleBin`。
- **认不出的大目录**（如 `%LOCALAPPDATA%\<GUID>\…`）— 报事实不猜死，建议**改名观察一周**。
- **权限规则拦截就尊重**：agent 应用自己的数据目录（如 `.workbuddy\logs`）被规则保护时不重试、不绕路。

## 安全约定

- 默认**只读**，未经用户确认绝不删除任何东西。
- 个人目录删除前**必须**先整目录备份到另一块盘并校验文件数一致。
- `Windows\Installer`、`WinSxS`、`System32`、`ProgramData\Package Cache` 是硬性禁区。
- 分寸细节（如 `$WINDOWS.~BT` 最近仍被写入时交给系统设置处理）见 `SKILL.md`。

## License

MIT
