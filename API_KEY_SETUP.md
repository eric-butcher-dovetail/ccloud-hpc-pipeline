# Carolina Cloud API Key Setup

## Step 1: Get Your API Key from Console

1. **Login to Carolina Cloud Console**
   - Go to: https://console.carolinacloud.io
   - Login with your credentials

2. **Navigate to API Settings**
   - Click on your profile/settings
   - Go to **Settings** → **API Keys**
   - Or go directly to: https://console.carolinacloud.io/settings/api

3. **Create or Copy API Key**
   - If you don't have a key: Click "Create New API Key"
   - Give it a name like "HPC Pipeline"
   - Copy the generated key immediately (you may not see it again!)
   - Store it securely

## Step 2: Configure the API Key

Choose one of these methods:

### Method 1: Add to Shell Config (Recommended - Permanent)

**For Zsh (macOS default):**
```bash
echo 'export CCLOUD_API_KEY=cc_your_actual_api_key_here' >> ~/.zshrc
source ~/.zshrc
```

**For Bash (Linux):**
```bash
echo 'export CCLOUD_API_KEY=cc_your_actual_api_key_here' >> ~/.bashrc
source ~/.bashrc
```

### Method 2: Use .env File (Project-Specific)

```bash
# In the project directory
cp .env.example .env

# Edit .env and replace the placeholder
nano .env  # or use your preferred editor
# Change: export CCLOUD_API_KEY=your_api_key_here
# To:     export CCLOUD_API_KEY=cc_your_actual_key

# Source it before running deploy
source .env
./deploy.sh
```

### Method 3: Set Temporarily (Current Session Only)

```bash
export CCLOUD_API_KEY=cc_your_actual_api_key_here
./deploy.sh
```

## Step 3: Verify Setup

```bash
# Check that the key is set
echo $CCLOUD_API_KEY
# Should output: cc_your_actual_api_key_here (not empty)

# Test with Carolina Cloud CLI
ccloud list
# Should list your instances (or show empty list if none exist)
```

## Troubleshooting

### Error: "CCLOUD_API_KEY environment variable is not set"
**Cause:** The API key wasn't exported to the environment

**Solution:**
```bash
# Check if it's set
echo $CCLOUD_API_KEY

# If empty, set it:
export CCLOUD_API_KEY=cc_your_actual_key

# Or add to shell config permanently (see Method 1 above)
```

### Error: "Authentication failed" or "Invalid API key"
**Cause:** The API key is incorrect or expired

**Solutions:**
1. Verify you copied the entire key (including any prefix like `cc_`)
2. Check for extra spaces or newlines
3. Generate a new API key from the console
4. Verify the key works with: `ccloud list`

### Key Not Persisting Between Sessions
**Cause:** Key is only set for current session

**Solution:** Use Method 1 (add to ~/.zshrc or ~/.bashrc) for permanent setup

## Security Best Practices

1. **Never commit the API key** to git
   - `.env` is in `.gitignore` (protected)
   - Use `.env.example` with placeholders only

2. **Don't share your API key**
   - Treat it like a password
   - Don't post it in Slack, GitHub issues, etc.

3. **Rotate keys regularly**
   - Generate new keys periodically
   - Revoke old keys from console

4. **Use minimal permissions**
   - If Carolina Cloud supports scoped keys, use them
   - Only grant permissions needed for the pipeline

5. **Monitor usage**
   - Check console for unexpected activity
   - Review API logs if available

## API Key Format

Carolina Cloud API keys typically look like:
```
cc_1234567890abcdef1234567890abcdef
```

- Usually starts with `cc_` prefix
- Contains alphanumeric characters
- 32-64 characters long (varies by provider)

## Quick Reference

| Action | Command |
|--------|---------|
| Set key temporarily | `export CCLOUD_API_KEY=your_key` |
| Check if set | `echo $CCLOUD_API_KEY` |
| Test key | `ccloud list` |
| Add to zsh | `echo 'export CCLOUD_API_KEY=key' >> ~/.zshrc` |
| Add to bash | `echo 'export CCLOUD_API_KEY=key' >> ~/.bashrc` |
| Reload shell | `source ~/.zshrc` or `source ~/.bashrc` |

---

**Next Steps:** Once your API key is configured, proceed to [QUICKSTART.md](QUICKSTART.md) to run the pipeline!
