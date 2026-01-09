# Quick Start Guide

Get the Carolina Cloud HPC pipeline running in 5 minutes.

## ✅ Prerequisites Check

```bash
# Check all prerequisites
command -v ccloud >/dev/null 2>&1 && echo "✓ Carolina Cloud CLI installed" || echo "✗ CLI missing"
[ -n "$CCLOUD_API_KEY" ] && echo "✓ API key configured" || echo "✗ API key not set"
[ -f ~/.ssh/id_rsa ] && echo "✓ SSH key exists" || echo "✗ SSH key missing"
```

## 🚀 Three Steps to Run

### Step 1: Install CLI

**macOS ARM64:**
```bash
curl -L -o ccloud-darwin-arm64 https://cli.carolinacloud.io/download/darwin-arm64
sudo mkdir -p /usr/local/bin
sudo mv ccloud-darwin-arm64 /usr/local/bin/ccloud
sudo chmod +x /usr/local/bin/ccloud
```

**macOS Intel / Linux:** See [README.md](README.md#detailed-setup)

### Step 2: Configure API Key

Get your key from https://console.carolinacloud.io/settings/api

```bash
echo 'export CCLOUD_API_KEY=your_api_key_here' >> ~/.zshrc
source ~/.zshrc
```

### Step 3: Run Pipeline

```bash
# Generate SSH keys if needed
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# Run the pipeline
./deploy-cli.sh
```

## ⏱️ What to Expect

```
Phase                    Duration
────────────────────────────────
Validation               ~5 sec
VM Provisioning          ~45 sec
Docker Installation      ~30 sec
Code Deployment          ~5 sec
Docker Build             ~40 sec
Analysis Execution       ~40 sec
Results Download         ~3 sec
Infrastructure Cleanup   ~10 sec
────────────────────────────────
TOTAL                    ~3 min
```

## 📊 View Results

```bash
# View main results
cat results/analysis_results.csv

# View statistics
cat results/terminal_price_stats.csv
```

## 🔧 Customize

```bash
# Use bigger VM
VM_CPUS=8 VM_RAM=32 ./deploy-cli.sh

# Change instance name
INSTANCE_NAME=my-test ./deploy-cli.sh

# Save results elsewhere
RESULTS_DIR=./my-results ./deploy-cli.sh
```

## 💡 Common Issues

**"ccloud: command not found"**
```bash
# Verify installation
which ccloud

# Add to PATH if needed
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**"CCLOUD_API_KEY not set"**
```bash
# Set it temporarily
export CCLOUD_API_KEY=your_key

# Or permanently (recommended)
echo 'export CCLOUD_API_KEY=your_key' >> ~/.zshrc
source ~/.zshrc
```

**"Permission denied (publickey)"**
```bash
# Generate SSH keys
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# Fix permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

## ℹ️ What It Does

1. Provisions high-performance VM (4 vCPUs, 16GB RAM)
2. Installs Docker and deploys analysis code
3. Runs 10 million path Monte Carlo simulation
4. Downloads results as CSV files
5. **Automatically destroys VM** (~$0.01 total cost)

## 📚 Need More Details?

See [README.md](README.md) for:
- Detailed installation instructions
- Configuration options
- Analysis explanation
- Troubleshooting guide
- Customization examples

---

**That's it!** Three steps and you're running HPC workloads on Carolina Cloud. 🚀
