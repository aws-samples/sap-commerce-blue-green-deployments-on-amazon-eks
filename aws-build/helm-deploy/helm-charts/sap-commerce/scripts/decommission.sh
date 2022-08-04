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

# ./decommission.sh \
# --HelmReleaseName <sap-commerce-blue-green-release-name> \
##############################################################################

### Move to the directory where we have the helm chart definition
cd ../


# Discover which slot (blue or green) is the production one
productionSlotColor=$(helm get values --all $HelmReleaseName -o yaml | yq '.slot.production.color')
echo "The current production slot is: $productionSlotColor"

if [ "$productionSlotColor" == "blue" ]; then
    greenEnabled="false"
    blueEnabled="true"
else
    blueEnabled="false"
    greenEnabled="true"
fi

echo "blueEnabled $blueEnabled"
echo "greenEnabled $greenEnabled"


### Upgrade the helm chart with the relevant flags to disable the stage slot
helm upgrade $HelmReleaseName sap-commerce-blue-green \
    --set slot.blue.enabled=$blueEnabled \
    --set slot.green.enabled=$greenEnabled \
    --set deploy.performSystemUpdate=false \
    --set slot.stage.createTypeSystem=false \
    --reuse-values