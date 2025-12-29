# Gmail Skill Test Instructions

This folder contains the Gmail skill in the `skills/gmail/` subdirectory for testing with Claude Code.

## Setup Steps

### 1. Install Dependencies

**Ubuntu 24.04+ requires virtual environment:**

```bash
# Create virtual environment (already done for you)
python3 -m venv venv

# Activate it (do this every time)
source venv/bin/activate

# Install dependencies
pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib
```

**Note:** The venv is already created and dependencies are installed. Just activate it:
```bash
source venv/bin/activate
```

### 2. Set Up Google Cloud Credentials

You need OAuth credentials from Google Cloud Console. See `skills/gmail/README.md` for full instructions, but here's the quick version:

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create a new project (or use existing)
3. Enable Gmail API
4. Configure OAuth consent screen (External, add yourself as test user)
5. **Publish the app** (prevents 403 errors)
6. Create OAuth client (Desktop app type)
7. Download credentials as JSON

Save the credentials to:
```
~/.gmail_credentials/credentials.json
```

### 3. Authenticate

**Activate venv first:**
```bash
source venv/bin/activate
```

**For WSL/local machine:**
```bash
python3 skills/gmail/scripts/gmail_search.py auth
```

**For remote/headless server:**
```bash
python3 skills/gmail/scripts/gmail_search.py auth --manual
```

## Test Commands

All commands should be run from the `test-gmail-skill/` directory **with venv activated**.

**Always start with:**
```bash
source venv/bin/activate
```

### Basic Tests

```bash
# Check setup
python3 skills/gmail/scripts/gmail_search.py setup

# Search for recent emails
python3 skills/gmail/scripts/gmail_search.py search "in:inbox" --limit 5

# Search with filters
python3 skills/gmail/scripts/gmail_search.py search --unread --limit 3

# Search by sender
python3 skills/gmail/scripts/gmail_search.py search --from "gmail.com"

# Get full email body
python3 skills/gmail/scripts/gmail_search.py search "test" --limit 1 --full

# JSON output
python3 skills/gmail/scripts/gmail_search.py search "in:inbox" --limit 2 --json
```

### Advanced Tests

```bash
# Date range search
python3 skills/gmail/scripts/gmail_search.py search --after 2024/12/01

# Emails with attachments
python3 skills/gmail/scripts/gmail_search.py search --has-attachment --limit 5

# List all labels
python3 skills/gmail/scripts/gmail_search.py labels

# Search by label
python3 skills/gmail/scripts/gmail_search.py search --label "IMPORTANT"
```

### Download Attachments Test

```bash
# First, find an email with attachments
python3 skills/gmail/scripts/gmail_search.py search --has-attachment --attachments --limit 1

# Copy the message ID from output, then download
python3 skills/gmail/scripts/gmail_search.py download MESSAGE_ID
```

### Scope Management

```bash
# View current scope
python3 skills/gmail/scripts/gmail_search.py scope

# Change to modify scope (requires re-auth)
python3 skills/gmail/scripts/gmail_search.py scope --set modify
python3 skills/gmail/scripts/gmail_search.py auth

# Change back to readonly
python3 skills/gmail/scripts/gmail_search.py scope --set readonly
python3 skills/gmail/scripts/gmail_search.py auth
```

## Testing with Claude Code

### Step 1: Open Claude Code in Test Directory

```bash
cd test-gmail-skill
# Open Claude Code here
```

### Step 2: Test Scenarios

Try these prompts with Claude:

#### Scenario 1: Search Email
```
Search my Gmail for emails from the last week
```

Claude should:
- Recognize this is a Gmail search task
- Use the gmail skill from `skills/gmail/`
- Run the appropriate search command
- Return formatted results

#### Scenario 2: Filter by Sender
```
Find all unread emails from @company.com
```

Claude should construct a search with --from and --unread flags.

#### Scenario 3: Download Attachments
```
Find emails with attachments about "invoice" and download them
```

Claude should:
1. Search with --has-attachment and query "invoice"
2. Extract message ID from results
3. Run download command

#### Scenario 4: Check Configuration
```
Is Gmail configured? Show me my current setup.
```

Claude should run the setup command and report status.

#### Scenario 5: Manual Auth (Remote Server)
```
Authenticate with Gmail using manual mode
```

Claude should run `auth --manual` and guide you through the process.

## Expected Results

✅ **Setup command** - Shows configuration status
✅ **Search commands** - Return formatted emails (Markdown or JSON)
✅ **Download command** - Saves files to `~/Downloads/gmail_attachments/`
✅ **Labels command** - Lists all Gmail labels
✅ **Auth command** - Completes OAuth flow successfully
✅ **Manual auth** - Prints URL, accepts code from terminal

## Skill Detection

Claude Code should automatically detect the skill because:
1. It's in the `skills/` subdirectory
2. Contains `SKILL.md` with proper frontmatter:
   ```yaml
   ---
   name: gmail
   description: This skill should be used when searching, fetching, or downloading emails from Gmail...
   ---
   ```

## Troubleshooting

### "Not authenticated" error
- Run `python3 skills/gmail/scripts/gmail_search.py auth` first
- Check that `~/.gmail_credentials/token.pickle` exists

### "403: access_denied" error
- Make sure you published the OAuth app in Google Cloud Console
- Add yourself as a test user
- Re-run the auth command

### Browser doesn't open (remote server)
- Use `python3 skills/gmail/scripts/gmail_search.py auth --manual`
- This prints a URL you can open locally
- Paste the authorization code back

### Token expired
- Test mode tokens expire after 7 days
- Re-run auth command to refresh

### Claude doesn't detect the skill
- Verify `SKILL.md` has proper YAML frontmatter
- Check that files are in `skills/gmail/` subdirectory
- Restart Claude Code session

## Clean Up After Testing

```bash
# Remove cached credentials
rm -rf ~/.gmail_credentials/

# Remove test folder
cd ..
rm -rf test-gmail-skill/
```
