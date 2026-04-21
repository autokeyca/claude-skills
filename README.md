# Claude Skills

Custom user-invocable skills for Claude Code. Installed by cloning into `~/.claude/skills/`.

## Skills

- **`autokey-business`** — AutoKey business reference (company profile, customers, systems, agent fleet).
- **`checkpoint`** (`/cp`) — Save state before a context reset. Writes `pickup.md` + `.pickup-session-id` via an atomic receipt-printing script; auto-injects on next `/clear` via SessionStart hook.
- **`devblitz`** (`/db`) — Parallel backlog sprint with sub-agents + audit pass before merge.
- **`scriptcase`** — ScriptCase 9 app maintenance for AutoKey's AKCRM / AKINV projects.

## Install

```bash
git clone git@github.com:autokeyca/claude-skills.git ~/.claude/skills
```

The `checkpoint` skill additionally needs a SessionStart hook in `~/.claude/settings.json` — see `checkpoint/SKILL.md`.
