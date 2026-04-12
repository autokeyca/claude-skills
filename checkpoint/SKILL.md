---
name: cp
description: Save memories, state, and update project documentation before a context reset. Produces a continuation prompt for seamless resumption.
disable-model-invocation: true
user-invocable: true
allowed-tools: Read Write Edit Glob Grep Agent Bash
---

# Checkpoint — Save State Before Context Reset

You are about to lose your conversation context. Perform ALL of the following steps thoroughly before the reset.

## Step 1: Review Recent Work

Run `git log --oneline -20` to see what changed recently. Also check `git diff --stat` and `git status` for any uncommitted work. Identify:
- Features built or modified
- Bugs fixed
- Configuration or infrastructure changes
- Anything in progress or incomplete

## Step 2: Update Memory Files

Read the memory index at the project's auto-memory `MEMORY.md` file, then:

- **Update existing memories** that are now stale or incomplete (e.g., version status, project state)
- **Create new memories** for anything learned this session that isn't already captured: decisions, feedback, new patterns, references
- Do NOT save things derivable from code or git history — only save what's non-obvious or would be lost without memory

## Step 3: Update Project Documentation

Read the project's `CLAUDE.md`. If any of the following changed, update it:
- Architecture, patterns, or conventions
- Service configuration (ports, hosts, credentials)
- New routes, models, or important code paths
- Version status or feature completion

Only update sections that are actually stale. Do not rewrite sections that are still accurate.

## Step 4: Check for Uncommitted Work

If there are uncommitted changes, warn the user. Do NOT commit unless explicitly asked — just flag it.

## Step 5: Write Continuation Prompt to pickup.md

Write a `pickup.md` file in the project root with the following format:

```markdown
## Context Reset Continuation

### Just Completed
- [bullet list of what was done this session]

### In Progress / Next Up
- [anything that was started but not finished]
- [what the user said they wanted to do next, if known]

### Open Issues
- [any bugs, blockers, or unresolved questions]

### Notes
- [any other context that would help the next session hit the ground running]
```

Make the continuation prompt concise but complete — it should give the next session everything it needs without re-exploring the codebase.

Confirm to the user that `pickup.md` has been written and will be automatically loaded in the next session.

## Important

- Be thorough but concise in all updates
- Do not ask the user questions — just do it
- If Symphony context is active, note which channel the user was in
- Complete all steps even if some have no changes needed — confirm each step
