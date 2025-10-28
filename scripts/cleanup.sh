# Cleanup Script for D365 Demo
# This script removes all resources created by the demo

#!/usr/bin/env bash
set -e

# Configuration
RESOURCE_GROUP="rg-d365-demo"
CONFIRMATION=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${RED}⚠️  WARNING: This will delete ALL resources in the resource group!${NC}"
echo -e "${YELLOW}Resource Group: $RESOURCE_GROUP${NC}"
echo ""
echo "This includes:"
echo "- Azure API Management"
echo "- Logic Apps"
echo "- Azure Functions"
echo "- Service Bus"
echo "- Storage Accounts (ADLS Gen2)"
echo "- Application Insights"
echo "- Key Vault"
echo "- All associated data"
echo ""

read -p "Type 'DELETE' to confirm: " CONFIRMATION

if [ "$CONFIRMATION" = "DELETE" ]; then
    echo -e "${YELLOW}Deleting resource group: $RESOURCE_GROUP${NC}"
    
    # Delete the entire resource group
    az group delete --name $RESOURCE_GROUP --yes --no-wait
    
    echo -e "${GREEN}✓ Deletion initiated successfully!${NC}"
    echo -e "${YELLOW}Note: Deletion may take several minutes to complete.${NC}"
    echo "You can check the status with: az group show --name $RESOURCE_GROUP"
else
    echo -e "${GREEN}Deletion cancelled.${NC}"
fi
