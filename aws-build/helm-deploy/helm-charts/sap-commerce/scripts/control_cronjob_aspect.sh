#!/usr/bin/env bash

# Copyright 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.

set -e

### Handling named parameters
while [ $# -gt 0 ]; do
   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
        # echo $1 $2 // Optional to see the parameter:value result
   fi
  shift
done

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

cd ..

##############################################################################
# Sample invocations, please change the values according to your requirement
##############################################################################

##### This invocation is for the first time deploy (helm chart not yet deployed)
# ./control_cronjob_aspect.sh \
# --HelmReleaseName sap-commerce-project \
# --BlueCronjobAspectEnabled false \
# --GreenCronjobAspectEnabled true

### Upgrade helm chart
helm upgrade $HelmReleaseName sap-commerce-blue-green \
    --set slot.blue.aspect.cronjob.enabled=$BlueCronjobAspectEnabled \
    --set slot.green.aspect.cronjob.enabled=$GreenCronjobAspectEnabled \
    --set deploy.performSystemUpdate=false \
    --set slot.stage.createTypeSystem=false \
    --reuse-values \
    --timeout 7200s