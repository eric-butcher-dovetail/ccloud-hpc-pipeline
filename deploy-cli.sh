#!/bin/bash

################################################################################
# Carolina Cloud HPC Data Analysis Pipeline - CLI-Based Deployment
# 
# This is the WORKING version that uses the Carolina Cloud CLI directly.
# Use this instead of deploy.sh (which assumes a Terraform provider exists).
#
# This script automates the complete lifecycle:
# 1. VM provisioning via CLI
# 2. Instance readiness verification
# 3. Code deployment
# 4. Analysis execution via Docker
# 5. Results retrieval
# 6. Infrastructure teardown (cost control)
################################################################################

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration from environment variables with defaults
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/id_rsa}"
SSH_KEY_PUB="${SSH_KEY_PUB:-$HOME/.ssh/id_rsa.pub}"
RESULTS_DIR="${RESULTS_DIR:-./results}"
MAX_WAIT_TIME="${MAX_WAIT_TIME:-600}"  # 10 minutes
CHECK_INTERVAL="${CHECK_INTERVAL:-10}"  # 10 seconds
INSTANCE_NAME="${INSTANCE_NAME:-data-analysis-pipeline}"

# VM Configuration (AMD EPYC-equivalent specs)
VM_CPUS="${VM_CPUS:-4}"
VM_RAM="${VM_RAM:-16}"
VM_DISK="${VM_DISK:-50}"
VM_TIER="${VM_TIER:-high-performance}"

# Global variable to store instance ID
INSTANCE_ID=""

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Cleanup function (always runs on exit)
cleanup() {
    local exit_code=$?
    log_info "Starting cleanup process..."
    
    if [ -n "$INSTANCE_ID" ]; then
        log_info "Destroying instance $INSTANCE_ID to prevent unnecessary costs..."
        if ccloud destroy "$INSTANCE_ID" --force 2>/dev/null || ccloud destroy "$INSTANCE_ID" 2>/dev/null; then
            log_success "Instance destroyed successfully"
        else
            log_error "Failed to destroy instance - MANUAL CLEANUP REQUIRED!"
            log_error "Run: ccloud destroy $INSTANCE_ID"
            log_error "Or check console: https://console.carolinacloud.io"
            exit_code=1
        fi
    else
        log_warning "No instance ID found, skipping destroy"
    fi
    
    if [ $exit_code -eq 0 ]; then
        log_success "Pipeline completed successfully"
    else
        log_error "Pipeline failed with exit code: $exit_code"
    fi
    
    exit $exit_code
}

# Register cleanup function to run on exit
trap cleanup EXIT INT TERM

# Validate prerequisites
validate_prerequisites() {
    log_info "Validating prerequisites..."
    
    # Check Carolina Cloud CLI
    if ! command -v ccloud &> /dev/null; then
        log_error "Carolina Cloud CLI not found. Please install from: https://cli.carolinacloud.io"
        exit 1
    fi
    
    # Verify API key is set
    if [ -z "$CCLOUD_API_KEY" ]; then
        log_error "CCLOUD_API_KEY environment variable not set."
        log_error "Get your API key from: https://console.carolinacloud.io/settings/api"
        log_error "Then add to ~/.zshrc: export CCLOUD_API_KEY=your_api_key"
        exit 1
    fi
    
    # Test API key works
    if ! ccloud list &> /dev/null; then
        log_error "API key authentication failed. Please verify your CCLOUD_API_KEY"
        exit 1
    fi
    
    # Check SSH keys
    if [ ! -f "$SSH_KEY_PATH" ] || [ ! -f "$SSH_KEY_PUB" ]; then
        log_error "SSH keys not found at $SSH_KEY_PATH"
        log_info "Generate keys with: ssh-keygen -t rsa -b 4096"
        exit 1
    fi
    
    # Check required files
    for file in Dockerfile analysis.py; do
        if [ ! -f "$file" ]; then
            log_error "Required file not found: $file"
            exit 1
        fi
    done
    
    log_success "All prerequisites validated"
}

