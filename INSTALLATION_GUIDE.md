## Installation Guide

### Prerequisites

To install this artefact you need to have previously provisioned:

* Identify an AWS Region of choice: `<aws-region>`
* Identify a helm release name `<helm-release-name>`. The project name will become the helm chart name.
* Define an environment `<environment>` name to target the deployment
* Identify or create an Amazon EKS Cluster `<eks-cluster-name>` (with public API endpoint) 
* Deploy the ALB Controller to the `<eks-cluster-name>`. You can use this [helm chart](https://artifacthub.io/packages/helm/aws/aws-load-balancer-controller).
* Deploy to the `<eks-cluster-name>` any additional add-on you might need (eg: [External DNS](https://artifacthub.io/packages/helm/external-dns/external-dns))
* Identify a production domain `<production-domain>` and `<stage domain>` (or subdomain of production domain) `<stage-domain>` to access your cluster (eg: with Amazon Route53 hosted zone) and configure both URLs on the Load Balancer Ingress on Amazon EKS cluster.
* Create a certificate with SSL/TLS certificate using [AWS Certificate Manager](https://aws.amazon.com/certificate-manager/)for `<production-domain> ` and `<stage-domain>`
* IAM role `<cicd-iam-role-name>` for accessing the EKS Cluster to be used by the CI/CD pipeline build actions
* Amazon S3 buckets for:
    * SAP software storage: `<sap-software-bucket>`
    * SAP commerce platform configuration: `<sap-commerce-configuration-bucket>`
* Download SAP Commerce bundle zip file `<sap-commerce-zip-file>` as described in the [documentation](https://help.sap.com/viewer/a74589c3a81a4a95bf51d87258c0ab15/2105/en-US/9f99b61bd8f14414a60340ee5d77a51f.html) and place the zip file in `<sap-commerce-download-dir>` on your workstation. 
* Upload the `<sap-commerce-zip-file>` zip file to `<sap-software-bucket>`
* Create an AWS CodeCommit int the specific `<aws-region>`. The AWS CodeCommit repository for example could be: `<aws-codecommit-repository-name>.` Define the main or master branch `<master-branch>`
* Create an Amazon ECR Repository `<aws-ecr-repository>` in the specific `<aws-region>`
* Create a IAM role, and note the `<sap-commerce-role-arn>`, for the SAP Commerce application pods in the AWS Account with the following policy attached:

```json
{
    "Statement": [
        {
            "Action": [
                "s3:**",*
                "ecr:*",
                "cloudwatch:*"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Sid": "sapcommercepolicy"
        }
    ],
    "Version": "2012-10-17"
}
```

* Create a Kubernetes Namespace for SAP Commerce application (eg: `sap-commerce`). Here a sample yaml template:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  labels:
    kubernetes.io/metadata.name: sap-commerce
  name: sap-commerce`
```

* Create a Kubernetes Service Account (eg: `commerce-service-account`) with `<sap-commerce-role-arn>` associated. Here a sample yaml template:

```yaml
apiVersion: v1
automountServiceAccountToken: true
kind: ServiceAccount
metadata:
  annotations:
    eks.amazonaws.com/role-arn: <sap-commerce-role-arn>
  name: sap-commerce-service-account
  namespace: sap-commerce`
```

### Installation Steps

To install this artefact, please clone the repository:
`git clone git@ssh.gitlab.aws.dev:sap-commerce/sap-commerce-blue-green-deployments-on-aws-eks.git`

Add all the files from the cloned repository to the new AWS CodeCommit repository `<aws-codecommit-repository-name>` on the `<master-branch>` branch.
I am assuming your local repository (CodeCommit repository) is in directory `sap-commerce-sample-project.`
Unzip the `<sap-commerce-download-dir>/<sap-commerce-zip-file>` inside the directory `sap-commerce-sample-project` .

Perform an initial ant build to create the initial configuration based on the [development template](https://help.sap.com/viewer/b490bb4e85bc42a7aa09d513d0bcb18e/2105/en-US/8b8a17848669101495abb16de725fd00.html).
Copy and overwrite the directory `sap-commerce-sample-project/hybris/config_to_copy/customize` in `sap-commerce-sample-project/hybris/config/`.  
Copy and overwrite the file `sap-commerce-sample-project/hybris/config_to_copy/localextensions.xml` in `sap-commerce-sample-project/hybris/config/`. You can add additional extensions in the `localextensions.xml` depending on the kind of environment you want to create.

Copy the relevant JDBC drive into `sap-commerce-sample-project/hybris/config/customize/platform/lib/dbdriver`.

Add, commit and push all the files to the git repository `<aws-codecommit-repository-name>`on the`<master-branch>.`
For example you can execute these commands: `git add . && git commit -m “Initial Commit” -a && git push`

Review and adjust the configuration properties located in `aws-build/sap-commerce-configurations/environments/<environment>`
In particular adjust the database URL and the media bucket and AWS profile to be used.
Upload the updated configuration files manually to Amazon S3 bucket `<sap-commerce-configuration-bucket>` or by using the helper script:
`aws-build/sap-commerce-configurations/upload_configuration_to_s3.sh <sap-commerce-configuration-bucket>`.

Execute the AWS CloudFormation to provision the CI/CD pipeline and build actions.

```bash
aws-build/cf-codepipeline/setup-pipeline.sh \
--GitRepositoryName <aws-codecommit-repository-name> \
--ECRRepositoryName <aws-ecr-repository> \
--HelmReleaseName <helm-release-name> \
--Environment <environment> \
--EKSClusterName <eks-cluster-name> \
--DeploymentRoleName <cicd-iam-role-name> \
--S3BucketForCommerceConfigurations <sap-commerce-configuration-bucket> \
--S3BucketForCommerceSoftware <sap-software-bucket> \
--SAPCommerceReleaseZipFile <sap-commerce-zip-file> \
--MasterBranch <master-branch> \
--StageFQDN <stage-domain> \
--ProductionFQDN <production-domain> \
--SAPCommerceRoleArn <sap-commerce-role-arn> \
--Region <aws-region>
```

This command is provisioning the CI/CD pipeline components (AWS  and set the environment variables on AWS CodeBuild actions to be used in the deployment.

After this command you should have the AWS CodeBuild actions, the AWS EventBridge rule that triggers a Lambda function to create a new CodePipeline pipeline and the AWS Lambda.

You can now create a new branch in the AWS CodeCommit `<aws-codecommit-repository-name>` that follows this branch name pattern: `release-*`

The first time the application is deployed, only the production slot is used.
Next deployments will be triggered as blue/green deployments using both slots.

### Cleanup

To cleanup all the resources you can execute the following script:
`aws-build/cleanup.sh --GitRepositoryName <aws-codecommit-repository-name> --HelmReleaseName <helm-release-name>`

This command is going to delete the AWS CodePipeline resources and uninstall the helm chart of the SAP Commerce application.
Please delete all the resources you have created and that are described in the prerequisite section.

## Conclusion

A blue/green deployment strategy can be a game changer in order to speed up the deployment of new releases in e-commerce contexts, i hope this blog can help you to get some insights to modernise and improve your pipeline. 



