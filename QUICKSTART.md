# Quick Start Guide

Get your Carolina Cloud HPC pipeline running in 5 minutes!

## Prerequisites Check

Run this command to verify you have everything:

```bash
# Check all prerequisites at once
command -v ccloud >/dev/null 2>&1 && echo "✓ Carolina Cloud CLI installed" || echo "✗ CLI missing"
[ -n "$CCLOUD_API_KEY" ] && echo "✓ API key configured" || echo "✗ API key not set"
[ -f ~/.ssh/id_rsa ] && echo "✓ SSH key exists" || echo "✗ SSH key missing"
```

## 60-Second Setup

### 1. Install Dependencies (if needed)

**Carolina Cloud CLI:**
```bash
# Download for macOS ARM64 (adjust URL for your platform)
curl -L -o ccloud-darwin-arm64 https://cli.carolinacloud.io/download/darwin-arm64
sudo mkdir -p /usr/local/bin
sudo mv ccloud-darwin-arm64 /usr/local/bin/ccloud
sudo chmod +x /usr/local/bin/ccloud

# Set up API key (get from https://console.carolinacloud.io/settings/api)
echo 'export CCLOUD_API_KEY=your_api_key_here' >> ~/.zshrc
source ~/.zshrc
```

**SSH Key (if you don't have one):**
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

### 2. Download This Repository

```bash
# If using git
git clone https://github.com/your-org/ccloud-hpc-pipeline.git
cd ccloud-hpc-pipeline

# Or if you have the files already
cd /path/to/ccloud-test-case
```

### 3. Run the Pipeline

```bash
# Make the script executable (first time only)
chmod +x deploy-cli.sh

# Execute the CLI-based pipeline (RECOMMENDED - this one works!)
./deploy-cli.sh

# OR use the Terraform version (conceptual - provider doesn't exist yet)
# ./deploy.sh
```

That's it! The script will:
1. ✓ Provision a high-performance VM (4 vCPUs, 16GB RAM)
2. ✓ Install Docker on the instance
3. ✓ Deploy the analysis code
4. ✓ Run the Monte Carlo simulation
5. ✓ Download results to `./results/`
6. ✓ **Automatically destroy the infrastructure**

## Expected Timeline

```
Phase                    Duration
────────────────────────────────
Validation               ~5 sec
VM Provisioning          ~30-60 sec
Instance Ready           ~30-60 sec
Docker Installation      ~30 sec
Code Deployment          ~5 sec
Docker Build             ~40 sec
Analysis Execution       ~40 sec
Results Download         ~3 sec
Infrastructure Cleanup   ~10 sec
────────────────────────────────
TOTAL                    ~4-5 min
```

## View Your Results

```bash
# View the main results
cat results/analysis_results.csv

# View terminal price statistics
cat results/terminal_price_stats.csv

# Pretty print with column
column -t -s, results/analysis_results.csv
```

## Common First-Time Issues

### "ccloud: command not found"
**Solution:**
```bash
# Install the CLI (see Prerequisites section above)
# Or use the helper script:
./install-cli.sh
```

### "CCLOUD_API_KEY environment variable is not set"
**Solution:**
```bash
# Get your API key from: https://console.carolinacloud.io/settings/api
echo 'export CCLOUD_API_KEY=your_actual_api_key' >> ~/.zshrc
source ~/.zshrc
```

### "Permission denied (publickey)"
**Solution:**
```bash
# Generate a new SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# Verify permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

### "Terraform provider not found"
**This is expected!** The Terraform provider doesn't exist yet.  
**Solution:** Use the CLI-based script instead:
```bash
./deploy-cli.sh
```

### "Instance not ready after 600 seconds"
**Solution:**
```bash
# Increase timeout and retry
MAX_WAIT_TIME=1200 ./deploy.sh
```

## Customization Quick Tips

### Change Simulation Size

Edit `analysis.py`:
```python
SIMULATIONS = 1_000_000  # Smaller/faster (was 10M)
# or
SIMULATIONS = 50_000_000  # Larger/slower
```

### Use Bigger Instance

Edit `main.tf`:
```hcl
plan = "epyc-8-32"   # 8 vCPUs, 32GB RAM
# or
plan = "epyc-16-64"  # 16 vCPUs, 64GB RAM
```

Then run:
```bash
terraform init
./deploy.sh
```

### Change Results Directory

```bash
RESULTS_DIR=./my-results ./deploy.sh
```

## Cost Estimate

**Per run:** ~$0.01 USD (less than 1 cent!)

The pipeline automatically destroys all resources, so you only pay for ~4-5 minutes of compute time.

## Manual Cleanup (Just in Case)

If something goes wrong and the automatic cleanup doesn't run:

```bash
# Destroy via Terraform
terraform destroy -auto-approve

# Or via Carolina Cloud CLI
ccloud compute instances list
ccloud compute instances delete <INSTANCE_ID>
```

## Next Steps

- 📖 Read the full [README.md](README.md) for detailed documentation
- 🏗️ Check [ARCHITECTURE.md](ARCHITECTURE.md) for system design
- 🔧 Modify `analysis.py` to run your own computations
- 📊 Add visualization to your results
- 🚀 Scale up with bigger instances or more simulations

## Getting Help

**Documentation:**
- [Carolina Cloud Docs](https://docs.carolinacloud.io)
- [Terraform Docs](https://www.terraform.io/docs)

**Support:**
- GitHub Issues: [Create an issue](https://github.com/your-org/ccloud-hpc-pipeline/issues)
- Carolina Cloud: support@carolinacloud.io

## Success Checklist

After your first successful run, you should have:

- [ ] Infrastructure created and destroyed automatically
- [ ] Results in `./results/` directory
- [ ] Two CSV files with analysis data
- [ ] No running instances in Carolina Cloud console
- [ ] Understanding of the pipeline flow

Congratulations! 🎉 You've successfully run your first HPC pipeline on Carolina Cloud!

---

**Pro Tip:** Bookmark the [Carolina Cloud Console](https://console.carolinacloud.io) to monitor your infrastructure in real-time.