# Provision VM via CLI
provision_vm() {
    log_info "Provisioning Carolina Cloud VM..."
    log_info "Configuration: ${VM_CPUS} vCPUs, ${VM_RAM}GB RAM, ${VM_DISK}GB disk"
    log_info "Tier: $VM_TIER"
    
    # Create VM
    local output
    output=$(ccloud new vm \
        --name "$INSTANCE_NAME" \
        --cpus "$VM_CPUS" \
        --ram "$VM_RAM" \
        --disk "$VM_DISK" \
        --tier "$VM_TIER" \
        --ssh-key "$SSH_KEY_PUB" \
        --static-ip 2>&1)
    
    if [ $? -ne 0 ]; then
        log_error "Failed to create VM"
        echo "$output"
        exit 1
    fi
    
    # Extract instance ID from output (adjust parsing based on actual output format)
    INSTANCE_ID=$(echo "$output" | grep -oE '[a-f0-9-]{36}' | head -1)
    
    if [ -z "$INSTANCE_ID" ]; then
        # Try alternative: list instances and get the most recent
        INSTANCE_ID=$(ccloud list | grep "$INSTANCE_NAME" | head -1 | awk '{print $1}')
    fi
    
    if [ -z "$INSTANCE_ID" ]; then
        log_error "Could not determine instance ID"
        echo "$output"
        exit 1
    fi
    
    log_success "VM provisioned with ID: $INSTANCE_ID"
}

