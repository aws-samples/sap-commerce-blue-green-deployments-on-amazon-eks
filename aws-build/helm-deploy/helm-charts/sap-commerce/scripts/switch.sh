#!/usr/bin/env bash

# Copyright 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.

### Handling named parameters
while [ $# -gt 0 ]; do
   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
        # echo $1 $2 // Optional to see the parameter:value result
   fi
  shift
done

##############################################################################
# Sample invocations, please change the values according to your requirement.
# Please tune the parameters when it's the first deploy or sequent deploys.

# ./switch.sh \
# --HelmReleaseName <sap-commerce-blue-green-release-name> \
##############################################################################

### Move to the directory where we have the helm chart definition
cd ../


# Discover which slot (blue or green) is the production one
currentProductionSlotColor=$(helm get values --all $HelmReleaseName -o yaml | yq '.slot.production.color')
echo "The current production slot is: $currentProductionSlotColor"

### Set the switched values for the production/stage slots
if [ "$currentProductionSlotColor" == "blue" ]; then
    productionSlotColor="green"
    greenProduction=true
    blueProduction=false
else
    productionSlotColor="blue"
    greenProduction=false
    blueProduction=true
fi

### Upgrade the helm chart to perform the switch
helm upgrade $HelmReleaseName sap-commerce-blue-green \
    --set slot.production.color="$productionSlotColor" \
    --set slot.blue.production=$blueProduction \
    --set slot.green.production=$greenProduction \
    --set deploy.performSystemUpdate=false \
    --set slot.stage.createTypeSystem=false \
    --reuse-values
