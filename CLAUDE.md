# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository contains custom skills and tools for extending Claude's capabilities through:
- **Claude Agent SDK skills** - Python-based tools for Gmail integration and other services
- **MCP servers** - Model Context Protocol servers (planned)
- **Custom tooling** - Utilities for Claude Code integration

## Architecture

### Skill Structure

Skills follow the Claude Agent SDK pattern with a standardized layout:

```
skill-name/
├── SKILL.md          # Skill metadata and command reference (frontmatter + docs)
├── README.md         # User-facing installation and setup guide
└── scripts/          # Executable Python scripts implementing the skill
```

**Key files:**
- `SKILL.md` - Contains YAML frontmatter (`name`, `description`) defining when Claude should invoke the skill, followed by complete command documentation
- `README.md` - Setup instructions, credential configuration, usage examples
- Python scripts in `scripts/` - Actual implementation, should be executable with `#!/usr/bin/env python3`

### Current Skills

**Gmail Skill** (`gmail/`)
- Gmail API integration for searching, reading, sending, replying to, and managing emails
- Send emails, create drafts, reply to messages with proper threading
- OAuth2 authentication with configurable scopes (readonly/modify/full, default: modify)
- Supports Gmail search syntax with helper flags, HTML formatting, CC/BCC
- Main entry point: `gmail/scripts/gmail_search.py`

## Development Commands

### Gmail Skill

```bash
# Check configuration status
python3 gmail/scripts/gmail_search.py setup

# Authenticate (required before first use)
python3 gmail/scripts/gmail_search.py auth                # Local (auto-opens browser)
python3 gmail/scripts/gmail_search.py auth --manual       # Remote/headless (prints URL)

# Search emails
python3 gmail/scripts/gmail_search.py search "query" [--from EMAIL] [--unread] [--json]

# Download attachments
python3 gmail/scripts/gmail_search.py download MESSAGE_ID

# List labels
python3 gmail/scripts/gmail_search.py labels

# Send email
python3 gmail/scripts/gmail_search.py send --to EMAIL --subject "SUBJECT" --body "MESSAGE" [--cc EMAIL] [--bcc EMAIL] [--html]

# Create draft
python3 gmail/scripts/gmail_search.py draft --to EMAIL --subject "SUBJECT" --body "MESSAGE" [--cc EMAIL] [--bcc EMAIL] [--html]

# Reply to email (maintains thread)
python3 gmail/scripts/gmail_search.py reply MESSAGE_ID --body "REPLY" [--html]

# Change permission scope (default: modify)
python3 gmail/scripts/gmail_search.py scope --set [readonly|modify|full]
```

### Dependencies

Gmail skill requires:
```bash
pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib
```

## Credential Management

Skills use `~/.{service}_credentials/` for credential storage:

- `~/.gmail_credentials/credentials.json` - OAuth client secrets from Google Cloud Console
- `~/.gmail_credentials/token.pickle` - Cached authentication token
- `~/.gmail_credentials/scope.txt` - Current API scope setting

**Never commit credential files to git** - they are in `.gitignore`.

## Git Workflow

This repository uses:
- **Main branch:** `main`
- **Remote:** `https://github.com/autokeyca/claude-skills`
- **Authentication:** GitHub token embedded in remote URL (same pattern as n8n-workflows-backup)

Standard commit format:
```
Brief description of changes

- Bullet point details
- Additional context

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Adding New Skills

When creating a new skill:

1. Create directory: `skill-name/`
2. Add `SKILL.md` with frontmatter:
   ```yaml
   ---
   name: skill-name
   description: When to use this skill (be specific about trigger phrases)
   ---
   ```
3. Add `README.md` with setup instructions
4. Add executable scripts in `scripts/` directory
5. Document all commands and flags in SKILL.md
6. Update root README.md to list the new skill
7. Add any credential paths to `.gitignore`

## OAuth Setup Pattern

Skills requiring OAuth follow this pattern:

1. User creates Google Cloud project
2. Enable required APIs
3. Configure OAuth consent screen (test mode for personal use)
4. Publish app in test mode (prevents 403 errors)
5. Create OAuth client (Desktop app type)
6. Download credentials to `~/.{service}_credentials/credentials.json`
7. Run `auth` command to complete OAuth flow
   - Use `auth` for local machines (auto-opens browser)
   - Use `auth --manual` for remote/headless servers (prints URL to paste)

Test mode tokens expire after 7 days; production requires Google verification.

**Remote Authentication:** Skills support `--manual` flag for headless environments. Manual flow prints authorization URL, user opens it locally, then pastes the code back into the terminal.

## Output Formats

Skills should support both Markdown (default) and JSON output via `--json` flag:
- **Markdown:** Human-readable, formatted for display
- **JSON:** Structured data for programmatic use

Use `--json` consistently across all commands for parseable output.