# Get instance details
get_instance_ip() {
    local details
    details=$(ccloud get "$INSTANCE_ID" 2>&1)
    
    # Parse IP address from output (adjust regex based on actual format)
    local ip
    ip=$(echo "$details" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
    
    echo "$ip"
}

# Wait for instance to be running and SSH ready
wait_for_instance() {
    local elapsed=0
    local instance_ip=""
    
    log_info "Waiting for instance to be fully ready..."
    
    # Wait for IP to be assigned
    while [ $elapsed -lt $MAX_WAIT_TIME ]; do
        instance_ip=$(get_instance_ip)
        if [ -n "$instance_ip" ]; then
            log_info "Instance IP: $instance_ip"
            break
        fi
        echo -n "."
        sleep $CHECK_INTERVAL
        elapsed=$((elapsed + CHECK_INTERVAL))
    done
    
    if [ -z "$instance_ip" ]; then
        log_error "Failed to get instance IP within $MAX_WAIT_TIME seconds"
        return 1
    fi
    
    # Wait for SSH to be available
    elapsed=0
    while [ $elapsed -lt $MAX_WAIT_TIME ]; do
        if ssh -o StrictHostKeyChecking=no \
               -o UserKnownHostsFile=/dev/null \
               -o ConnectTimeout=5 \
               -i "$SSH_KEY_PATH" \
               "root@$instance_ip" \
               "echo 'ready'" &>/dev/null; then
            log_success "Instance is ready (elapsed: ${elapsed}s)"
            echo "$instance_ip"
            return 0
        fi
        
        echo -n "."
        sleep $CHECK_INTERVAL
        elapsed=$((elapsed + CHECK_INTERVAL))
    done
    
    log_error "Instance failed to become ready within $MAX_WAIT_TIME seconds"
    return 1
}

# Install Docker on instance
install_docker() {
    local instance_ip=$1
    
    log_info "Installing Docker on instance..."
    
    ssh -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -i "$SSH_KEY_PATH" \
        "root@$instance_ip" \
        'bash -s' << 'EOF'
set -e
apt-get update -qq
apt-get install -y -qq docker.io
systemctl start docker
systemctl enable docker
mkdir -p /root/pipeline/output
EOF
    
    if [ $? -eq 0 ]; then
        log_success "Docker installed successfully"
    else
        log_error "Failed to install Docker"
        return 1
    fi
}

# Deploy code to instance
deploy_code() {
    local instance_ip=$1
    
    log_info "Deploying analysis code to instance..."
    
    local scp_opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $SSH_KEY_PATH"
    
    if scp $scp_opts Dockerfile analysis.py "root@$instance_ip:/root/pipeline/"; then
        log_success "Code deployed successfully"
    else
        log_error "Failed to deploy code"
        return 1
    fi
}

# Build Docker image on instance
build_docker_image() {
    local instance_ip=$1
    
    log_info "Building Docker image on instance..."
    
    if ssh -o StrictHostKeyChecking=no \
           -o UserKnownHostsFile=/dev/null \
           -i "$SSH_KEY_PATH" \
           "root@$instance_ip" \
           "cd /root/pipeline && docker build -t analysis-pipeline:latest ."; then
        log_success "Docker image built successfully"
    else
        log_error "Failed to build Docker image"
        return 1
    fi
}

# Execute analysis
execute_analysis() {
    local instance_ip=$1
    
    log_info "Executing data analysis pipeline..."
    log_info "This may take several minutes for large-scale Monte Carlo simulation..."
    
    if ssh -o StrictHostKeyChecking=no \
           -o UserKnownHostsFile=/dev/null \
           -i "$SSH_KEY_PATH" \
           "root@$instance_ip" \
           "docker run --rm -v /root/pipeline/output:/app/output analysis-pipeline:latest"; then
        log_success "Analysis completed successfully"
    else
        log_error "Analysis execution failed"
        return 1
    fi
}

# Download results
download_results() {
    local instance_ip=$1
    
    log_info "Downloading results..."
    
    mkdir -p "$RESULTS_DIR"
    
    local scp_opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $SSH_KEY_PATH"
    
    if scp $scp_opts -r "root@$instance_ip:/root/pipeline/output/"*.csv "$RESULTS_DIR/"; then
        log_success "Results downloaded to: $RESULTS_DIR"
        
        log_info "Analysis Results:"
        echo "----------------------------------------"
        if [ -f "$RESULTS_DIR/analysis_results.csv" ]; then
            cat "$RESULTS_DIR/analysis_results.csv"
        fi
        echo "----------------------------------------"
    else
        log_error "Failed to download results"
        return 1
    fi
}

# Main execution flow
main() {
    log_info "=========================================="
    log_info "Carolina Cloud HPC Pipeline (CLI-Based)"
    log_info "=========================================="
    log_info "Start time: $(date)"
    log_info ""
    
    # Step 1: Validate environment
    validate_prerequisites
    
    # Step 2: Provision VM
    provision_vm
    
    # Step 3: Wait for instance and get IP
    local instance_ip
    if ! instance_ip=$(wait_for_instance); then
        log_error "Instance readiness check failed"
        exit 1
    fi
    
    log_success "Instance ready at: $instance_ip"
    
    # Step 4: Install Docker
    if ! install_docker "$instance_ip"; then
        log_error "Docker installation failed"
        exit 1
    fi
    
    # Step 5: Deploy code
    if ! deploy_code "$instance_ip"; then
        log_error "Code deployment failed"
        exit 1
    fi
    
    # Step 6: Build Docker image
    if ! build_docker_image "$instance_ip"; then
        log_error "Docker build failed"
        exit 1
    fi
    
    # Step 7: Execute analysis
    if ! execute_analysis "$instance_ip"; then
        log_error "Analysis execution failed"
        exit 1
    fi
    
    # Step 8: Download results
    if ! download_results "$instance_ip"; then
        log_error "Results download failed"
        exit 1
    fi
    
    log_info ""
    log_info "=========================================="
    log_success "Pipeline completed successfully!"
    log_info "End time: $(date)"
    log_info "=========================================="
    log_info ""
    log_info "Results location: $RESULTS_DIR"
    log_info "Infrastructure will be destroyed on exit..."
}

# Execute main function
main "$@"
