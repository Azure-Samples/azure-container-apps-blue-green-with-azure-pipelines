# Blue/Green Deployments in Azure Container Apps using Azure pipelines

Blue Green is a deployment technique that reduces downtime and risk by running two identical production environments called Blue and Green.
This concept was introduced by [Martin Fowler](https://martinfowler.com/bliki/BlueGreenDeployment.html) and is now supported by Azure Container Apps.

This example shows how to deploy a Blue/Green deployment using Azure Container Apps and Azure pipelines.

For more information on Blue/Green deployments, see [Blue/Green deployments with Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/blue-green-deployment?pivots=azure-cli).


## Getting Started

### Prerequisites

To run this sample in Azure Devops, you need:

- An Azure subscription. If you don't have an Azure subscription, create a [free account](https://azure.microsoft.com/free/?WT.mc_id=A261C142F) before you begin.
- An Azure DevOps organization. If you don't have an Azure DevOps organization, you can create one for free. For details, see [Create an organization or project collection](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/create-organization?view=azure-devops&tabs=preview-page). If you already have an organization, you can use it instead.
- An Azure Container Registry. If you don't have an Azure Container Registry, create one for free. For details, see [Create an Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-portal?WT.mc_id=A261C142F). If you already have a registry, you can use it instead. For this example,we are using Docker Hub as the container registry.

### Deploying the sample

- Fork the sample repository and clone into your local machine.
- Create a new Azure DevOps project and import the sample repository.
- Configure the Azure Container Registry as a service connection in Azure DevOps. For details, see [Create a service connection](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure?view=azure-devops&tabs=yaml#create-a-service-connection).
- Ensure you add the variables listed in the Azure Pipelines YAML file to the pipeline variables.

  This includes the following variables:
  - `API_NAME` - The name of the Application to deploy.
  - `ENVIRONMENT` - The name of the container apps environment to deploy to.
  - `REGISTRY_USERNAME` - The username of the container registry.
  - `REGISTRY_PASSWORD` - The password of the container registry.
  - `RESOURCE_GROUP` - The name of the resource group to deploy the application to.
  - `NOTIFICATIONEMAIL` - The email address to send notifications to.
  - `SUBSCRIPTIONID` - The subscription ID of the Azure subscription.
  - `LOCATION` - The location of the Azure resources.
  - `DOCKER_REPOSITORY` - The name of the docker repository to push the image to.
- Since the repository is already configured with a pipeline, you can run the pipeline to deploy the application.
- Test the application

### The flow of the pipeline

![Pipeline ](image.png)

The pipeline is configured to run on every commit to the main branch. The pipeline consists of the following stages:

 1. **Build** - Builds & tests the application and pushes the image to the container registry.
 2. **Deploy**
      - Deploys the application to the environment that is not in use, this can be either the Blue or Green environment. The environment is determined by checking the `productionLabel` tag on the environment. If the tag is set to `blue`, the application is deployed to the Green environment and vice versa.
      - The current blue and green commit IDs are stored as variables in the pipeline. They are obtained by getting the tags as mentioned above.
      - The variables are then set to be used in the pipeline.
      - Next step is to obtain the latest commit ID of the application.
      - If the production label is set to empty then the `productionLabel` tag is set to `blue` and the green commit ID is set to the latest commit ID.
      - If the production label is set to `blue` then the blue commit ID is set to the blue commit ID that is currently deployed. If the production label is set to `green` then the green commit ID is set to the green commit ID that is currently deployed. Otherwise the blue commit ID and the green commit ID are set to the latest commit ID
      - Once the variables are set correctly the application is then deployed to the environment that is not in use, this is a Bicep template that deploys the application to the environment.
 3. **waitForValidation** - This stage use Azure Devops Task `ManualValidation@0` to wait for the user to validate the deployment. The user can check that the application is deployed correctly and then approve the deployment to resume the pipeline
 4. **Deploy_To_Production** - This stage swaps the production label of the environment that is currently in use and sets the traffic to 100% to the environment that is not in use.

#### Roll Back Container Apps

This [rollback pipeline](./rollback.yml) rolls back the container app to the previous version. If you'd like to go back to the previous version. This can be triggered manually at any time.
 1. **Roll_Back** - This stage swaps the production label of the environment that is currently in use and sets the traffic to 100% to the environment was previously in use. 

NB: For the deployment the pipeline uses the AzureResourceManagerTemplateDeployment@3 task to deploy the application. This task is used to deploy Bicep templates. Another option  is to use the Azure CLI task to deploy Bicep templates.

For a more detailed explanation of the scripts please refer to [Blue/Green deployments with Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/blue-green-deployment?pivots=azure-cli).

## Resources

### This sample was tested with the following  Samples

This is the companion repository for the [Azure Container Apps code-to-cloud quickstart](https://docs.microsoft.com/en-us/azure/container-apps/quickstart-code-to-cloud?tabs=bash%2Ccsharp&pivots=acr-remote) Album Viewer UI.

The Album API sample is available in other languages:

| [C#](https://github.com/azure-samples/containerapps-albumapi-csharp) | [Go](https://github.com/azure-samples/containerapps-albumapi-go) | [Python](https://github.com/azure-samples/containerapps-albumapi-python) | [JavaScript](https://github.com/azure-samples/containerapps-albumapi-javascript) |
| -------------------------------------------------------------------- | ---------------------------------------------------------------- | ------------------------------------------------------------------------ | -------------------------------------------------------------------------------- |

curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net&client_id=7b43ab68-0fbb-4a0b-9f51-2a39380f7215' -H Metadata:true | jq -r '.access_token'
