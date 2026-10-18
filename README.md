# windows-disk-space-audit

An agent skill for **read-only Windows disk space auditing** (focused on the C: drive), with a graded cleanup report and battle-tested execution pitfalls. Works with **any agent platform that reads the `SKILL.md` convention** — WorkBuddy, Claude Code, Codex CLI, etc.

一个 Windows 磁盘空间审查 Agent 技能：**只读审查 Windows 磁盘（尤其 C 盘）空间占用**，产出分级清理报告，并沉淀了执行清理阶段的实战坑。适用于**任何支持 `SKILL.md` 约定的 Agent 平台**——WorkBuddy、Claude Code、Codex 等。

---

# 🇬🇧 English

## How to use

### 1. Prompt triggers

Just talk to your agent in plain language:

| Scenario | Prompt example |
|---|---|
| Audit (read-only by default) | *"My C: drive is almost full, what can be cleaned up?"* |
| Audit | *"Help me investigate disk usage"* |
| Audit | *"C: is running out of space, what should we do?"* |
| Cleanup (after review) | *"Clean up the class-B items"* |
| Cleanup | *"Remove this program"* (backs up first) |

The skill defaults to a **read-only audit**; deletion happens only after you review the report and explicitly confirm the targets.

### 2. Typical workflow

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

## Safety guarantees

- Read-only by default; never deletes anything without explicit user confirmation.
- Personal directories MUST be fully backed up to another drive and file-count-verified before deletion.
- `Windows\Installer`, `WinSxS`, `System32`, and `ProgramData\Package Cache` are hard no-go zones.
- Fine-grained judgment calls (e.g. leaving `$WINDOWS.~BT` to Windows Settings when it was recently written) are documented in `SKILL.md`.

---

# 🇨🇳 中文

## 使用方法

### 1. 触发提示词

在你的 Agent 平台里用自然语言说一句话即可触发：

| 场景 | 提示词示例 |
|---|---|
| 审查（默认只读） | 「C盘快满了，看看哪些能清理」 |
| 审查 | 「帮我排查一下磁盘占用」 |
| 审查 | 「看看 C 盘空间不够了怎么办」 |
| 清理（审查确认后） | 「B 类帮我清理掉」 |
| 清理 | 「把这个软件删了」（会先备份再删） |

技能默认**只读审查**；只有当你看过报告、明确确认要删的目标之后，才会执行删除。

### 2. 典型工作流

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

## 安全约定

- 默认**只读**，未经用户确认绝不删除任何东西。
- 个人目录删除前**必须**先整目录备份到另一块盘并校验文件数一致。
- `Windows\Installer`、`WinSxS`、`System32`、`ProgramData\Package Cache` 是硬性禁区。
- 分寸细节（如 `$WINDOWS.~BT` 最近仍被写入时交给系统设置处理）见 `SKILL.md`。

## License

MIT
