# Azure Migrate Lab Automation

This project provides automation scripts for setting up and managing an Azure Migrate lab environment, focusing on automating the migration process for VMware, Hyper-V, or physical servers (including AWS/GCP EC2 instances) to Azure.

## Prerequisites

Before using these scripts, ensure you have the following prerequisites:

1. **Azure CLI**: Install the Azure CLI by following the [official documentation](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
   
   ```bash
   # macOS (using Homebrew)
   brew update && brew install azure-cli
   
   # Ubuntu/Debian
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   
   # Windows
   # Download and run the MSI installer from: https://aka.ms/installazurecliwindows
   ```

2. **Azure Subscription**: You need an active Azure subscription with sufficient permissions to create resources.

3. **Source Environment**: Access to one of the following environments:
   - VMware vSphere
   - Microsoft Hyper-V
   - AWS EC2 instances (discovered using the Physical server method)
   - GCP instances (discovered using the Physical server method)
   - On-premises physical servers

4. **Appliance Server Requirements** (for Physical/AWS/GCP discovery):
   - Windows Server 2022 (recommended) or Windows Server 2019
   - 16 GB RAM, 8 vCPUs, approximately 80 GB of disk storage
   - Static or dynamic IP address with internet access (direct or via proxy)
   - Outbound internet connectivity to required Azure endpoints

## Configuration

1. Copy the environment template file to create a local configuration:

   ```bash
   cp config/env.template .env
   ```

2. Edit the `.env` file and provide your specific configuration values:
   - `SUBSCRIPTION_ID`: Your Azure Subscription ID
   - `RESOURCE_GROUP`: Name for the resource group (default: AzureMigrateLab-RG)
   - `LOCATION`: Azure region for deployment (default: eastus)
   - `MIGRATE_PROJECT_NAME`: Name for your Azure Migrate project
   - `VNET_NAME`: Name for the target virtual network
   - `VNET_ADDRESS_PREFIX`: Address space for the virtual network
   - `SUBNET_NAME`: Name for the target subnet
   - `SUBNET_ADDRESS_PREFIX`: Address range for the subnet
   - `SOURCE_TYPE`: Type of source environment (VMware, Hyper-V, or Physical)
     - Use "Physical" for AWS EC2 instances, GCP VMs, or on-premises physical servers

## Usage

### 1. Create Azure Migrate Project

Run the following script to create an Azure Migrate project and the necessary infrastructure:

```bash
# Make the script executable
chmod +x scripts/create-migrate-project.sh

# Run with default values from .env file
./scripts/create-migrate-project.sh

# OR specify parameters directly
./scripts/create-migrate-project.sh \
  --subscription-id "your-subscription-id" \
  --resource-group "YourResourceGroup" \
  --location "westus2" \
  --project-name "YourMigrateProject" \
  --vnet-name "YourVNet" \
  --vnet-prefix "10.1.0.0/16" \
  --subnet-name "YourSubnet" \
  --subnet-prefix "10.1.0.0/24" \
  --source-type "Physical"  # Use "Physical" for AWS EC2 instances
```

This script performs the following actions:
- Logs in to Azure (if not already logged in)
- Sets the subscription context
- Creates a resource group (if it doesn't exist)
- Creates an Azure Migrate project using ARM templates
  - Includes assessment and migration solution components
- Creates a virtual network and subnet for the target environment
- Provides information about the next steps

### 2. Next Steps for AWS EC2 Instance Discovery

After running the script, follow these steps to set up the Azure Migrate appliance for AWS EC2 discovery:

1. Access the Azure Migrate project in the Azure portal using the URL provided by the script
2. Download the Azure Migrate appliance for "Physical or other servers" discovery
3. Set up the appliance on a Windows Server 2022/2019 machine with appropriate resources:
   - 16 GB RAM, 8 vCPUs, 80 GB disk storage
   - Internet connectivity to Azure
4. Prepare your AWS EC2 instances for discovery:
   - For Windows EC2 instances: Enable inbound connections on WinRM port 5985 (HTTP)
   - For Linux EC2 instances: Enable inbound connections on port 22 (TCP)
5. Configure the appliance with appropriate credentials:
   - For Windows servers: Domain account for domain-joined servers, local account for non-domain servers
   - For Linux servers: Account with sudo access or a non-sudo account with necessary permissions

#### Windows Server Preparation

For Windows EC2 instances, ensure:
- WinRM is enabled and configured for HTTP connections
- Inbound port 5985 is open in the security group/firewall
- Remote Management Users group has the user account being used for discovery

#### Linux Server Preparation

For Linux EC2 instances, ensure:
- SSH is enabled and port 22 is open in the security group/firewall
- The account used has appropriate sudo access or necessary permissions

### 3. Perform Discovery and Assessment

Once the appliance is configured:
1. The appliance will connect to your AWS EC2 instances based on the provided credentials
2. Discovery of servers will take approximately 2 minutes per 100 servers
3. Software inventory and SQL Server discovery will begin automatically
4. After discovery completes, you can create assessments in the Azure Migrate project

### Future Automation (Planned)

The following steps will be automated in future script releases:

- Appliance deployment and configuration
- Assessment creation and management
- Replication setup and monitoring
- Test migration operations
- Migration execution and completion

## Troubleshooting

### Common Issues

1. **Authentication Errors**:
   ```
   az login
   ```

2. **Resource Already Exists**:
   If resources already exist, the script will attempt to use them rather than creating new ones.

3. **Permission Issues**:
   Ensure your Azure account has sufficient permissions to create resources.

4. **ARM Deployment Failures**:
   If the Azure Migrate project deployment fails, check the deployment status in the Azure Portal:
   ```
   # Check deployment status
   az deployment group show --resource-group "YourResourceGroup" --name "YourMigrateProject-deployment"
   ```

5. **AWS EC2 Connection Issues**:
   - Verify network connectivity between the appliance and AWS EC2 instances
   - Check security group rules to ensure required ports are open
   - Verify credentials have appropriate permissions

## References

- [Azure Migrate Documentation](https://docs.microsoft.com/en-us/azure/migrate/)
- [Tutorial: Discover Physical Servers](https://learn.microsoft.com/en-us/azure/migrate/tutorial-discover-physical?view=migrate-classic)
- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [Azure ARM Templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/)
- [Complete Automation Plan](plans/azure-migrate-lab-automation-plan.md) 