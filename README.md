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

### Manual Steps After Project Creation

After running the create-migrate-project script, follow these steps to import server inventory via CSV:

1. **Access the Azure Migrate Project**:
   - Use the portal URL provided by the script. The URL follows this format:
   ```
   portal.azure.com/#view/Microsoft_Azure_Migrate/AmhResourceMenuBlade/~/serverGoal/resourceId/%2Fsubscriptions%2F{SUBSCRIPTION_ID}%2FresourceGroups%2F{RESOURCE_GROUP}%2Fproviders%2FMicrosoft.Migrate%2FMigrateProjects%2F{MIGRATE_PROJECT_NAME}
   ```
   Where:
   - `{SUBSCRIPTION_ID}`: Your Azure Subscription ID
   - `{RESOURCE_GROUP}`: Your Resource Group name
   - `{MIGRATE_PROJECT_NAME}`: Your Azure Migrate project name

2. **Add Assessment Tool**:
   - In the Azure Migrate project page, find the "Add more assessment tools?" question
   - Click "Click here" to add a new assessment tool
   - Select "Azure Migrate: Discovery and assessment"

3. **Import Server Inventory**:
   - In "Migration goals" > "Servers, databases and web apps" > "Azure Migrate: Discovery and assessment", select "Discover"
   - Choose "Server Inventory (CSV)" as the File type
   - In step 3 of the wizard, import the sample CSV file from `./samples/AzureMigrateimporttemplate.csv`

4. **View Imported Servers**:
   - Return to the Azure Migrate project
   - Navigate to "Migration Goals" > "Servers, databases and web apps"
   - Under "Azure Migrate: Discovery and assessment", you should see 10 servers that were imported
   - Click the "10" to see the detailed list of imported servers under the "Import based" tab 