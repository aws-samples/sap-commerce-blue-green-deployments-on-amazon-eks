#!/usr/bin/env bash

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

printf "Usage: ./setup-pipeline.sh \\
--GitRepositoryName <aws-code-commit-repository-name> \\
--ECRRepositoryName <aws-account>.dkr.ecr.<aws-region>.amazonaws.com/<aws-ecr-repository-name> \\
--HelmReleaseName sap-commerce-project \\
--Environment <environment> \\
--EKSClusterName <aws-eks-cluster-name> \\
--DeploymentRoleName <aws-iam-role-for-eks> \\
--S3BucketForCommerceConfigurations <amazon-s3-bucket-for-sap-configuration> \\
--S3BucketForCommerceSoftware <amazon-s3-bucket-for-sap-software> \\
--SAPCommerceReleaseZipFile CXCOMM210500P_5-70005661.ZIP \\
--MasterBranch master \\
--StageDomainName <stage-domain-name> \\
--ProductionDomainName <production-domain-name> \\
--SAPCommercePodRoleArn <aws-iam-role-for-kubernetes-service-account> \\
--Region <aws-region>"

### Create the Lambda function and required roles
aws cloudformation deploy \
    --stack-name $GitRepositoryName-cicd-pipeline-setup \
    --template-file Setup.yaml \
    --region $Region \
    --capabilities CAPABILITY_NAMED_IAM
echo "S3 bucket, IAM roles and Lambda function created."    

### Upload the CF template to provision the pipeline through Lambda
aws s3 cp TemplatePipeline.yaml s3://"$(aws sts get-caller-identity --query Account --output text)"-templates/ --acl private
echo "CloudFormation templated loaded on the S3 buacket."    

### Provision the CodeBuild projects manually with Setup flag set to true
aws cloudformation deploy \
    --stack-name $GitRepositoryName-cicd-build-actions \
    --template-file SetupPipeline.yaml \
    --parameter-overrides \
        GitRepositoryName=$GitRepositoryName \
        ECRRepositoryName=$ECRRepositoryName \
        HelmReleaseName=$HelmReleaseName \
        Environment=$Environment \
        EKSClusterName=$EKSClusterName \
        DeploymentRoleName=$DeploymentRoleName \
        S3BucketForCommerceConfigurations=$S3BucketForCommerceConfigurations \
        S3BucketForCommerceSoftware=$S3BucketForCommerceSoftware \
        SAPCommerceReleaseZipFile=$SAPCommerceReleaseZipFile \
        MasterBranch=$MasterBranch \
        StageDomainName=$StageDomainName \
        ProductionDomainName=$ProductionDomainName \
        SapCommercePodRoleArn=$SapCommercePodRoleArn \
    --region $Region \
    --capabilities CAPABILITY_NAMED_IAM

echo "CodeBuild actions created."    
