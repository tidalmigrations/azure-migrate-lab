#!/bin/bash

# Azure Migrate Project Creation Script
# This script automates the creation of an Azure Migrate project and required resources

# Exit on error
set -e

# Load configuration from .env file if it exists
if [ -f .env ]; then
    echo "Loading configuration from .env file..."
    source .env
fi

# Configuration variables with defaults
SUBSCRIPTION_ID=${SUBSCRIPTION_ID:-""}
RESOURCE_GROUP=${RESOURCE_GROUP:-"AzureMigrateLab-RG"}
LOCATION=${LOCATION:-"eastus"}
MIGRATE_PROJECT_NAME=${MIGRATE_PROJECT_NAME:-"AzureMigrateProject"}
VNET_NAME=${VNET_NAME:-"AzureMigrateLab-VNet"}
VNET_ADDRESS_PREFIX=${VNET_ADDRESS_PREFIX:-"10.0.0.0/16"}
SUBNET_NAME=${SUBNET_NAME:-"AzureMigrateLab-Subnet"}
SUBNET_ADDRESS_PREFIX=${SUBNET_ADDRESS_PREFIX:-"10.0.0.0/24"}
SOURCE_TYPE=${SOURCE_TYPE:-"Physical"} # Options: VMware, Hyper-V, Physical (for AWS/GCP/on-prem physical servers)

# Function to display script usage
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --subscription-id ID       Azure Subscription ID"
    echo "  --resource-group NAME      Resource Group Name (default: $RESOURCE_GROUP)"
    echo "  --location LOCATION        Azure Region (default: $LOCATION)"
    echo "  --project-name NAME        Azure Migrate Project Name (default: $MIGRATE_PROJECT_NAME)"
    echo "  --vnet-name NAME           Virtual Network Name (default: $VNET_NAME)"
    echo "  --vnet-prefix PREFIX       VNet Address Prefix (default: $VNET_ADDRESS_PREFIX)"
    echo "  --subnet-name NAME         Subnet Name (default: $SUBNET_NAME)"
    echo "  --subnet-prefix PREFIX     Subnet Address Prefix (default: $SUBNET_ADDRESS_PREFIX)"
    echo "  --source-type TYPE         Source Type [VMware|Hyper-V|Physical] (default: $SOURCE_TYPE)"
    echo "                             Use 'Physical' for AWS, GCP, or on-prem physical servers"
    echo "  --help                     Display this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --subscription-id)
            SUBSCRIPTION_ID="$2"
            shift 2
            ;;
        --resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        --location)
            LOCATION="$2"
            shift 2
            ;;
        --project-name)
            MIGRATE_PROJECT_NAME="$2"
            shift 2
            ;;
        --vnet-name)
            VNET_NAME="$2"
            shift 2
            ;;
        --vnet-prefix)
            VNET_ADDRESS_PREFIX="$2"
            shift 2
            ;;
        --subnet-name)
            SUBNET_NAME="$2"
            shift 2
            ;;
        --subnet-prefix)
            SUBNET_ADDRESS_PREFIX="$2"
            shift 2
            ;;
        --source-type)
            SOURCE_TYPE="$2"
            shift 2
            ;;
        --help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [ -z "$SUBSCRIPTION_ID" ]; then
    echo "Error: Subscription ID is required."
    echo "Please provide it using --subscription-id option or set SUBSCRIPTION_ID in .env file."
    usage
fi

# Validate source type
if [[ "$SOURCE_TYPE" != "VMware" && "$SOURCE_TYPE" != "Hyper-V" && "$SOURCE_TYPE" != "Physical" ]]; then
    echo "Error: Invalid source type. Must be 'VMware', 'Hyper-V', or 'Physical'."
    usage
fi

echo "=== Azure Migrate Lab Setup Configuration ==="
echo "Subscription ID:      $SUBSCRIPTION_ID"
echo "Resource Group:       $RESOURCE_GROUP"
echo "Location:             $LOCATION"
echo "Migrate Project Name: $MIGRATE_PROJECT_NAME"
echo "VNet Name:            $VNET_NAME"
echo "VNet Address Prefix:  $VNET_ADDRESS_PREFIX"
echo "Subnet Name:          $SUBNET_NAME"
echo "Subnet Address Prefix: $SUBNET_ADDRESS_PREFIX"
echo "Source Type:          $SOURCE_TYPE"
echo "=============================================="

