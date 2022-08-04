# Helm Chart Blue/Green  Parameters

|Key	|Type	|Default	|Description	|
|---	|---	|---	|---	|
|helm.release	|string	|sap-commerce	|Defines the name of the helm chart release	|
|helm.namespace	|string	|default	|Defines the namespace of the helm chart namespace	|
|slot.green.enabled	|string	|false	|Defines if the greeen slot is enabled	|
|slot.green.typeSystem	|string	| 	|Defines the name of the SAP Commerce type system of the pods in the green slot	|
|slot.green.release	|string	| 	|Defines the application release (docker image tag) of the pods in the green slot	|
|slot.green.aspect.cronjob.enabled	|boolean	|true |Defines if the resources for the cronjob aspect in the green slot need to be created	|
|slot.blue.enabled	|string	|false	|Defines if the blue slot is enabled	|
|slot.blue.typeSystem	|string	| 	|Defines the name of the SAP Commerce type system of the pods in the blue slot	|
|slot.blue.release	|string	| 	|Defines the application release (docker image tag) of the pods in the blue slot	|
|slot.blue.aspect.cronjob.enabled	|boolean	|true |Defines if the resources for the cronjob aspect in the blue slot need to be created	|
|slot.production.color	|string	| 	|Define which slot is currently holding the production release of the application.	|
|slot.production.domainName	|string	| 	|Defines the domain name for the sap commerce resources in the production slot	|
|slot.production.httpsCertificateArn	|string	| 	|Defines the https certificate arn for the production ingresses	|
|slot.production.typeSystem	|string	| 	|Defines the name of the SAP Commerce type system of the pods in the production slot	|
|slot.stage.color	|string	| 	|Define which slot is currently holding the stage release of the application.	|
|slot.stage.domainName	|string	| 	|Defines the domain name for the sap commerce resources in the stage slot	|
|slot.stage.httpsCertificateArn	|string	| 	|Defines the https certificate arn for the stage ingresses	|
|slot.stage.typeSystem	|string	| 	|Defines the name of the SAP Commerce type system of the pods in the stage slot	|
|image.repository	|string	| 	|Container image repository for the sap commerce application 	|
|image.pullPolicy	|string	|IfNotPresent	|PullPolicy for the sap commerce image, defaults to the empty Pod behavior	|
|kubernetes.createNamespace	|boolean	|false	|Defines if the namespace needs to be created.	|
|kubernetes.namespace	|string	|sap-commerce	|The namespace for all the kubernetes resources created by this helm chart	|
|kubernetes.createServiceAccount	|boolean	|false	|Defines if the service account needs to be created.	|
|kubernetes.sap.serviceAccount	|string	|commerce-service-account	|The service account for all the sap commerce kubernetes pods created by this helm chart	|
|kubernetes.sap.serviceAccountName	|string	|commerce-service-account	|The service account name for all the sap commerce kubernetes pods created by this helm chart	|
|kubernetes.sapnodeLabelSelector	|string	|sap-commerce	|The node selector for the sap commerce deployments	|
|deploy.environment	|string	| 	|The name of the environment you're going to deploy this helm chart	|
|deploy.s3BucketForConfig	|string	| 	|The Amazon S3 bucket in which the sap commerce configuration files for the sap commerce application	|
|slot.stage.createTypeSystem	|string	| 	|Defines if the type system of the new staged release that is going to be deployed	|
|deploy.performSystemUpdate	|string	| 	|Defines if the  system update needs to be executed for the new release that is going to be deployed	|

