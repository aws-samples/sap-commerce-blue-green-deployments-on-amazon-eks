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


productionSlotColor=$(helm get values --all $HelmReleaseName -o yaml | yq -r '.slot.production.color')

echo $productionSlotColor