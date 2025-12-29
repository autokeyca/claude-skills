---
name: gmail
description: This skill should be used when searching, fetching, downloading, sending, or replying to emails in Gmail. Use for queries like "search Gmail for...", "find emails from John", "show unread emails", "send email to...", "create draft email", "reply to that email", or "download attachment from email".
---

# Gmail Skill

Search, send, reply to, and manage emails via Gmail API with flexible query options and output formats.

## Prerequisites

Credentials must be configured in `~/.gmail_credentials/`. Run `setup` to check status:

```bash
python3 scripts/gmail_search.py setup
```

### Obtaining Gmail API Credentials

#### 1. Create Google Cloud Project

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Click project dropdown -> "New Project"
3. Name it (e.g., "Gmail Agent Skill") -> Create

#### 2. Enable Gmail API

1. Navigate to "APIs & Services" -> "Library"
2. Search for "Gmail API"
3. Click it and press "Enable"

#### 3. Configure OAuth Consent Screen

1. Go to "OAuth consent screen" (left sidebar)
2. Choose "External" user type
3. Fill in required fields:
   - App name: Gmail Agent Skill
   - User support email: your email
   - Developer email: your email
4. Click "Save and Continue", skip Scopes
5. On "Test users" page, add your Gmail address
6. Complete all steps

#### 4. Publish the Test App

**Important:** Without this step, you'll get "Error 403: access_denied".

1. Go back to "OAuth consent screen"
2. Under "Publishing status", click "Publish App"
3. Confirm the dialog

This keeps the app in test mode (not production) but allows your test users to authenticate. You'll see an "unverified app" warning during login - click "Advanced" -> "Go to Gmail Agent Skill (unsafe)" to proceed.

**Note:** Test tokens expire after 7 days. Production requires Google verification.

#### 5. Create OAuth Credentials

1. Go to "Credentials" (left sidebar)
2. Click "Create Credentials" -> "OAuth client ID"
3. Select "Desktop app" as application type
4. Name it (e.g., "Gmail Agent Client")
5. Click "Create"

#### 6. Get Your Credentials

1. Client ID will be displayed - copy it
2. Client Secret: Click the download icon or view details to get the secret

#### 7. Save Credentials

Create `~/.gmail_credentials/credentials.json`:

```json
{
  "installed": {
    "client_id": "YOUR_CLIENT_ID",
    "client_secret": "YOUR_CLIENT_SECRET",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "redirect_uris": ["http://localhost"]
  }
}
```

#### 8. Authenticate

**For local machines (WSL, Linux desktop):**
```bash
python3 scripts/gmail_search.py auth
```

This opens a browser. Click through the "unverified app" warning ("Advanced" -> "Go to Gmail Agent Skill"), approve access, and you're ready.

**For remote/headless servers:**
```bash
python3 scripts/gmail_search.py auth --manual
```

This prints a URL. Open it in your local browser, complete authorization, copy the code, and paste it back into the terminal.

## Quick Start

```bash
# Check setup status
python3 scripts/gmail_search.py setup

# Authenticate (opens browser)
python3 scripts/gmail_search.py auth

# Search emails
python3 scripts/gmail_search.py search "meeting notes"

# Search with filters
python3 scripts/gmail_search.py search --from "boss@company.com" --unread
```

## Commands

### Setup

Check configuration status:

```bash
python3 scripts/gmail_search.py setup
python3 scripts/gmail_search.py setup --json
```

### Authenticate

Authenticate with Gmail using OAuth:

```bash
# Automatic (opens browser) - for local machines
python3 scripts/gmail_search.py auth

# Manual (prints URL) - for remote/headless servers
python3 scripts/gmail_search.py auth --manual
```

**When to use `--manual`:**
- Remote servers without GUI
- SSH sessions
- Headless Ubuntu servers
- Any environment where browser auto-launch fails

### Scope

View or change API permission scope:

```bash
# View current scope
python3 scripts/gmail_search.py scope

# Change scope (requires re-auth)
python3 scripts/gmail_search.py scope --set readonly
python3 scripts/gmail_search.py scope --set modify
python3 scripts/gmail_search.py scope --set full
```

**Available scopes:**
- `readonly` - Read emails only
- `modify` - Read, send, reply, and modify labels (default)
- `full` - Full access including delete

