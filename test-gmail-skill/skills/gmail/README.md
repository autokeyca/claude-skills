# Gmail Skill

Search, send, reply to, and manage emails via Gmail API with flexible query options and output formats.

## Features

- **Search**: Free-text search with Gmail query syntax
- **Filters**: By sender, recipient, subject, label, date range, status
- **Send emails**: Send new emails with CC/BCC support
- **Create drafts**: Save draft emails without sending
- **Reply**: Reply to emails with proper threading
- **Attachments**: Download attachments from messages
- **Labels**: List all available Gmail labels
- **HTML support**: Send/draft/reply with HTML formatting
- **Configurable OAuth scopes**: readonly/modify/full (default: modify)
- **Output formats**: Markdown (default) or JSON

## Installation

```bash
pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib
```

## Setup: Obtaining Gmail API Credentials

### 1. Create Google Cloud Project

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Click project dropdown (top bar) -> "New Project"
3. Name it (e.g., "Gmail Agent Skill") -> Create
4. Wait for project creation, then select it

### 2. Enable Gmail API

1. In your project, go to "APIs & Services" -> "Library"
2. Search for "Gmail API"
3. Click on it and press "Enable"

### 3. Configure OAuth Consent Screen

1. Go to "APIs & Services" -> "OAuth consent screen"
2. Choose "External" user type -> Create
3. Fill in required fields:
   - **App name:** Gmail Agent Skill
   - **User support email:** your email
   - **Developer contact email:** your email
4. Click "Save and Continue"
5. Skip "Scopes" (just click "Save and Continue")
6. On "Test users" page, click "Add Users"
7. Add your Gmail address as a test user
8. Click "Save and Continue" -> "Back to Dashboard"

### 4. Publish the Test App

**Important:** Without this step, you'll get "Error 403: access_denied".

1. Go back to "OAuth consent screen"
2. Under "Publishing status", you'll see "Testing"
3. Click "Publish App"
4. Confirm by clicking "Confirm"

This publishes your app in **test mode** (not production). It allows the test users you added to authenticate. The app remains unverified, which is fine for personal use - you'll just see a warning screen during authentication that you can click through.

**Note:** Test mode tokens expire after 7 days, requiring re-authentication. For personal use, this is a minor inconvenience. Production publishing requires Google verification review.

### 5. Create OAuth Credentials

1. Go to "APIs & Services" -> "Credentials"
2. Click "Create Credentials" -> "OAuth client ID"
3. Application type: **Desktop app**
4. Name: "Gmail Agent Client"
5. Click "Create"

### 6. Download and Save Credentials

After creation, you'll see Client ID and Client Secret.

**Option A: Download JSON**
1. Click the download icon next to your OAuth client
2. Save as `~/.gmail_credentials/credentials.json`

**Option B: Create manually**

Create `~/.gmail_credentials/credentials.json`:

```json
{
  "installed": {
    "client_id": "YOUR_CLIENT_ID.apps.googleusercontent.com",
    "client_secret": "YOUR_CLIENT_SECRET",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "redirect_uris": ["http://localhost"]
  }
}
```

### 7. Authenticate

**For local machines (WSL, Linux desktop):**
```bash
python3 scripts/gmail_search.py auth
```

This opens a browser. Sign in with Google, click through the "unverified app" warning (click "Advanced" -> "Go to Gmail Agent Skill (unsafe)"), approve access, and you're ready.

**For remote/headless servers:**
```bash
python3 scripts/gmail_search.py auth --manual
```

Use `--manual` when running on remote servers without a GUI. The script will:
1. Print an authorization URL
2. You open it in your local browser
3. Complete the Google authorization
4. Copy the authorization code
5. Paste it back into the terminal

This allows authentication on headless servers, SSH sessions, or any environment where a browser can't be automatically launched.

## Usage

### Search & Read

```bash
# Check setup status
python3 scripts/gmail_search.py setup

# Search emails
python3 scripts/gmail_search.py search "meeting notes"

# Filter by sender
python3 scripts/gmail_search.py search --from "boss@company.com"

# Unread emails with attachments
python3 scripts/gmail_search.py search --unread --has-attachment

# Date range
python3 scripts/gmail_search.py search --after 2024/11/01 --before 2024/11/30

# Full body (not just snippet)
python3 scripts/gmail_search.py search "invoice" --full

# JSON output
python3 scripts/gmail_search.py search "project" --json

# Download attachments
python3 scripts/gmail_search.py download MESSAGE_ID

# List labels
python3 scripts/gmail_search.py labels
```

### Send & Reply

```bash
# Send email
python3 scripts/gmail_search.py send \
  --to "recipient@example.com" \
  --subject "Meeting Tomorrow" \
  --body "Let's meet at 10am in the conference room."

# Send with CC/BCC
python3 scripts/gmail_search.py send \
  --to "john@example.com" \
  --subject "Project Update" \
  --body "Here's the update..." \
  --cc "boss@company.com,team@company.com" \
  --bcc "archive@company.com"

# Send HTML email
python3 scripts/gmail_search.py send \
  --to "recipient@example.com" \
  --subject "Newsletter" \
  --body "<h1>Welcome</h1><p>HTML content here</p>" \
  --html

# Create draft
python3 scripts/gmail_search.py draft \
  --to "recipient@example.com" \
  --subject "Draft Email" \
  --body "This will be saved as a draft."

# Reply to email (maintains thread)
python3 scripts/gmail_search.py reply MESSAGE_ID \
  --body "Thanks for your email! I'll get back to you soon."

# Reply with HTML
python3 scripts/gmail_search.py reply MESSAGE_ID \
  --body "<p>Thanks!</p><p>Best regards</p>" \
  --html
```

## Scopes

Change permission level:

```bash
python3 scripts/gmail_search.py scope --set readonly   # Read only
python3 scripts/gmail_search.py scope --set modify     # Read, send, reply, modify labels (default)
python3 scripts/gmail_search.py scope --set full       # Full access including delete
```

**Default scope:** `modify` - Allows reading, sending, replying, and modifying labels. This is the recommended scope for most use cases.

**Note:** Changing scope requires re-authentication (`python3 scripts/gmail_search.py auth`).

## Files

- `~/.gmail_credentials/credentials.json` - OAuth client credentials
- `~/.gmail_credentials/token.pickle` - Cached auth token
- `~/.gmail_credentials/scope.txt` - Current scope setting
