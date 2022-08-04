#!/usr/bin/env bash

# Copyright 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.

### Thsi script is useful to uninstall completely the helm chat.
### This could be useful for debugging purposes

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

# ./undeploy.sh \
# --HelmReleaseName <sap-commerce-blue-green-release-name> \
##############################################################################

helm uninstall $HelmReleaseName -n default