# Confirm execution
read -p "Continue with this configuration? (y/n): " confirm
if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo "Operation cancelled."
    exit 0
fi

echo "Logging in to Azure..."
az account show &> /dev/null || az login

echo "Setting subscription context..."
az account set --subscription "$SUBSCRIPTION_ID"

echo "Creating Resource Group if it doesn't exist..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

# Create Azure Migrate project using ARM template deployment
echo "Creating Azure Migrate project..."

# Create a temporary ARM template file
ARM_TEMPLATE=$(mktemp)

# Define the ARM template for Azure Migrate project
cat > $ARM_TEMPLATE << EOF
{
    "\$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {},
    "resources": [
        {
            "type": "Microsoft.Migrate/migrateProjects",
            "apiVersion": "2020-05-01",
            "name": "${MIGRATE_PROJECT_NAME}",
            "location": "${LOCATION}",
            "properties": {}
        },
        {
            "type": "Microsoft.Migrate/migrateProjects/solutions",
            "apiVersion": "2020-05-01",
            "name": "${MIGRATE_PROJECT_NAME}/Servers-Assessment-ServerAssessment",
            "dependsOn": [
                "[resourceId('Microsoft.Migrate/migrateProjects', '${MIGRATE_PROJECT_NAME}')]"
            ],
            "properties": {
                "tool": "ServerAssessment",
                "purpose": "Assessment",
                "goal": "Servers"
            }
        },
        {
            "type": "Microsoft.Migrate/migrateProjects/solutions",
            "apiVersion": "2020-05-01",
            "name": "${MIGRATE_PROJECT_NAME}/Servers-Migration-ServerMigration",
            "dependsOn": [
                "[resourceId('Microsoft.Migrate/migrateProjects', '${MIGRATE_PROJECT_NAME}')]"
            ],
            "properties": {
                "tool": "ServerMigration",
                "purpose": "Migration",
                "goal": "Servers"
            }
        }
    ]
}
EOF

# Deploy the ARM template
az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$ARM_TEMPLATE" \
    --name "${MIGRATE_PROJECT_NAME}-deployment" \
    --no-wait

echo "Azure Migrate project deployment initiated. This may take a few minutes to complete."

# Clean up the temporary template file
rm $ARM_TEMPLATE

echo "Creating Virtual Network and Subnet..."
az network vnet create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VNET_NAME" \
    --address-prefix "$VNET_ADDRESS_PREFIX" \
    --subnet-name "$SUBNET_NAME" \
    --subnet-prefix "$SUBNET_ADDRESS_PREFIX"

echo "Azure Migrate project setup completed successfully!"
echo "Resource Group:       $RESOURCE_GROUP"
echo "Migrate Project:      $MIGRATE_PROJECT_NAME"
echo "Virtual Network:      $VNET_NAME"
echo "Subnet:               $SUBNET_NAME"

# Get the link to the Azure Portal for accessing the Migrate project
echo "To access your Azure Migrate project, visit the Azure Portal at:"
echo "Portal URL: https://portal.azure.com/#blade/Microsoft_Azure_Migrate/AmhResourceMenuBlade/overview/resourceId/%2Fsubscriptions%2F$SUBSCRIPTION_ID%2FresourceGroups%2F$RESOURCE_GROUP%2Fproviders%2FMicrosoft.Migrate%2FMigrateProjects%2F$MIGRATE_PROJECT_NAME"

# Next steps
echo ""
echo "Next steps:"
echo "1. Visit the Azure Migrate project in the Azure Portal using the URL above"
echo "2. Download the Azure Migrate appliance for $SOURCE_TYPE from the Azure Portal"

if [ "$SOURCE_TYPE" == "Physical" ]; then
    echo "3. Set up the appliance on a Windows Server 2022/2019 with the following requirements:"
    echo "   - 16-GB RAM, 8 vCPUs, 80 GB disk space"
    echo "   - Static or dynamic IP with internet access"
    echo "4. For AWS EC2 instances:"
    echo "   - Ensure inbound connections on WinRM port 5985 (HTTP) for Windows servers"
    echo "   - Ensure inbound connections on port 22 (TCP) for Linux servers"
    echo "5. Configure the appliance for discovery and provide credentials to access AWS instances"
else
    echo "3. Deploy the appliance in your $SOURCE_TYPE environment"
    echo "4. Configure the appliance for discovery"
fi

echo ""
echo "For more details, see the README.md" 