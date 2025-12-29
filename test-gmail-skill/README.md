# Gmail Skill Test Environment

This is a test deployment of the Gmail skill for Claude Code.

## Structure

```
test-gmail-skill/
├── README.md (this file)
├── TEST_INSTRUCTIONS.md
└── skills/
    └── gmail/           # The Gmail skill
        ├── SKILL.md     # Skill metadata
        ├── README.md    # Setup guide
        └── scripts/
            └── gmail_search.py
```

## Quick Start

1. **Activate virtual environment:**
   ```bash
   # Easy way:
   source activate.sh

   # Or manually:
   source venv/bin/activate
   ```

   *Note: The venv is already created with dependencies installed!*

2. **Set up credentials:**
   - See `TEST_INSTRUCTIONS.md` for detailed setup
   - Save OAuth credentials to `~/.gmail_credentials/credentials.json`

3. **Authenticate:**
   ```bash
   # Make sure venv is activated (step 1), then:
   python3 skills/gmail/scripts/gmail_search.py auth

   # Or for remote servers:
   python3 skills/gmail/scripts/gmail_search.py auth --manual
   ```

4. **Test it:**
   ```bash
   # With venv activated:
   python3 skills/gmail/scripts/gmail_search.py search "in:inbox" --limit 5
   ```

## Testing with Claude Code

Open Claude Code in this directory (`test-gmail-skill/`) and ask questions like:
- "Search my Gmail for emails from last week"
- "Find unread emails about meetings"
- "Download attachments from emails about invoices"

Claude should automatically detect and use the Gmail skill from `skills/gmail/`.

## Documentation

- [TEST_INSTRUCTIONS.md](TEST_INSTRUCTIONS.md) - Comprehensive testing guide
- [skills/gmail/SKILL.md](skills/gmail/SKILL.md) - Complete command reference
- [skills/gmail/README.md](skills/gmail/README.md) - Setup instructions
