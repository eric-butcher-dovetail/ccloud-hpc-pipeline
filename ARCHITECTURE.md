# Architecture Documentation

## System Design

### High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        Local Machine                              │
│  ┌────────────┐                                                   │
│  │ deploy.sh  │ ← Orchestration Script                           │
│  └─────┬──────┘                                                   │
│        │                                                           │
│        ├─→ Terraform CLI ──────────┐                              │
│        │                            │                              │
│        ├─→ SSH/SCP                  │                              │
│        │                            │                              │
│        └─→ Docker (for results)    │                              │
└────────────────────────────────────┼──────────────────────────────┘
                                     │
                                     │ HTTPS API
                                     ▼
            ┌─────────────────────────────────────────┐
            │      Carolina Cloud Control Plane       │
            │   (console.carolinacloud.io)           │
            └──────────────┬──────────────────────────┘
                           │
                           │ Provision/Manage
                           ▼
            ┌─────────────────────────────────────────┐
            │    Carolina Cloud Compute Instance      │
            │                                          │
            │  ┌────────────────────────────────────┐ │
            │  │  Ubuntu 24.04 LTS                  │ │
            │  │  AMD EPYC (epyc-4-16)             │ │
            │  │  4 vCPUs, 16GB RAM                │ │
            │  └────────────────────────────────────┘ │
            │                                          │
            │  ┌────────────────────────────────────┐ │
            │  │  Docker Engine                     │ │
            │  │                                     │ │
            │  │  ┌──────────────────────────────┐ │ │
            │  │  │  analysis-pipeline:latest    │ │ │
            │  │  │                               │ │ │
            │  │  │  • carolinacloud/data-science│ │ │
            │  │  │  • pandas, numpy, scipy      │ │ │
            │  │  │  • analysis.py               │ │ │
            │  │  └──────────────────────────────┘ │ │
            │  └────────────────────────────────────┘ │
            │                                          │
            │  ┌────────────────────────────────────┐ │
            │  │  Output Volume (/app/output)       │ │
            │  │  • analysis_results.csv            │ │
            │  │  • terminal_price_stats.csv        │ │
            │  └────────────────────────────────────┘ │
            └─────────────────────────────────────────┘
```

## Execution Flow

### Phase 1: Pre-flight Checks
```bash
validate_prerequisites()
├─→ Check Terraform installation
├─→ Check Carolina Cloud CLI
├─→ Verify CLI authentication
├─→ Validate SSH keys exist
└─→ Confirm required files present
```

### Phase 2: Infrastructure Provisioning
```bash
init_terraform()
└─→ terraform init

provision_infrastructure()
└─→ terraform apply
    ├─→ Create SSH key resource
    ├─→ Reserve static IP
    ├─→ Provision AMD EPYC instance
    │   ├─→ Install Docker via user_data
    │   ├─→ Configure ubuntu user
    │   └─→ Signal completion (/tmp/init-complete)
    └─→ Attach static IP to instance
```

### Phase 3: Instance Readiness
```bash
wait_for_instance()
└─→ Loop until ready (max 10 minutes)
    ├─→ Attempt SSH connection
    ├─→ Check for /tmp/init-complete
    └─→ Return when ready
```

### Phase 4: Code Deployment
```bash
deploy_code()
└─→ SCP files to instance
    ├─→ Dockerfile
    └─→ analysis.py
```

### Phase 5: Container Build
```bash
build_docker_image()
└─→ SSH to instance
    └─→ docker build -t analysis-pipeline:latest .
        ├─→ Pull carolinacloud/data-science base
        ├─→ Install pandas, numpy, scipy
        ├─→ Copy analysis.py
        └─→ Configure environment
```

### Phase 6: Analysis Execution
```bash
execute_analysis()
└─→ SSH to instance
    └─→ docker run --rm -v ~/pipeline/output:/app/output analysis-pipeline:latest
        ├─→ Load Python environment
        ├─→ Execute analysis.py
        │   ├─→ Monte Carlo simulation (10M paths)
        │   └─→ Matrix computation benchmark
        ├─→ Generate CSV results
        └─→ Save to /app/output (mapped volume)
```

### Phase 7: Results Retrieval
```bash
download_results()
└─→ SCP from instance to local
    ├─→ analysis_results.csv
    └─→ terminal_price_stats.csv
```

### Phase 8: Cleanup
```bash
cleanup() [ALWAYS RUNS via trap]
└─→ terraform destroy -auto-approve
    ├─→ Detach static IP
    ├─→ Release static IP
    ├─→ Terminate instance
    └─→ Delete SSH key resource
