# Carolina Cloud HPC Data Analysis Pipeline

A fully automated, reproducible test case for high-performance data analysis on Carolina Cloud infrastructure. This pipeline demonstrates Infrastructure as Code (IaC), containerized workloads, and complete lifecycle management with automatic cost controls.

## 🎯 Overview

This project implements a **stateless**, **cost-controlled** data analysis pipeline that:

- Provisions AMD EPYC compute instances via Terraform
- Executes computationally intensive Monte Carlo simulations
- Automatically retrieves results
- **Destroys infrastructure** to prevent unnecessary costs

## 🏗️ Architecture

```
┌─────────────────┐
│   deploy.sh     │  ← Orchestration Script
└────────┬────────┘
         │
         ├─→ Terraform ──→ Carolina Cloud API
         │   (Provision AMD EPYC Instance)
         │
         ├─→ SSH + SCP ──→ Deploy Code
         │
         ├─→ Docker Build ──→ Create Container
         │
         ├─→ Docker Run ──→ Execute Analysis
         │
         ├─→ SCP ──→ Retrieve Results
         │
         └─→ Terraform Destroy ──→ Cleanup
```

## 📦 Components

### 1. Infrastructure (`main.tf`)
- **Provider**: Carolina Cloud Terraform provider
- **Instance**: AMD EPYC `epyc-4-16` (4 vCPUs, 16GB RAM)
- **OS**: Ubuntu 24.04 LTS
- **Networking**: Static IP reservation
- **Security**: SSH key injection
- **Initialization**: Automated Docker installation

### 2. Container (`Dockerfile`)
- **Base Image**: `carolinacloud/data-science:latest`
- **Dependencies**: pandas, numpy, scipy, matplotlib
- **Configuration**: Optimized for multi-core performance
- **Portability**: Fully reproducible environment

### 3. Analysis Workload (`analysis.py`)
**Monte Carlo Option Pricing Simulation:**
- 10 million path simulations
- Black-Scholes model implementation
- European call option pricing
- Statistical validation against analytical solution

**Matrix Computation Benchmark:**
- Large-scale linear algebra (5000×5000 matrices)
- Matrix multiplication and eigenvalue computation
- Hardware performance demonstration

### 4. Orchestration (`deploy.sh`)
Fully automated bash script with:
- ✅ Prerequisite validation
- ✅ Infrastructure provisioning
- ✅ Readiness checks
- ✅ Code deployment
- ✅ Analysis execution
- ✅ Result retrieval
- ✅ **Automatic cleanup (cost control)**

## ⚠️ IMPORTANT: Which Script to Use?

**Use `deploy-cli.sh` (CLI-based) - This one works!**

The Terraform provider `carolinacloud/ccloud` doesn't exist yet, so `deploy.sh` won't work.  
See [TERRAFORM_NOTE.md](TERRAFORM_NOTE.md) for details.

## 🚀 Quick Start

### Prerequisites

1. **Carolina Cloud CLI** - Installed and configured
   ```bash
   # Download the CLI for your platform
   # macOS ARM64:
   curl -L -o ccloud-darwin-arm64 https://cli.carolinacloud.io/download/darwin-arm64
   sudo mv ccloud-darwin-arm64 /usr/local/bin/ccloud
   sudo chmod +x /usr/local/bin/ccloud
   
   # Get your API key from: https://console.carolinacloud.io/settings/api
   # Add to ~/.zshrc or ~/.bashrc:
   export CCLOUD_API_KEY=your_api_key_here
   
   # Reload shell config
   source ~/.zshrc
   ```

2. **Terraform** - v1.0+
   ```bash
   # macOS
   brew install terraform
   
   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

3. **SSH Keys** - Generated and configured
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
   ```

### Installation

```bash
# Clone or download this repository
git clone https://github.com/your-org/ccloud-hpc-pipeline.git
cd ccloud-hpc-pipeline

# Make orchestration script executable
chmod +x deploy.sh
```

### Execution

```bash
# Run the complete pipeline (CLI-based - RECOMMENDED)
./deploy-cli.sh

# With custom configuration
SSH_KEY_PATH=~/.ssh/custom_key \
RESULTS_DIR=./my-results \
INSTANCE_NAME=my-analysis \
VM_CPUS=8 \
VM_RAM=32 \
./deploy-cli.sh
```

