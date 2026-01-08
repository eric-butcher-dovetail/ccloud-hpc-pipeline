#!/bin/bash

################################################################################
# Carolina Cloud HPC Data Analysis Pipeline - Deployment Orchestrator
# 
# This script automates the complete lifecycle:
# 1. Infrastructure provisioning (Terraform)
# 2. Instance readiness verification
# 3. Code deployment
# 4. Analysis execution via Docker
# 5. Results retrieval
# 6. Infrastructure teardown (cost control)
#
# Prerequisites:
# - Carolina Cloud CLI authenticated
# - Terraform installed
# - SSH key configured
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
    
    if [ -f "terraform.tfstate" ]; then
        log_info "Destroying infrastructure to prevent unnecessary costs..."
        if terraform destroy -auto-approve; then
            log_success "Infrastructure destroyed successfully"
        else
            log_error "Failed to destroy infrastructure - MANUAL CLEANUP REQUIRED!"
            log_error "Run: terraform destroy"
            exit_code=1
        fi
    else
        log_warning "No terraform state found, skipping destroy"
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
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform not found. Please install: https://www.terraform.io/downloads"
        exit 1
    fi
    
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
    
    # Check SSH keys
    if [ ! -f "$SSH_KEY_PATH" ] || [ ! -f "$SSH_KEY_PUB" ]; then
        log_error "SSH keys not found at $SSH_KEY_PATH"
        log_info "Generate keys with: ssh-keygen -t rsa -b 4096"
        exit 1
    fi
    
    # Check required files
    for file in main.tf Dockerfile analysis.py; do
        if [ ! -f "$file" ]; then
            log_error "Required file not found: $file"
            exit 1
        fi
    done
    
    log_success "All prerequisites validated"
}

# Initialize Terraform
init_terraform() {
    log_info "Initializing Terraform..."
    
    if terraform init; then
        log_success "Terraform initialized"
    else
        log_error "Terraform initialization failed"
        exit 1
    fi
}

# Provision infrastructure
provision_infrastructure() {
    log_info "Provisioning Carolina Cloud infrastructure..."
    log_info "Instance type: AMD EPYC (epyc-4-16)"
    log_info "OS: Ubuntu 24.04"
    
    if terraform apply -auto-approve \
        -var="ssh_key_path=$SSH_KEY_PUB" \
        -var="instance_name=$INSTANCE_NAME"; then
        log_success "Infrastructure provisioned"
    else
        log_error "Infrastructure provisioning failed"
        exit 1
    fi
}

# Extract Terraform outputs
get_terraform_output() {
    local output_name=$1
    terraform output -raw "$output_name" 2>/dev/null || echo ""
}

# Wait for instance to be running and SSH ready
wait_for_instance() {
    local instance_ip=$1
    local ssh_user=$2
    local elapsed=0
    
    log_info "Waiting for instance to be fully ready..."
    log_info "Instance IP: $instance_ip"
    
    # Wait for SSH to be available
    while [ $elapsed -lt $MAX_WAIT_TIME ]; do
        if ssh -o StrictHostKeyChecking=no \
               -o UserKnownHostsFile=/dev/null \
               -o ConnectTimeout=5 \
               -i "$SSH_KEY_PATH" \
               "$ssh_user@$instance_ip" \
               "test -f /tmp/init-complete" 2>/dev/null; then
            log_success "Instance is ready (elapsed: ${elapsed}s)"
            return 0
        fi
        
        echo -n "."
        sleep $CHECK_INTERVAL
        elapsed=$((elapsed + CHECK_INTERVAL))
    done
    
    log_error "Instance failed to become ready within $MAX_WAIT_TIME seconds"
    return 1
}

# Deploy code to instance
deploy_code() {
    local instance_ip=$1
    local ssh_user=$2
    
    log_info "Deploying analysis code to instance..."
    
    # Create SCP options
    local scp_opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $SSH_KEY_PATH"
    
    # Copy files
    if scp $scp_opts Dockerfile analysis.py "$ssh_user@$instance_ip:~/pipeline/"; then
        log_success "Code deployed successfully"
    else
        log_error "Failed to deploy code"
        return 1
    fi
}

# Build Docker image on instance
build_docker_image() {
    local instance_ip=$1
    local ssh_user=$2
    
    log_info "Building Docker image on instance..."
    
    if ssh -o StrictHostKeyChecking=no \
           -o UserKnownHostsFile=/dev/null \
           -i "$SSH_KEY_PATH" \
           "$ssh_user@$instance_ip" \
           "cd ~/pipeline && docker build -t analysis-pipeline:latest ."; then
        log_success "Docker image built successfully"
    else
        log_error "Failed to build Docker image"
        return 1
    fi
}

# Execute analysis
execute_analysis() {
    local instance_ip=$1
    local ssh_user=$2
    
    log_info "Executing data analysis pipeline..."
    log_info "This may take several minutes for large-scale Monte Carlo simulation..."
    
    # Run Docker container and stream output
    if ssh -o StrictHostKeyChecking=no \
           -o UserKnownHostsFile=/dev/null \
           -i "$SSH_KEY_PATH" \
           "$ssh_user@$instance_ip" \
           "docker run --rm -v ~/pipeline/output:/app/output analysis-pipeline:latest"; then
        log_success "Analysis completed successfully"
    else
        log_error "Analysis execution failed"
        return 1
    fi
}

# Download results
download_results() {
    local instance_ip=$1
    local ssh_user=$2
    
    log_info "Downloading results..."
    
    # Create results directory
    mkdir -p "$RESULTS_DIR"
    
    # Download all CSV files
    local scp_opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $SSH_KEY_PATH"
    
    if scp $scp_opts -r "$ssh_user@$instance_ip:~/pipeline/output/*.csv" "$RESULTS_DIR/"; then
        log_success "Results downloaded to: $RESULTS_DIR"
        
        # Display results
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
    log_info "Carolina Cloud HPC Pipeline Deployment"
    log_info "=========================================="
    log_info "Start time: $(date)"
    log_info ""
    
    # Step 1: Validate environment
    validate_prerequisites
    
    # Step 2: Initialize Terraform
    init_terraform
    
    # Step 3: Provision infrastructure
    provision_infrastructure
    
    # Step 4: Extract instance details
    local instance_ip=$(get_terraform_output "instance_ip")
    local ssh_user=$(get_terraform_output "ssh_user")
    local instance_id=$(get_terraform_output "instance_id")
    
    if [ -z "$instance_ip" ]; then
        log_error "Failed to retrieve instance IP from Terraform output"
        exit 1
    fi
    
    log_success "Instance provisioned: $instance_id"
    log_info "Public IP: $instance_ip"
    
    # Step 5: Wait for instance to be ready
    if ! wait_for_instance "$instance_ip" "$ssh_user"; then
        log_error "Instance readiness check failed"
        exit 1
    fi
    
    # Step 6: Deploy code
    if ! deploy_code "$instance_ip" "$ssh_user"; then
        log_error "Code deployment failed"
        exit 1
    fi
    
    # Step 7: Build Docker image
    if ! build_docker_image "$instance_ip" "$ssh_user"; then
        log_error "Docker build failed"
        exit 1
    fi
    
    # Step 8: Execute analysis
    if ! execute_analysis "$instance_ip" "$ssh_user"; then
        log_error "Analysis execution failed"
        exit 1
    fi
    
    # Step 9: Download results
    if ! download_results "$instance_ip" "$ssh_user"; then
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