```

## Data Flow

```
Input Data (Hardcoded in analysis.py)
    │
    ▼
Random Number Generation (numpy.random)
    │
    ▼
Monte Carlo Simulation (10M paths)
    │
    ├─→ Geometric Brownian Motion
    ├─→ Path generation
    └─→ Payoff calculation
    │
    ▼
Statistical Analysis
    │
    ├─→ Mean, std, confidence intervals
    ├─→ Comparison with analytical solution
    └─→ Error calculation
    │
    ▼
Matrix Benchmark
    │
    ├─→ Large matrix multiplication (5000×5000)
    └─→ Eigenvalue computation
    │
    ▼
Results Serialization (pandas DataFrame)
    │
    ▼
CSV Export (/app/output/*.csv)
    │
    ▼
SCP Transfer to Local Machine
    │
    ▼
./results/ directory
```

## Computational Complexity

### Monte Carlo Simulation
- **Time Complexity**: O(n × m)
  - n = number of simulations (10M)
  - m = time steps (252)
- **Space Complexity**: O(n × m) for price paths
- **Expected Runtime**: 20-30 seconds on epyc-4-16

### Matrix Computation
- **Time Complexity**: O(n³) for matrix multiplication
  - n = matrix dimension (5000)
- **Space Complexity**: O(n²)
- **Expected Runtime**: 15-25 seconds on epyc-4-16

## Scalability Considerations

### Vertical Scaling (Instance Size)
```
epyc-4-16   →  4 vCPUs, 16GB  → Baseline
epyc-8-32   →  8 vCPUs, 32GB  → 2x throughput
epyc-16-64  → 16 vCPUs, 64GB  → 4x throughput
epyc-32-128 → 32 vCPUs, 128GB → 8x throughput
```

### Horizontal Scaling (Multiple Instances)
For truly massive workloads, modify `deploy.sh` to:
1. Provision multiple instances in parallel
2. Split simulation into batches
3. Aggregate results
4. Destroy all instances

Example pseudocode:
```bash
for i in {1..10}; do
    INSTANCE_NAME="pipeline-$i" ./deploy.sh &
done
wait
aggregate-results.py
```

### Algorithmic Optimization
- Use lower-level BLAS/LAPACK for matrix ops
- Implement GPU acceleration (CUDA/ROCm on AMD)
- Use parallel processing within Python (multiprocessing)
- Batch operations more efficiently

## Security Architecture

### Authentication Flow
```
Developer Machine
    │
    ├─→ Carolina Cloud CLI Token
    │   (stored in ~/.ccloud/config)
    │
    └─→ SSH Private Key
        (used for instance access)

Terraform Provider
    │
    └─→ Uses CLI token for API authentication

Instance Access
    │
    └─→ SSH key pair authentication
        (no password authentication)
```

### Network Security
- Instances use **private networking** by default
- **Static IP** only for external access
- **SSH port 22** restricted to deployer IP (configure in Carolina Cloud console)
- No persistent storage = reduced attack surface

### Data Security
- **Stateless design**: No sensitive data persists on VM
- Results transferred via **encrypted SCP**
- Infrastructure destroyed immediately after use
- No long-lived credentials on instances

## Cost Model

### Per-Run Cost Breakdown
```
Component                Duration    Rate            Cost
─────────────────────────────────────────────────────────
Instance (epyc-4-16)     ~5 min     $0.10/hour      $0.008
Static IP                ~5 min     $0.005/hour     $0.0004
Data Transfer (egress)   ~10 KB     $0.01/GB        ~$0.00
─────────────────────────────────────────────────────────
Total per run                                       ~$0.01
```

### Cost Optimization Strategies
1. **Automatic Cleanup** (implemented) - Destroy immediately
2. **Spot Instances** (optional) - 60-90% discount
3. **Reserved Capacity** (for frequent runs) - Up to 40% discount
4. **Batch Processing** - Amortize startup costs
5. **Right-Sizing** - Don't over-provision compute

### Cost Monitoring
```bash
# Carolina Cloud CLI
ccloud billing usage --start-date 2026-01-01 --end-date 2026-01-31

# Terraform state
terraform show -json | jq '.values.root_module.resources[].values.cost_per_hour'
```

## Disaster Recovery

### What If Cleanup Fails?

**Scenario 1: Script interrupted before cleanup**
```bash
# Manually destroy infrastructure
cd /path/to/ccloud-test-case
terraform destroy -auto-approve
```

**Scenario 2: Terraform state corrupted**
```bash
# List resources manually
ccloud compute instances list

# Delete specific instance
ccloud compute instances delete <INSTANCE_ID>

# Release IP
ccloud network ips release <IP_ADDRESS>
```

**Scenario 3: Lost Terraform state**
```bash
# Import existing resources
terraform import ccloud_instance.analysis_vm <INSTANCE_ID>
terraform import ccloud_reserved_ip.static_ip <IP_ID>

# Then destroy normally
terraform destroy -auto-approve
```

## Monitoring & Observability

### Logging Levels
The `deploy.sh` script provides color-coded logging:
- 🔵 **INFO**: Normal operation progress
- 🟢 **SUCCESS**: Successful completion of step
- 🟡 **WARNING**: Non-fatal issues
- 🔴 **ERROR**: Fatal errors requiring attention

### Metrics to Track
1. **Provisioning Time**: Time to reach "Running" state
2. **Build Time**: Docker image build duration
3. **Execution Time**: Analysis computation time
4. **Transfer Time**: Result download duration
5. **Cleanup Time**: Destruction duration
6. **Total Pipeline Time**: End-to-end duration

### Adding Custom Metrics
```bash
# Example: Add timing metrics
START_TIME=$(date +%s)
# ... operation ...
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "Operation took $ELAPSED seconds" >> metrics.log
```

## Testing Strategy

### Unit Testing (analysis.py)
```python
# test_analysis.py
import pytest
from analysis import monte_carlo_option_pricing

def test_mc_convergence():
    result = monte_carlo_option_pricing(n_sims=1000000)
    assert abs(result['pricing_error']) < 0.5  # Within $0.50
```

### Integration Testing (deploy.sh)
```bash
# test_deploy.sh
# Mock Carolina Cloud CLI responses
export CCLOUD_CLI_MOCK=true

# Run with minimal config
MAX_WAIT_TIME=60 \
SIMULATIONS=1000 \
./deploy.sh

# Verify results exist
test -f results/analysis_results.csv
```

### Load Testing
```bash
# Run multiple concurrent pipelines
for i in {1..5}; do
    INSTANCE_NAME="load-test-$i" \
    RESULTS_DIR="./results/test-$i" \
    ./deploy.sh &
done
wait
```

## Troubleshooting Playbook

### Issue: "Terraform provider not found"
**Cause**: Carolina Cloud provider not installed  
**Solution**:
```bash
terraform init -upgrade
```

### Issue: "SSH timeout"
**Cause**: Instance not fully initialized or network issues  
**Solution**:
```bash
# Increase timeout
MAX_WAIT_TIME=1200 ./deploy.sh

# Check instance console logs
ccloud compute instances console-log <INSTANCE_ID>
```

### Issue: "Docker command not found"
**Cause**: User data script failed or incomplete  
**Solution**:
```bash
# SSH to instance
ssh -i ~/.ssh/id_rsa ubuntu@<IP>

# Check Docker status
sudo systemctl status docker

# Reinstall if needed
sudo apt-get update && sudo apt-get install -y docker-ce
```

### Issue: "Out of memory during analysis"
**Cause**: Insufficient RAM for simulation size  
**Solution**:
```python
# In analysis.py, reduce simulation size
SIMULATIONS = 1_000_000  # Instead of 10M

# OR upgrade instance plan in main.tf
plan = "epyc-8-32"  # 32GB RAM
```

## Future Enhancements

### Potential Improvements
1. **CI/CD Integration**: GitHub Actions/GitLab CI pipeline
2. **Multi-Region Support**: Deploy to multiple regions
3. **Results Database**: Store results in PostgreSQL/TimescaleDB
4. **Visualization Dashboard**: Real-time Grafana/Plotly dashboard
5. **Parameter Sweep**: Automated exploration of parameter space
6. **Spot Instance Support**: Reduce costs by 60-90%
7. **GPU Acceleration**: Use NVIDIA/AMD GPUs for compute
8. **Kubernetes Deployment**: Scale with K8s on Carolina Cloud

### Roadmap
- **Q1 2026**: Add GPU support for Monte Carlo
- **Q2 2026**: Implement distributed computing (Ray, Dask)
- **Q3 2026**: Web UI for pipeline management
- **Q4 2026**: ML model training pipelines

## References

- [Carolina Cloud Documentation](https://docs.carolinacloud.io)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices)
- [Docker Multi-Stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [Monte Carlo Methods in Finance](https://en.wikipedia.org/wiki/Monte_Carlo_methods_in_finance)
- [AMD EPYC Architecture](https://www.amd.com/en/processors/epyc)

