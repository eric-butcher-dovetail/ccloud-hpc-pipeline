# Important Note: Terraform vs CLI Approach

## ⚠️ Terraform Provider Status

**The `carolinacloud/ccloud` Terraform provider does NOT currently exist in the Terraform Registry.**

When you run `terraform init`, you will see this error:
```
Error: Failed to query available provider packages
Could not retrieve the list of available versions for provider
carolinacloud/ccloud: provider registry registry.terraform.io does not have
a provider named registry.terraform.io/carolinacloud/ccloud
```

## ✅ What Works: CLI-Based Approach

**Use `deploy-cli.sh` instead of `deploy.sh`**

The `deploy-cli.sh` script uses the Carolina Cloud CLI directly and is **fully functional**:

```bash
./deploy-cli.sh
```

This script:
- ✅ Uses `ccloud new vm` to provision instances
- ✅ Uses `ccloud destroy` to clean up
- ✅ Works with your `CCLOUD_API_KEY`
- ✅ Includes all the same features (Docker, analysis, results)

## 📚 Why Two Scripts?

### `deploy.sh` (Terraform-based - CONCEPTUAL)
- Shows what Infrastructure-as-Code WOULD look like
- Educational/reference implementation
- **Does not work** without a Terraform provider
- Kept for demonstration purposes

### `deploy-cli.sh` (CLI-based - WORKING)
- **This is the one you should use!**
- Uses Carolina Cloud CLI commands directly
- Fully functional and tested
- Provides the same automation and cost controls

## 🔧 Options for Terraform Users

If you really want to use Terraform, you have these options:

### Option 1: Use null_resource with local-exec (Workaround)

```hcl
resource "null_resource" "carolina_cloud_vm" {
  provisioner "local-exec" {
    command = <<-EOT
      ccloud new vm \
        --name my-instance \
        --cpus 4 \
        --ram 16 \
        --disk 50 \
        --tier high-performance \
        --ssh-key ~/.ssh/id_rsa.pub \
        --static-ip
    EOT
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = "ccloud destroy ${self.id}"
  }
}
```

**Pros:** Uses Terraform workflow  
**Cons:** Not true IaC, harder to manage state

### Option 2: Create a Custom Provider

If you're a Go developer, you could create a Terraform provider:
- https://developer.hashicorp.com/terraform/tutorials/providers-plugin-framework
- Wrap the Carolina Cloud CLI or API
- Publish to Terraform Registry

### Option 3: Use the CLI (Recommended)

Just use `deploy-cli.sh` - it's simpler and works perfectly!

## 📊 Feature Comparison

| Feature | deploy.sh (Terraform) | deploy-cli.sh (CLI) |
|---------|----------------------|---------------------|
| **Status** | ❌ Doesn't work | ✅ Works |
| **Provisioning** | Terraform | CLI commands |
| **State Management** | Terraform state | Script variables |
| **Cleanup** | `terraform destroy` | `ccloud destroy` |
| **Dependencies** | Terraform + CLI | CLI only |
| **Complexity** | Higher | Lower |
| **Recommended** | No | **Yes** |

## 🚀 Quick Start (Use This!)

```bash
# 1. Set your API key
export CCLOUD_API_KEY=your_api_key

# 2. Run the working script
./deploy-cli.sh

# 3. Results appear in ./results/
```

## 🔮 Future

If Carolina Cloud releases an official Terraform provider in the future:
1. Update `main.tf` to use the real provider
2. Test `deploy.sh` works
3. Update this note

Until then, **use `deploy-cli.sh`** for all deployments!

## ❓ Questions?

- **"Why keep deploy.sh if it doesn't work?"**  
  Educational purposes - shows IaC concepts and what the implementation would look like

- **"Can I modify deploy-cli.sh?"**  
  Absolutely! It's a standard bash script using CLI commands

- **"Is deploy-cli.sh production-ready?"**  
  Yes! It includes error handling, cleanup, and all necessary features

- **"Will you fix deploy.sh?"**  
  We can't - it requires Carolina Cloud to publish a Terraform provider

---

**Bottom Line:** Use `deploy-cli.sh` - it works great! 🎉
