#!/usr/bin/env bash

# Copyright 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.

set -e
set -o posix

### Handling named parameters
while [ $# -gt 0 ]; do
   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
        
        #Optional to see the parameter:value result
        #echo $1 $2
   fi
  shift
done

##############################################################################
# Sample invocations, please change the values according to your requirement.
# Please tune the parameters when it's the first deploy or sequent deploys.

# ./deploy.sh \
# --ProductionRelease v1 \
# --ProductionTypeSystem DEFAULT \ #the first time you deploy this is not DEFAULT, then put the release name
# --StageRelease v2 \ #the first time you deploy this is not relevant
# --ECRRepositoryName <aws-account>.dkr.ecr.<aws-region>.amazonaws.com/<repository-name> \
# --HelmReleaseName <sap-commerce-blue-green-release-name> \
# --Environment <environment> \
# --S3BucketForCommerceConfigurations <amazon-s3-bucket-for-sap-configuration> \
# --StageTypeSystemExists true \ #the first time you deploy this is not relevant
# --PerformSystemUpdate true \ #the first time you deploy this is not relevant
# --StageDomain <stage-domain-name> \
# --ProductionDomain <production-domain-name> \
# --SapCommercePodRoleArn <aws-iam-role-for-kubernetes-service-account> \
# --Region <aws-region>
##############################################################################


### handle default parameters
CreateKubernetesNamespace="${CreateKubernetesNamespace:-false}"
CreateKubernetesServiceAccount="${CreateKubernetesServiceAccount:-false}"


### Move to the directory where we have the helm chart definition
cd ../

### Get the SSL certificate ARN
httpsCertificateArn=$(aws acm list-certificates --region $Region --query "CertificateSummaryList[?DomainName=='$ProductionDomain'].CertificateArn" --output text)

### checks if the helm chart has been already deployed once
deplomentsFound=$(helm list -n default --filter "$HelmReleaseName" -o yaml | yq 'any')
echo "Deployment found: $deplomentsFound"
#### This block executes when the application is deployed the first time because has not been deployed yet
if ! $deplomentsFound ; then

    echo "Deploying the chart for the first time..."
    helm install $HelmReleaseName sap-commerce-blue-green \
        --set kubernetes.createNamespace=$CreateKubernetesNamespace \
        --set kubernetes.sap.createServiceAccount=$CreateKubernetesServiceAccount \
        --set kubernetes.sap.roleArn=$SapCommercePodRoleArn \
        --set deploy.environment=$Environment \
        --set image.repository=$ECRRepositoryName \
        --set slot.blue.enabled=true \
        --set slot.blue.production=true \
        --set slot.blue.release=$ProductionRelease \
        --set slot.blue.typeSystem=$ProductionTypeSystem \
        --set slot.blue.aspect.cronjob.enabled=true \
        --set slot.green.enabled=false \
        --set slot.green.production=false \
        --set slot.production.color=blue \
        --set slot.production.domainName=$ProductionDomain \
        --set slot.production.typeSystem=$ProductionTypeSystem \
        --set slot.production.httpsCertificateArn=$httpsCertificateArn \
        --set slot.stage.httpsCertificateArn=$httpsCertificateArn \
        --set slot.stage.domainName=$StageDomain \
        --set deploy.s3BucketForConfig=$S3BucketForCommerceConfigurations \
        --set deploy.performSystemUpdate=false \
        --set slot.stage.createTypeSystem=false \
        --set deployment.fistTime=true \
        --timeout 7200s

    echo "Deployment completed"
    exit 0
fi

echo "Deploying the chart again..."

### Discover which slot (blue or green) is the production one
productionSlotColor=$(helm get values --all $HelmReleaseName -o yaml | yq -r '.slot.production.color')

### The deployment mode defines how the helm chart is deployed.
### Two modes are supported: blue-green or single-slot
blueEnabled=true
greenEnabled=true
if [[ $DeployMode == "single-slot" ]]; then
    echo "Deploy Mode is: $DeployMode"
    if [ "$productionSlotColor" == "blue" ]; then
        blueEnabled=false
    else
        greenEnabled=false
    fi
fi

### Setting the blue/green and production/stage flags
echo "The current production relase $ProductionRelease is deployed in slot: $productionSlotColor"
echo "The stage release will be: $StageRelease will be deployed in the other slot"
echo $productionSlotColor
if [[ $productionSlotColor == "blue" ]]; then
    echo "blue is production"
    newStageSlot="green"
    greenProduction=false
    greenTag=$StageRelease
    greenTypeSystem=$StageRelease
    blueProduction=true
    blueTag=$ProductionRelease
    blueTypeSystem=$ProductionTypeSystem
else
    echo "green is production"
    newStageSlot="blue"
    greenProduction=true
    greenTag=$ProductionRelease
    greenTypeSystem=$ProductionTypeSystem
    blueProduction=false
    blueTag=$StageRelease
    blueTypeSystem=$StageRelease
fi

echo "The current productive typesystem is $ProductionTypeSystem"
echo "The type system for stage is: $StageRelease"

### Decides if it's required to create the stage (new) type system
createStageTypeSystem=true
if [ $StageTypeSystemExists == true ] 
then
    echo "The type system for stage release: $StageRelease already exist"
    createStageTypeSystem=false    
fi

#### This block executes when the application is already been deployed. 

### Upgrade helm chart
echo "helm upgrade --debug $HelmReleaseName sap-commerce-blue-green \\
    --set deploy.environment=$Environment \\
    --set slot.production.color=$productionSlotColor \\
    --set slot.production.typeSystem=$ProductionTypeSystem \\
    --set slot.blue.enabled=$blueEnabled \\
    --set slot.blue.production=$blueProduction \\
    --set slot.blue.release=$blueTag \\
    --set slot.blue.typeSystem=$blueTypeSystem \\
    --set slot.blue.aspect.cronjob.enabled=$blueAspectCronjobEnabled \\
    --set slot.green.enabled=$greenEnabled \\
    --set slot.green.production=$greenProduction \\
    --set slot.green.release=$greenTag \\
    --set slot.green.typeSystem=$greenTypeSystem \\
    --set slot.green.aspect.cronjob.enabled=$greenAspectCronjobEnabled \\
    --set deploy.performSystemUpdate=$PerformSystemUpdate \\
    --set slot.stage.createTypeSystem=$createStageTypeSystem \\
    --set deployment.fistTime=false \\
    --reuse-values \\
    --timeout 7200s --dry-run"

helm upgrade $HelmReleaseName sap-commerce-blue-green \
    --set deploy.environment=$Environment \
    --set slot.production.color=$productionSlotColor \
    --set slot.production.typeSystem=$ProductionTypeSystem \
    --set slot.blue.enabled=$blueEnabled \
    --set slot.blue.production=$blueProduction \
    --set slot.blue.release=$blueTag \
    --set slot.blue.typeSystem=$blueTypeSystem \
    --set slot.blue.aspect.cronjob.enabled=$blueAspectCronjobEnabled \
    --set slot.green.enabled=$greenEnabled \
    --set slot.green.production=$greenProduction \
    --set slot.green.release=$greenTag \
    --set slot.green.typeSystem=$greenTypeSystem \
    --set slot.green.aspect.cronjob.enabled=$greenAspectCronjobEnabled \
    --set deploy.performSystemUpdate=$PerformSystemUpdate \
    --set slot.stage.createTypeSystem=$createStageTypeSystem \
    --set deployment.fistTime=false \
    --reuse-values \
    --timeout 7200s

echo "Deployment completed"


