# Carolina Cloud HPC Data Analysis Pipeline - Test Case

A complete example of running high-performance data analysis on Carolina Cloud with automated deployment, execution, and cleanup.

## 📋 What This Demonstrates

- **Cloud Infrastructure Automation** - Provision compute instances via CLI
- **Containerized Workloads** - Docker-based analysis environment
- **HPC Computing** - 10 million path Monte Carlo simulation on high-performance hardware
- **Cost Control** - Automatic infrastructure teardown after completion
- **End-to-End Pipeline** - From provisioning to results in one command

## 🚀 Quick Start

### Prerequisites

1. **Carolina Cloud CLI** installed
2. **Carolina Cloud API key** from https://console.carolinacloud.io/settings/api
3. **SSH keys** generated

### Run the Pipeline

```bash
# 1. Set your API key
export CCLOUD_API_KEY=your_api_key_here

# 2. Execute the pipeline
./deploy-cli.sh

# 3. Results appear in ./results/
```

That's it! The pipeline will:
- Provision a high-performance VM (4 vCPUs, 16GB RAM)
- Install Docker and deploy analysis code
- Run Monte Carlo simulation (~40 seconds)
- Download results as CSV files
- **Automatically destroy the VM** to prevent costs

## 📁 Project Structure

```
ccloud-test-case/
├── deploy-cli.sh          # Main automation script (USE THIS!)
├── analysis.py            # Monte Carlo simulation code
├── Dockerfile             # Container image definition
├── deploy.sh              # Terraform version (conceptual - provider doesn't exist)
├── main.tf                # Terraform config (conceptual)
├── install-cli.sh         # Helper to install Carolina Cloud CLI
├── QUICKSTART.md          # Detailed setup guide
└── LICENSE                # MIT License
```

## 🔧 Detailed Setup

### 1. Install Carolina Cloud CLI

**macOS ARM64 (M1/M2/M3):**
```bash
curl -L -o ccloud-darwin-arm64 https://cli.carolinacloud.io/download/darwin-arm64
sudo mkdir -p /usr/local/bin
sudo mv ccloud-darwin-arm64 /usr/local/bin/ccloud
sudo chmod +x /usr/local/bin/ccloud
```

**macOS Intel:**
```bash
curl -L -o ccloud-darwin-amd64 https://cli.carolinacloud.io/download/darwin-amd64
sudo mkdir -p /usr/local/bin
sudo mv ccloud-darwin-amd64 /usr/local/bin/ccloud
sudo chmod +x /usr/local/bin/ccloud
```

**Linux:**
```bash
curl -L -o ccloud-linux-amd64 https://cli.carolinacloud.io/download/linux-amd64
sudo mv ccloud-linux-amd64 /usr/local/bin/ccloud
sudo chmod +x /usr/local/bin/ccloud
```

### 2. Configure API Key

