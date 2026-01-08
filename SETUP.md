# Setup Instructions

## Step 1: Get Your Carolina Cloud API Key

1. Go to [Carolina Cloud Console](https://console.carolinacloud.io)
2. Log in to your account
3. Navigate to **Settings** → **API Keys**
4. Create a new API key or copy your existing one
5. Save it securely - you'll need it for the next step

## Step 2: Install Carolina Cloud CLI

The CLI binary is platform-specific. Choose your platform:

### macOS ARM64 (M1/M2/M3)
```bash
curl -L -o ccloud-darwin-arm64 https://cli.carolinacloud.io/download/darwin-arm64
sudo mkdir -p /usr/local/bin
sudo mv ccloud-darwin-arm64 /usr/local/bin/ccloud
sudo chmod +x /usr/local/bin/ccloud
```

### macOS Intel
```bash
curl -L -o ccloud-darwin-amd64 https://cli.carolinacloud.io/download/darwin-amd64
sudo mkdir -p /usr/local/bin
sudo mv ccloud-darwin-amd64 /usr/local/bin/ccloud
sudo chmod +x /usr/local/bin/ccloud
```

### Linux
```bash
curl -L -o ccloud-linux-amd64 https://cli.carolinacloud.io/download/linux-amd64
sudo mv ccloud-linux-amd64 /usr/local/bin/ccloud
sudo chmod +x /usr/local/bin/ccloud
```

### Verify Installation
```bash
ccloud --help
```

## Step 3: Configure API Key

Add your API key to your shell configuration:

### For Zsh (default on macOS)
```bash
echo 'export CCLOUD_API_KEY=your_actual_api_key_here' >> ~/.zshrc
source ~/.zshrc
```

### For Bash
```bash
echo 'export CCLOUD_API_KEY=your_actual_api_key_here' >> ~/.bashrc
source ~/.bashrc
```

### Verify API Key
```bash
echo $CCLOUD_API_KEY
ccloud list  # Should show your instances (or empty list if none)
```

## Step 4: Install Terraform

### macOS
```bash
brew install terraform
```

### Linux
```bash
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### Verify
```bash
terraform --version
```

## Step 5: Set Up SSH Keys

If you don't already have SSH keys:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
# Press Enter for default location
# Enter a passphrase (optional but recommended)
```

Verify:
```bash
ls -la ~/.ssh/id_rsa*
# Should show: id_rsa (private) and id_rsa.pub (public)
```

## Step 6: Test the Pipeline

```bash
cd /path/to/ccloud-test-case
./deploy.sh
```

## Troubleshooting

### "CCLOUD_API_KEY environment variable is not set"
- Make sure you added the export line to your shell config
- Run `source ~/.zshrc` (or `~/.bashrc`)
- Verify with: `echo $CCLOUD_API_KEY`

### "ccloud: command not found"
- Check if it's in your PATH: `which ccloud`
- If not, reinstall to `/usr/local/bin/`
- Verify `/usr/local/bin` is in PATH: `echo $PATH`

### "Permission denied" when moving to /usr/local/bin
- Use `sudo` for the move command
- Or install to `~/.local/bin` instead (see alternative in README)

### SSH connection issues
- Verify key permissions: `chmod 600 ~/.ssh/id_rsa`
- Test SSH: `ssh -i ~/.ssh/id_rsa ubuntu@<instance-ip>`

## Security Best Practices

1. **Never commit your API key** - It's in `.gitignore` as `.env`
2. **Use environment variables** - Don't hardcode credentials
3. **Rotate API keys regularly** - Generate new keys periodically
4. **Limit key permissions** - Use read-only keys when possible
5. **Monitor usage** - Check Carolina Cloud console for unexpected activity

## Next Steps

Once setup is complete:
- Read [QUICKSTART.md](QUICKSTART.md) for a quick overview
- Read [README.md](README.md) for detailed documentation
- Read [ARCHITECTURE.md](ARCHITECTURE.md) for system design details
- Customize `analysis.py` for your own workloads

## Getting Help

- **Carolina Cloud Docs**: https://docs.carolinacloud.io
- **CLI Reference**: Run `ccloud --help` or `ccloud [command] --help`
- **Support**: support@carolinacloud.io
