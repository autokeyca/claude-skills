---
name: db
description: Development Blitz — process all backlog Kanban tasks in parallel with sub-agents, then audit each before merging. Rapidly clears the backlog.
user-invocable: true
allowed-tools: Read Write Edit Glob Grep Agent Bash TaskCreate TaskUpdate TaskGet TaskList
---

# Development Blitz — Parallel Backlog Sprint

You are launching a Development Blitz. This is an automated process that:
1. Scans ALL sources of pending work (not just Kanban)
2. Filters to actionable tasks (skips deferred/blocked items)
3. Spawns parallel sub-agents to implement each task in isolated worktrees
4. Spawns audit sub-agents after each implementation completes
5. Merges passing work to master, commits, and pushes

## Execution Protocol

### Phase 1: Backlog Assessment — Multi-Source Scan

Gather pending work from ALL of the following sources. Present them in a unified table regardless of origin.

#### Source A: Kanban Board

Query the Kanban board for all tasks with `status IN ('backlog', 'todo', 'in_progress')`:

```
venv/bin/python -c "
import asyncio
from backend.db.session import async_session
from sqlalchemy import text
async def main():
    async with async_session() as s:
        r = await s.execute(text('''
            SELECT t.id::text, t.title, t.status, t.priority, t.description,
                   a.name as assignee, a.runtime
            FROM tasks t
            LEFT JOIN agents a ON t.assigned_agent_id = a.id
            WHERE t.status IN ('backlog', 'todo', 'in_progress')
            ORDER BY t.priority, t.created_at
        '''))
        for row in r:
            print(f'ID={row[0]}|TITLE={row[1]}|STATUS={row[2]}|PRI={row[3]}|DESC={row[4][:200] if row[4] else \"\"}|ASSIGNEE={row[5] or \"unassigned\"}')
asyncio.run(main())
"
```

#### Source B: Memory Files

Read the memory index at the project's auto-memory `MEMORY.md`. Look for:
- `project_*` memories that describe in-progress or planned work
- `feedback_*` memories that reference known bugs or open issues
- Any memory mentioning "TODO", "pending", "planned", "next", or "needs"

#### Source C: CLAUDE.md Known Issues

Scan the project `CLAUDE.md` for:
- Items listed under "Known limitation", "Known gap", "Known issue", or "Known hole"
- Items in version status notes with language like "not yet", "planned", "needs", "TODO"
- Open questions or deferred decisions

#### Source D: Git State

Check for uncommitted work that should be completed:
- `git status` — any modified/untracked files
- `git stash list` — any stashed work
- `git diff --stat` — any staged changes

#### Source E: In-Progress Tasks

Check for tasks marked `in_progress` that may be stalled or completable:
- Kanban tasks stuck in `in_progress` for >24h
- Active soak tests or monitoring that need conclusion

### Phase 2: Triage

Present ALL discovered work items in a unified table with their source. For each, recommend:
- **BLITZ** — can be implemented by a sub-agent autonomously
- **SKIP** — deferred by user, blocked, needs coordination, or requires interactive work
- **NEEDS CLARIFICATION** — description too vague to implement
- **CREATE CARD** — valid work item from Source B/C/D/E that doesn't have a Kanban card yet. Offer to create one before blitzing.

| # | Source | Task | Priority | Recommendation |
|---|--------|------|----------|---------------|
| 1 | Kanban | Kill Channel Feature | medium | BLITZ |
| 2 | CLAUDE.md | PeekPanelOverlay theme inconsistency | low | BLITZ |
| 3 | Memory | Delivery monitor R4/R5 tuning | medium | BLITZ |
| 4 | Kanban | v0.5 — Multi-user | medium | SKIP (deferred) |

Ask the user to confirm the BLITZ set before proceeding. If the user passed arguments to the command (e.g., `/db kill-channel peek-window`), filter to only matching tasks.

For non-Kanban items marked BLITZ, create a Kanban card first so progress is tracked.

### Phase 3: Parallel Implementation

For each BLITZ task, spawn a sub-agent with `isolation: "worktree"`:

- **Agent type**: Pick the best specialist (`react-specialist` for frontend, `postgres-pro` for DB, `general-purpose` for mixed)
- **Prompt must include**:
  - The full task description from Kanban
  - Relevant CLAUDE.md patterns and conventions
  - Specific files/modules to modify (research first if needed)
  - Test requirements (add tests for new backend routes)
  - Success criteria: what "done" looks like
  - File boundaries to prevent cross-agent conflicts

**Concurrency rules**:
- Max 4 parallel implementation agents at once (resource constraint)
- Tasks touching the same files must be sequential, not parallel
- Each agent works in its own worktree — no merge conflicts possible

### Phase 4: Audit

After each implementation agent completes, spawn an audit agent for that worktree:

```
Agent({
  description: "Audit [task name]",
  prompt: "Audit the changes in worktree at [path]. Check: ...",
})
```

Audit checks:
1. `git diff HEAD~1` — review all changes
2. No unintended side effects or logic changes
3. Tests pass: `venv/bin/python -m pytest backend/tests/ --tb=short -q`
4. No security issues (injection, XSS, etc.)
5. Follows project patterns from CLAUDE.md
6. No leftover debug code, console.logs, or TODOs

Report: PASS or FAIL with specific issues.

### Phase 5: Merge & Deploy

For each PASS:
1. Cherry-pick the commit from the worktree to master
2. Run full test suite on master
3. Push to GitHub
4. Update the Kanban task status to `done`
5. Restart backend if needed (check for active relays first!)

For each FAIL:
1. Report the issues to the user
2. Option to fix and re-audit, or skip

### Phase 6: Summary

Present a final report:

| Task | Status | Commit | Notes |
|------|--------|--------|-------|
| Kill Channel | ✅ Merged | abc1234 | 3 files, 12 tests |
| Peek Phase 2 | ❌ Failed audit | — | Missing error handling |
| ... | ... | ... | ... |

## Important Rules

- **Never force-push or amend commits on master**
- **Always check for active relays before restarting** (`ls /tmp/symphony/signals/.active-*`)
- **Never restart during an active relay** — wait for it to complete
- **Always push after committing** (per project rules)
- **Use rich markdown formatting** in all Symphony channel responses
- **Update Kanban status** as tasks progress: `in_progress` when starting, `done` when merged
- **Skip v0.5 tasks** unless the user explicitly includes them — they're deferred