## ⚙️ Configuration

Configure via environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `CCLOUD_API_KEY` | Carolina Cloud API key (required) | None |
| `SSH_KEY_PATH` | Path to private SSH key | `~/.ssh/id_rsa` |
| `SSH_KEY_PUB` | Path to public SSH key | `~/.ssh/id_rsa.pub` |
| `RESULTS_DIR` | Local directory for results | `./results` |
| `MAX_WAIT_TIME` | Instance readiness timeout (sec) | `600` |
| `CHECK_INTERVAL` | Status check interval (sec) | `10` |
| `INSTANCE_NAME` | Carolina Cloud instance name | `data-analysis-pipeline` |

## 📊 Expected Output

### Console Output
```
[INFO] 2026-01-08 10:15:23 - Validating prerequisites...
[SUCCESS] 2026-01-08 10:15:24 - All prerequisites validated
[INFO] 2026-01-08 10:15:24 - Initializing Terraform...
[SUCCESS] 2026-01-08 10:15:26 - Terraform initialized
[INFO] 2026-01-08 10:15:26 - Provisioning Carolina Cloud infrastructure...
[SUCCESS] 2026-01-08 10:16:45 - Infrastructure provisioned
[INFO] 2026-01-08 10:16:45 - Waiting for instance to be fully ready...
[SUCCESS] 2026-01-08 10:17:12 - Instance is ready (elapsed: 27s)
[INFO] 2026-01-08 10:17:12 - Deploying analysis code to instance...
[SUCCESS] 2026-01-08 10:17:15 - Code deployed successfully
[INFO] 2026-01-08 10:17:15 - Building Docker image on instance...
[SUCCESS] 2026-01-08 10:17:52 - Docker image built successfully
[INFO] 2026-01-08 10:17:52 - Executing data analysis pipeline...
======================================================================
CAROLINA CLOUD HPC DATA ANALYSIS PIPELINE
======================================================================
Starting Monte Carlo simulation with 10,000,000 paths...
Simulation completed in 23.45 seconds
Running matrix computation benchmark...
Matrix benchmark completed in 15.78 seconds
======================================================================
RESULTS SUMMARY
======================================================================
Monte Carlo Option Price: $8.0234
Analytical BS Price:      $8.0219
Pricing Error:            $0.0015 (0.02%)
95% Confidence Interval:  ±$0.0051
MC Computation Time:      23.45 seconds
Matrix Computation Time:  15.78 seconds
======================================================================
[SUCCESS] 2026-01-08 10:18:31 - Analysis completed successfully
[INFO] 2026-01-08 10:18:31 - Downloading results...
[SUCCESS] 2026-01-08 10:18:33 - Results downloaded to: ./results
[INFO] 2026-01-08 10:18:33 - Starting cleanup process...
[INFO] 2026-01-08 10:18:33 - Destroying infrastructure...
[SUCCESS] 2026-01-08 10:19:15 - Infrastructure destroyed successfully
[SUCCESS] 2026-01-08 10:19:15 - Pipeline completed successfully
```

### Result Files

**`results/analysis_results.csv`**
```csv
timestamp,monte_carlo_simulations,mc_option_price,mc_std_error,mc_ci_95,mc_elapsed_time_sec,analytical_bs_price,pricing_error,error_percentage,matrix_computation_size,matrix_elapsed_time_sec,matrix_max_eigenvalue,total_elapsed_time_sec
2026-01-08T10:18:29,10000000,8.0234,0.0026,0.0051,23.45,8.0219,0.0015,0.02,5000,15.78,125634.2,39.23
```

**`results/terminal_price_stats.csv`**
```csv
metric,mean,median,std,min,max,percentile_25,percentile_75,percentile_95
Terminal Stock Price Distribution,105.13,103.67,21.35,45.23,215.67,89.45,117.82,145.23
```

## 🔒 Cost Control Features

### Automatic Cleanup
The `deploy.sh` script includes a **trap handler** that ensures `terraform destroy` runs even if:
- Analysis fails
- Network interruption occurs
- User presses Ctrl+C
- Any error occurs