### Search

Search emails with free-text query or filters:

```bash
# Free-text search (uses Gmail search syntax)
python3 scripts/gmail_search.py search "project deadline"
python3 scripts/gmail_search.py search "from:john@example.com subject:invoice"

# Using helper flags
python3 scripts/gmail_search.py search --from "john@example.com"
python3 scripts/gmail_search.py search --to "me@example.com"
python3 scripts/gmail_search.py search --subject "Weekly Report"
python3 scripts/gmail_search.py search --label "INBOX"
python3 scripts/gmail_search.py search --label "work"

# Date filters (YYYY/MM/DD format)
python3 scripts/gmail_search.py search --after 2024/01/01
python3 scripts/gmail_search.py search --before 2024/12/31
python3 scripts/gmail_search.py search --after 2024/01/01 --before 2024/06/30

# Status filters
python3 scripts/gmail_search.py search --unread
python3 scripts/gmail_search.py search --starred
python3 scripts/gmail_search.py search --has-attachment

# Combined filters
python3 scripts/gmail_search.py search "invoice" --from "billing@" --has-attachment --after 2024/01/01

# Limit results
python3 scripts/gmail_search.py search "meeting" --limit 50

# Include full body (default shows snippet only)
python3 scripts/gmail_search.py search "contract" --full

# Include attachment info
python3 scripts/gmail_search.py search --has-attachment --attachments

# JSON output
python3 scripts/gmail_search.py search "project" --json
```

### Download Attachments

Download attachments from a specific message:

```bash
# Download to default location (~/Downloads/gmail_attachments/)
python3 scripts/gmail_search.py download MESSAGE_ID

# Download to custom directory
python3 scripts/gmail_search.py download MESSAGE_ID --output /path/to/folder

# JSON output
python3 scripts/gmail_search.py download MESSAGE_ID --json
```

Get message ID from search results (shown in output).

### Labels

List all available Gmail labels:

```bash
python3 scripts/gmail_search.py labels
python3 scripts/gmail_search.py labels --json
```

### Send Email

Send a new email:

```bash
# Basic send
python3 scripts/gmail_search.py send \
  --to "recipient@example.com" \
  --subject "Meeting Tomorrow" \
  --body "Let's meet at 10am in the conference room."

# With CC and BCC
python3 scripts/gmail_search.py send \
  --to "john@example.com" \
  --subject "Project Update" \
  --body "Here's the latest update..." \
  --cc "boss@company.com,team@company.com" \
  --bcc "archive@company.com"

# HTML email
python3 scripts/gmail_search.py send \
  --to "recipient@example.com" \
  --subject "Newsletter" \
  --body "<h1>Welcome</h1><p>This is an HTML email.</p>" \
  --html

# JSON output
python3 scripts/gmail_search.py send \
  --to "test@example.com" \
  --subject "Test" \
  --body "Test message" \
  --json
```

**Options:**
- `--to` (required) - Recipient email address
- `--subject` (required) - Email subject
- `--body` (required) - Email body content
- `--cc` (optional) - CC recipients (comma-separated)
- `--bcc` (optional) - BCC recipients (comma-separated)
- `--html` (optional) - Send as HTML instead of plain text
- `--json` (optional) - Output as JSON

### Create Draft

Create an email draft without sending:

```bash
# Basic draft
python3 scripts/gmail_search.py draft \
  --to "recipient@example.com" \
  --subject "Draft Email" \
  --body "This will be saved as a draft."

# Draft with CC/BCC
python3 scripts/gmail_search.py draft \
  --to "john@example.com" \
  --subject "Review Needed" \
  --body "Please review the attached document..." \
  --cc "team@company.com"

# HTML draft
python3 scripts/gmail_search.py draft \
  --to "recipient@example.com" \
  --subject "Formatted Draft" \
  --body "<p><strong>Important:</strong> Please review.</p>" \
  --html

# JSON output
python3 scripts/gmail_search.py draft \
  --to "test@example.com" \
  --subject "Test Draft" \
  --body "Draft message" \
  --json
```

**Options:**
- `--to` (required) - Recipient email address
- `--subject` (required) - Email subject
- `--body` (required) - Email body content
- `--cc` (optional) - CC recipients (comma-separated)
- `--bcc` (optional) - BCC recipients (comma-separated)
- `--html` (optional) - Create as HTML draft
- `--json` (optional) - Output as JSON

