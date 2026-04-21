---
name: cp
description: Save memories, state, and update project documentation before a context reset. Writes pickup.md for automatic resumption via SessionStart hook.
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

**Do not use the Write tool for pickup.md.** Use the atomic write+verify script, which writes `pickup.md` + `.pickup-session-id`, verifies both exist and are non-empty, and prints a receipt on stdout. This replaces the old "compose → Write → verify" sequence because that sequence turned out to be skippable — the script isn't.

Compose the pickup content to this structure:

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

Make it concise but complete — give the next session everything it needs without re-exploring the codebase.

Then pipe it into the script via a Bash tool call from the project root:

```bash
cat <<'EOF' | /home/ja/.claude/skills/checkpoint/write-pickup.sh
## Context Reset Continuation

### Just Completed
- ...
EOF
```

The script:
- Resolves the current session id from the transcript directory (no guessing).
- Writes `pickup.md` from stdin and `.pickup-session-id` in the project root.
- Stats both and exits non-zero if either is missing or empty.
- Prints a receipt to stdout, e.g.:
  `WROTE /home/ja/projects/<proj>/pickup.md 5826B 49L sha=<12hex> sid=<uuid> at=<iso8601>`
  `WROTE /home/ja/projects/<proj>/.pickup-session-id 37B sid=<uuid>`

**Receipt rule (mandatory):** Quote both `WROTE …` lines verbatim in your done-message. Do not paraphrase, do not summarize, do not claim success without them. The receipt is the proof; fabricating it (bytes/lines/sha that don't match what the script actually emitted) is the failure mode this script exists to prevent. If the script exits non-zero, surface the exact stderr line to the user and stop — do not retry silently.

## Important

- Be thorough but concise in all updates
- Do not ask the user questions — just do it
- If Symphony context is active, note which channel the user was in
- Complete all steps even if some have no changes needed — confirm each step

---

## How pickup.md Auto-Loading Works

The continuation prompt written by this skill is automatically injected after `/clear` via a **SessionStart hook** configured in `~/.claude/settings.json`. The hook only fires when the session source is `"clear"`, which means headless `claude -p` invocations and fresh launches are safely ignored.

### Hook mechanism

A `SessionStart` hook runs when a session begins. The hook script (`~/.claude/skills/checkpoint/hook.sh`):

1. Reads the Claude Code JSON payload from stdin (including `source` and `session_id`)
2. Checks `source` — if it is anything other than `"clear"`, exits silently (zero cost)
3. If `source == "clear"` and `pickup.md` exists: cats pickup.md to stdout, deletes both `pickup.md` and `.pickup-session-id`
4. If `source == "clear"` but no `pickup.md`: exits silently

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/home/ja/.claude/skills/checkpoint/hook.sh"
          }
        ]
      }
    ]
  }
}
```

### Why SessionStart instead of UserPromptSubmit

The original hook used `UserPromptSubmit`, which fires on every user message in every session — including headless `claude -p` invocations. A headless agent (e.g., Symphony's Ops Scanner) running in the same project directory with a different session ID would trigger the "different session" branch and consume pickup.md before the interactive user could see it.

`SessionStart` with a `source == "clear"` filter solves this cleanly:
- **`/clear` in interactive session** → `source == "clear"` → pickup.md consumed as intended
- **Headless `claude -p`** → `source == "startup"` → hook exits silently, pickup.md untouched
- **Fresh `claude` launch** → `source == "startup"` → hook exits silently (pickup is specifically for post-`/clear` handoff, not cold launches)
- **Session resume** → `source == "resume"` → hook exits silently

The session-ID sentinel is no longer needed for correctness but is kept for debugging and log analysis.

### Known source values

| Source | Meaning | Hook action |
|--------|---------|-------------|
| `startup` | Fresh `claude` launch or headless `claude -p` | Skip |
| `clear` | After `/clear` command | Consume pickup.md |
| `resume` | Session resumed | Skip |
| `compact` | After `/compact` command | Skip |

### Why a hook instead of CLAUDE.md

A CLAUDE.md instruction asks Claude to check for the file, but Claude may not act on it proactively — it's a soft instruction that can be missed. The hook is executed by the harness itself, so the pickup content is injected into the conversation context automatically. Claude cannot miss it.

### Token overhead

None when `pickup.md` doesn't exist or when source is not "clear". The hook produces no output in those cases, so it's invisible to the conversation. Tokens are only consumed on `/clear` when the file is present — which is exactly the one time you need it.

### Setup

This hook must be configured in `~/.claude/settings.json` on each machine where the `/cp` skill is used. The file is deleted after first read, so the hook effectively fires once per checkpoint cycle.