Get your API key from the [Carolina Cloud Console](https://console.carolinacloud.io/settings/api), then:

**Permanently (recommended):**
```bash
echo 'export CCLOUD_API_KEY=your_api_key_here' >> ~/.zshrc
source ~/.zshrc
```

**For current session only:**
```bash
export CCLOUD_API_KEY=your_api_key_here
```

**Verify:**
```bash
ccloud list  # Should show your instances or empty list
```

### 3. Generate SSH Keys (if needed)

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
# Press Enter for defaults, optionally add passphrase
```

## 🎯 What the Pipeline Does

### The Analysis Workload (`analysis.py`)

1. **Monte Carlo Simulation**
   - 10 million path simulations
   - Black-Scholes option pricing model
   - Statistical validation against analytical solution

2. **Matrix Computation Benchmark**
   - 5000×5000 matrix operations
   - Tests linear algebra performance on AMD EPYC hardware

3. **Results Export**
   - `analysis_results.csv` - Main simulation results
   - `terminal_price_stats.csv` - Statistical distributions

### Expected Runtime

- **Provisioning:** ~30-60 seconds
- **Docker Setup:** ~30 seconds
- **Analysis Execution:** ~40 seconds
- **Results Download:** ~3 seconds
- **Cleanup:** ~10 seconds
- **Total:** ~2-3 minutes

### Expected Cost

**~$0.01 USD per run** (automatic cleanup prevents runaway costs)

## ⚙️ Configuration

Customize via environment variables:

```bash
# VM configuration
VM_CPUS=8 \
VM_RAM=32 \
VM_DISK=100 \
VM_TIER=high-performance \
./deploy-cli.sh

# Other options
SSH_KEY_PATH=~/.ssh/custom_key \
RESULTS_DIR=./my-results \
INSTANCE_NAME=my-analysis \
./deploy-cli.sh
```

## 📊 Understanding the Results

### analysis_results.csv

```csv
timestamp,monte_carlo_simulations,mc_option_price,analytical_bs_price,pricing_error,error_percentage,...
2026-01-09T10:30:15,10000000,8.0234,8.0219,0.0015,0.02%,...
```

Key metrics:
- **mc_option_price**: Simulated option price
- **analytical_bs_price**: Theoretical Black-Scholes price
- **pricing_error**: Difference (should be small)
- **error_percentage**: Accuracy of simulation

### terminal_price_stats.csv

Statistical distribution of simulated stock prices at maturity.

## 🛠️ Troubleshooting

### "CCLOUD_API_KEY environment variable is not set"
```bash
# Check if set
echo $CCLOUD_API_KEY

# Set it
export CCLOUD_API_KEY=your_api_key
```

### "ccloud: command not found"
```bash
# Check PATH
which ccloud

# Reinstall CLI (see installation section above)
```

### "Permission denied (publickey)"
```bash
# Check SSH keys exist
ls -la ~/.ssh/id_rsa*

# Generate new keys
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
```

### "Failed to create VM"
- Verify API key is valid: `ccloud list`
- Check account has sufficient credits
- Ensure requested VM specs are available

## 📝 Customizing the Analysis

Edit `analysis.py` to run your own computation:

```python
# Change simulation size
SIMULATIONS = 50_000_000  # Larger for more accuracy

# Modify parameters
def monte_carlo_option_pricing(
    S0=120.0,      # Initial stock price
    K=125.0,       # Strike price
    T=0.5,         # Time to maturity
    # ...
):
```

## ⚠️ Note on Terraform Files

**`deploy.sh` and `main.tf` don't work** because the Carolina Cloud Terraform provider doesn't exist yet. These files are included as conceptual examples of what Infrastructure-as-Code would look like.

**Use `deploy-cli.sh` for actual deployments** - it uses the Carolina Cloud CLI directly.

## 🔒 Security

- ✅ API keys via environment variables (not hardcoded)
- ✅ `.gitignore` protects sensitive files
- ✅ SSH key authentication
- ✅ No persistent data on VMs
- ✅ Automatic cleanup prevents abandoned resources

**Never commit:**
- API keys
- SSH private keys
- `.tfstate` files
- `.env` files with secrets

## 📚 Additional Resources

- [Carolina Cloud Console](https://console.carolinacloud.io)
- [Carolina Cloud Documentation](https://docs.carolinacloud.io)
- [QUICKSTART.md](QUICKSTART.md) - Step-by-step setup guide

## 🤝 Contributing

This is a test case/example project. Feel free to:
- Modify for your own workloads
- Use as a template for similar pipelines
- Adapt for other cloud providers

## 📄 License

MIT License - See [LICENSE](LICENSE) file

---

**Questions?** Check [QUICKSTART.md](QUICKSTART.md) for detailed setup instructions.

**Want to modify?** Edit `analysis.py` for your own computation, adjust VM specs via environment variables.

**Having issues?** See the Troubleshooting section above or check the Carolina Cloud documentation.