### Manual Cleanup (if needed)
```bash
# If automatic cleanup fails, run manually:
terraform destroy -auto-approve

# Verify no instances are running:
ccloud compute instances list
```

## 🛠️ Troubleshooting

### SSH Connection Issues
```bash
# Test SSH connectivity
ssh -i ~/.ssh/id_rsa ubuntu@<INSTANCE_IP>

# Check SSH key permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

### Terraform State Issues
```bash
# Reset Terraform state
rm -rf .terraform terraform.tfstate*
terraform init

# Force unlock if state is locked
terraform force-unlock <LOCK_ID>
```

### Docker Build Failures
```bash
# SSH into instance manually
ssh -i ~/.ssh/id_rsa ubuntu@<INSTANCE_IP>

# Check Docker status
sudo systemctl status docker

# View Docker logs
docker logs <container_id>
```

### Carolina Cloud API Key Issues
```bash
# Check if API key is set
echo $CCLOUD_API_KEY

# Test API key works
ccloud list

# If not working, reset it
export CCLOUD_API_KEY=your_new_api_key
```

## 📈 Performance Considerations

### Scaling Parameters

Adjust in `analysis.py`:
```python
SIMULATIONS = 10_000_000  # Increase for longer runtime
TIME_STEPS = 252          # More granular path simulation
```

### Instance Sizing

Modify in `main.tf`:
```hcl
plan = "epyc-8-32"   # 8 vCPUs, 32GB RAM
plan = "epyc-16-64"  # 16 vCPUs, 64GB RAM
```

### Timeout Configuration
```bash
# Increase for slower networks or complex workloads
MAX_WAIT_TIME=1200 ./deploy.sh  # 20 minutes
```

## 🏆 Best Practices Implemented

✅ **Infrastructure as Code** - Reproducible, version-controlled infrastructure  
✅ **Stateless Design** - No persistent data on VMs  
✅ **Cost Controls** - Automatic teardown prevents runaway costs  
✅ **Containerization** - Portable, consistent environments  
✅ **Error Handling** - Comprehensive error checking and logging  
✅ **Security** - SSH key authentication, no hardcoded credentials  
✅ **Observability** - Detailed logging and result tracking  

## 📝 Customization

### Using Different Workloads

Replace `analysis.py` with your own computation:
```python
#!/usr/bin/env python3
import pandas as pd

# Your analysis here
results = your_computation()

# Save to CSV
results.to_csv('/app/output/results.csv', index=False)
```

### Alternative Base Images

Modify `Dockerfile`:
```dockerfile
FROM continuumio/miniconda3:latest
# or
FROM jupyter/scipy-notebook:latest
```

### Multi-Stage Deployments

Run multiple analyses:
```bash
for experiment in exp1 exp2 exp3; do
    INSTANCE_NAME=$experiment \
    RESULTS_DIR=./results/$experiment \
    ./deploy.sh
done
```

## 🔐 Security Notes

- **Never commit** `.tfstate` files (contain sensitive data)
- Use **environment variables** for API keys, never hardcode
- **Rotate SSH keys** regularly
- Review **Carolina Cloud security groups** and firewall rules
- Enable **audit logging** for production workloads

## 📚 Additional Resources

- [Carolina Cloud Documentation](https://docs.carolinacloud.io)
- [Terraform Carolina Cloud Provider](https://registry.terraform.io/providers/carolinacloud/ccloud)
- [Carolina Cloud CLI Reference](https://cli.carolinacloud.io/docs)
- [AMD EPYC Performance Guide](https://www.amd.com/en/processors/epyc-server)

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with tests

## 📄 License

MIT License - See LICENSE file for details

## 🙋 Support

- Issues: [GitHub Issues](https://github.com/your-org/ccloud-hpc-pipeline/issues)
- Email: support@example.com
- Carolina Cloud Support: support@carolinacloud.io

---

**⚠️ IMPORTANT**: Always verify infrastructure is destroyed after pipeline execution to avoid unexpected charges. Check your Carolina Cloud console at [console.carolinacloud.io](https://console.carolinacloud.io).