### Reply to Email

Reply to an existing email (maintains thread):

```bash
# Basic reply
python3 scripts/gmail_search.py reply MESSAGE_ID \
  --body "Thanks for your email! I'll get back to you soon."

# HTML reply
python3 scripts/gmail_search.py reply MESSAGE_ID \
  --body "<p>Thanks for reaching out!</p><p>Best regards</p>" \
  --html

# JSON output
python3 scripts/gmail_search.py reply MESSAGE_ID \
  --body "Reply message" \
  --json
```

**How it works:**
- Automatically fetches the original message details
- Extracts the sender as the reply recipient
- Preserves the subject line (adds "Re:" if needed)
- Maintains email threading with proper headers (In-Reply-To, References)
- Keeps the conversation in the same thread

**Options:**
- `MESSAGE_ID` (required) - ID of the message to reply to (from search results)
- `--body` (required) - Reply message body
- `--html` (optional) - Send reply as HTML
- `--json` (optional) - Output as JSON

## Output Formats

### Markdown (default)

```markdown
# Gmail Search Results (3 messages)

## Weekly Report
**From:** boss@company.com
**To:** me@example.com
**Date:** Mon, 25 Nov 2024 10:00:00 +0000
**ID:** `18abc123def`

> Here's the weekly report summary...

---
```

### JSON

Add `--json` flag for structured output:

```json
[
  {
    "id": "18abc123def",
    "thread_id": "18abc123def",
    "from": "boss@company.com",
    "to": "me@example.com",
    "subject": "Weekly Report",
    "date": "Mon, 25 Nov 2024 10:00:00 +0000",
    "snippet": "Here's the weekly report summary...",
    "labels": ["INBOX", "UNREAD"]
  }
]
```

## Gmail Search Syntax

The skill supports Gmail's native search syntax in free-text queries:

| Operator | Example | Description |
|----------|---------|-------------|
| `from:` | `from:john@example.com` | From specific sender |
| `to:` | `to:team@company.com` | To specific recipient |
| `subject:` | `subject:meeting` | In subject line |
| `label:` | `label:work` | Has specific label |
| `has:attachment` | `has:attachment` | Has attachments |
| `filename:` | `filename:pdf` | Attachment filename |
| `is:unread` | `is:unread` | Unread messages |
| `is:starred` | `is:starred` | Starred messages |
| `after:` | `after:2024/01/01` | After date |
| `before:` | `before:2024/12/31` | Before date |
| `newer_than:` | `newer_than:7d` | Within last N days |
| `older_than:` | `older_than:1m` | Older than N months |
| `in:` | `in:inbox` | In specific folder |
| `OR` | `from:john OR from:jane` | Either condition |
| `-` | `-label:spam` | Exclude |
| `""` | `"exact phrase"` | Exact match |

## Example User Requests

| User says | Command |
|-----------|---------|
| "Search Gmail for meeting notes" | `search "meeting notes"` |
| "Find emails from John" | `search --from "john"` |
| "Show unread emails" | `search --unread` |
| "Emails about the project from last month" | `search "project" --after 2024/10/01` |
| "Invoices with attachments" | `search "invoice" --has-attachment` |
| "Read the full email about contract" | `search "contract" --full --limit 1` |
| "Download attachments from that email" | `download MESSAGE_ID` |
| "What labels do I have?" | `labels` |
| "Starred emails from boss" | `search --from "boss" --starred` |
| "Is Gmail configured?" | `setup` |
| "Send email to john@example.com about the meeting" | `send --to "john@example.com" --subject "Meeting" --body "..."` |
| "Create a draft email to the team" | `draft --to "team@company.com" --subject "..." --body "..."` |
| "Reply to that email" | `reply MESSAGE_ID --body "Thanks for your message!"` |
| "Send HTML email with formatted content" | `send --to "..." --subject "..." --body "<h1>...</h1>" --html` |

## Dependencies

```bash
pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib
```

## Files

- `~/.gmail_credentials/credentials.json` - OAuth client credentials
- `~/.gmail_credentials/token.pickle` - Cached auth token
- `~/.gmail_credentials/scope.txt` - Current scope setting
