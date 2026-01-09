# ⚠️  WARNING: This is a CONCEPTUAL example!
# The carolinacloud/ccloud Terraform provider does not currently exist in the registry.
# 
# This file shows what the infrastructure-as-code WOULD look like if the provider existed.
# For ACTUAL deployment, use deploy-cli.sh which uses the Carolina Cloud CLI directly.
#
# If you want to use this conceptual approach, you would need to:
# 1. Create or find a custom Terraform provider for Carolina Cloud
# 2. Or use a generic provider like "null_resource" with "local-exec" to call the CLI
#
# See: https://developer.hashicorp.com/terraform/language/resources/provisioners/local-exec

terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# NOTE: Using null_resource with local-exec as a workaround
# This calls the Carolina Cloud CLI instead of using a native provider

# Variables for configuration
variable "ssh_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "instance_name" {
  description = "Name of the Carolina Cloud instance"
  type        = string
  default     = "data-analysis-pipeline"
}

variable "region" {
  description = "Carolina Cloud region"
  type        = string
  default     = "us-east-1"
}

# SSH Key Resource
resource "ccloud_ssh_key" "pipeline_key" {
  name       = "${var.instance_name}-key"
  public_key = file(pathexpand(var.ssh_key_path))
}

# Carolina Cloud Instance
resource "ccloud_instance" "analysis_vm" {
  name   = var.instance_name
  region = var.region
  
  # AMD EPYC plan for high-performance computing
  plan = "epyc-4-16"  # 4 vCPUs, 16GB RAM
  
  # Ubuntu 24.04 LTS
  os_image = "ubuntu-24.04"
  
  # Attach SSH key for access
  ssh_keys = [ccloud_ssh_key.pipeline_key.id]
  
  # Enable backups: false for cost savings (stateless workload)
  backups_enabled = false
  
  # Tags for organization
  tags = {
    Environment = "test"
    Purpose     = "data-analysis"
    Automated   = "true"
    ManagedBy   = "terraform"
  }
  
  # User data script to install Docker and prepare environment
  user_data = <<-EOF
    #!/bin/bash
    set -e
    
    # Update system
    apt-get update
    apt-get upgrade -y
    
    # Install Docker
    apt-get install -y ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Allow ubuntu user to run docker without sudo
    usermod -aG docker ubuntu
    
    # Create working directory
    mkdir -p /home/ubuntu/pipeline
    chown ubuntu:ubuntu /home/ubuntu/pipeline
    
    # Signal completion
    touch /tmp/init-complete
  EOF
}

# Static/Public IP
resource "ccloud_reserved_ip" "static_ip" {
  region = var.region
}

# Attach the static IP to the instance
resource "ccloud_reserved_ip_attachment" "ip_attachment" {
  reserved_ip_id = ccloud_reserved_ip.static_ip.id
  instance_id    = ccloud_instance.analysis_vm.id
}

# Outputs for automation script
output "instance_id" {
  description = "ID of the created instance"
  value       = ccloud_instance.analysis_vm.id
}

output "instance_ip" {
  description = "Public IP address of the instance"
  value       = ccloud_reserved_ip.static_ip.address
}

output "instance_status" {
  description = "Status of the instance"
  value       = ccloud_instance.analysis_vm.status
}

output "ssh_user" {
  description = "SSH username for the instance"
  value       = "ubuntu"
}

