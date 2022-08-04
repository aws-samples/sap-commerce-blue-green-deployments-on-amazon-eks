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

### Variables
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
SCRIPT_PATH=$(pwd -P)
DOCKER_COMMERCE_IMAGE_NAME="sap-commerce"
COMMERCE_TAG=$BranchName
REGION=$Region
MAIN_PROJECT_DIR=$(cd "../.." && pwd -P)
HYBRIS_BASE_DIRS=$(cd "../../hybris" && pwd -P)
PLATFORM_IMAGE_DIR="$MAIN_PROJECT_DIR/docker-images/sap-commerce-docker-$COMMERCE_TAG"

[[ $OSTYPE = darwin* ]] && SED_I_OPTION=".bak" || SED_I_OPTION=""

cd $HYBRIS_BASE_DIRS/bin/platform

### Setup ANT
. ./setantenv.sh

#### Fix build
touch $HYBRIS_BASE_DIRS/config/local.properties

#### Build fully the sap commerce project
ant clean customize all sassclean sasscompile 

#### Create deployment package for platform and application modules
ant production -Dproduction.include.tomcat=false -Dproduction.legacy.mode=false -Dtomcat.legacy.deployment=false -Dproduction.create.zip=false

### create the local platform image directory
rm -rf $PLATFORM_IMAGE_DIR
mkdir -p $PLATFORM_IMAGE_DIR

#### handle configuration aspects
#remove existing
SCRIPT_PATH_ENCODED=$(cd $SCRIPT_PATH/../.. && pwd -P)
SCRIPT_PATH_ENCODED=$(echo $SCRIPT_PATH_ENCODED | sed 's_/_\\/_g')
SCRIPT_PATH_ENCODED=$(echo $SCRIPT_PATH_ENCODED | sed 's_-_\\-_g')

#create the aspect map file based on the template
rm -rf $SCRIPT_PATH/aspectMap.properties
cp $SCRIPT_PATH/templates/aspectMap.properties $SCRIPT_PATH/aspectMap.properties
sed -i $SED_I_OPTION "s/PROJECT_DIR/$SCRIPT_PATH_ENCODED/g" $SCRIPT_PATH/aspectMap.properties

### Create/Build/Push Docker image
#create docker image based on the prouction build outcome
ant -Dbasedir=$HYBRIS_PLATFORM createPlatformImageStructure -DplatformImageDir=$PLATFORM_IMAGE_DIR -DplatformImageAspects=$SCRIPT_PATH/aspectMap.properties
# build image
cd $PLATFORM_IMAGE_DIR
aws ecr get-login-password --region $REGION| docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
docker build -t $DOCKER_COMMERCE_IMAGE_NAME .
docker tag $DOCKER_COMMERCE_IMAGE_NAME $ECRRepositoryName:$COMMERCE_TAG
#push image
docker push $ECRRepositoryName:$COMMERCE_TAG
echo "commerce image pushed to: $ECRRepositoryName:$COMMERCE_TAG"
