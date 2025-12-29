# Gmail Skill - Quick Start

## 3-Step Setup

### 1. Install Python Dependencies

**Ubuntu 24.04+ requires virtual environment:**

```bash
# Create virtual environment (one time)
python3 -m venv venv

# Activate it
source venv/bin/activate

# Install dependencies
pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib
```

**Note:** Always activate the venv before running commands:
```bash
source venv/bin/activate
```

### 2. Get Google OAuth Credentials

Create `~/.gmail_credentials/credentials.json`:

```json
{
  "installed": {
    "client_id": "YOUR_CLIENT_ID_HERE.apps.googleusercontent.com",
    "client_secret": "YOUR_CLIENT_SECRET_HERE",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "redirect_uris": ["http://localhost"]
  }
}
```

**How to get credentials:**
1. Go to https://console.cloud.google.com
2. Create/select project → Enable Gmail API
3. OAuth consent screen → External → Add yourself as test user → **Publish app**
4. Credentials → Create OAuth client ID → Desktop app
5. Download JSON or copy client_id and client_secret

### 3. Authenticate

**Make sure venv is activated first:**
```bash
source venv/bin/activate
```

**Local (WSL/desktop):**
```bash
python3 skills/gmail/scripts/gmail_search.py auth
```

**Remote server (headless):**

First, from your LOCAL machine, set up SSH port forwarding:
```bash
ssh -L 8080:localhost:8080 user@remote-server
```

Then on the remote server (in the SSH session):
```bash
python3 skills/gmail/scripts/gmail_search.py auth --manual
```

Open the printed URL in your LOCAL browser. The OAuth callback will tunnel back through SSH.

## Test It

```bash
# Activate venv
source venv/bin/activate

# Search emails
python3 skills/gmail/scripts/gmail_search.py search "in:inbox" --limit 5
```

## Use with Claude Code

Open Claude Code in this `test-gmail-skill/` directory and try:

```
Search my Gmail for emails from last week
```

Claude will automatically use the Gmail skill!

---

**Full docs:** See [TEST_INSTRUCTIONS.md](TEST_INSTRUCTIONS.md)
