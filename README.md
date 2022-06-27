# sds-recipe-receiver
Demo app that reads messages from an Azure Service Bus queue and logs the messages it receives.

## Prerequisites 

### Repository secrets
There 3 secrets that are needed for workflows so they can function properly they are:
* AZURE_CREDENTIALS - the output from following [these instructions](https://github.com/marketplace/actions/azure-login#configure-deployment-credentials).
* REGISTRY_USERNAME - username for sdshmctspublic container registry.
* REGISTRY_PASSWORD - password for sdshmctspublic container registry.

### Permissions 
For this repository to be fully function we need to have the correct permissions in place for Keda, the GitHub workflows and the recipe receiver application.

#### Keda 
The triggerAuthentications CRD from Keda uses Azure Pod Identity and a Managed Identity (keda-{env}-mi) to authenticate with the Azure Service Bus. This allows Keda to watch the size of the Queue, so it can scale pods up and down when necessary.

The Managed Identity used by Keda needs the `Azure Service Bus Data Receiver` role scoped to the `toffee-servicebus-stg` service bus.

#### Application
The recipe receiver application also uses a Managed identity to authenticate with the Service Bus app needs the `Azure Service Bus Data Receiver` role scoped to the `toffee-servicebus-stg` service bus.

#### Workflow
The workflow authenticates to Azure using Service Principal credentials stored in the AZURE_CREDENTIALS repository secret. That SP was created manually and is called `sds-recipe-receiver`.

To allow the workflow to do all of this we need:
* `Owner` role on the `toffee-shared-infrastructure-stg` resource group
* `Azure Service Bus Data Owner` role on the `toffee-servicebus-stg` service bus
* `Contributor` role on the `ss-dev-01-rg` & `ss-dev-01-rg` resource groups
* `AcrPush` role on the `sdshmctspublic` repo

## Workflows

### Summary of steps
PR Open:
* Builds the Recipe Receiver app
* Publishes the container image to the `sdshmctspublic` & `hmctspublic` container registries
* Creates new queues on each Service Bus to test the PR
* Loads the newly created queues with messages
* Deploys the Keda resources to the SDS DEV & CFT Preview AKS clusters
* Watches the queues until the message count hits 0

PR Close:
* Deletes the created Keda resources from the clusters
* Removes the locks on the resource groups that the Service Buses live in
* Deletes the PR queues
* Recreates the locks

### Updating the workflows
#### Deployment strategy
To reduce the amount of code and the complexity around making sure that both the SDS and CFT deployments are as similar as possible, a matrix strategy is used. This means that unless conditions are put in (which we would like to avoid), any changes made in the workflows and the scripts that they use will have an effect both the SDS and CFT deployment. 

#### Environment variables
SDS and CFT environment variables are loaded from sds.env and cft.env respectively. These files contain the project specific environment variables that are needed for the workflows to run properly and should be the place for any further project specific variables that may be needed in the future. Common environment variables that can be used across both projects can be declared in the workflow files.

## Loading a queue with messages

The script to load messages into a queue is located in the messageGenerator directory. You can either run the binary if you're on macOS or use `go run main.go`. For the script to work you'll need to have the `Azure Service Bus Data Sender` role assigned to your Azure account.

The script takes 3 arguments, the hostname of the service bus, the name of the queue and the number of messages to load the queue with.

### Examples
Using the binary to load 500 messages into the recipes-pr10 queue (only works if the queue exists, meaning the PR has to still be open):

`./messageGenerator/recipe-sender -service-bus toffee-servicebus-stg.servicebus.windows.net -queue recipes-pr10 -messages 500`

Using `go run` to run the script to load 2000 messages into the recipes queue:

`go run messageGenerator/main.go -service-bus toffee-servicebus-stg.servicebus.windows.net -queue recipes -messages 2000`

