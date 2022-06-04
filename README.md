# sds-recipe-receiver
Demo app that reads messages from an Azure Service Bus queue and logs the messages to stdout.

## Prerequisites 

### Repository secrets
There 3 secrets that are needed for workflows so they can function properly they are:
* AZURE_CREDENTIALS - the output from following [these instructions](https://github.com/marketplace/actions/azure-login#configure-deployment-credentials).
* REGISTRY_USERNAME - username for hmctspublic container registry.
* REGISTRY_PASSWORD - password for hmctspublic container registry.

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
* `Contributor` role on the `ss-dev-0-rg` & `ss-dev-01-rg` resource groups

## Workflow steps
PR Open:
* Builds the Recipe Receiver app
* Publishes the container image to the `hmctspublic` container registry
* Creates a new queue on the Toffee Staging Service Bus when a PR is opened
* Loads the newly created queue with messages
* Deploys the Keda resources to the SDS DEV AKS cluster
* Watches the queue until the message count hits 0

PR Close:
* Deletes the Keda resources from the SDS DEV AKS cluster
* Removes the lock on the toffee-shared-infrastructure-stg resource group
* Deletes the PR queue
* Recreates the lock on the toffee-shared-infrastructure-stg resource group

## Loading a queue with messages

The script to load messages into a queue is located in the messageGenerator directory. You can either run the binary if you're on macOS or use `go run main.go`. For the script to work you'll need to have the `Azure Service Bus Data Sender` role assigned to your Azure account.

The script takes 3 arguments, the hostname of the service bus, the name of the queue and the number of messages to load the queue with.

### Examples
Using the binary to load 500 messages into the recipes-pr10 queue:

`./messageGenerator/recipe-sender -service-bus toffee-servicebus-stg.servicebus.windows.net -queue recipes-pr10 -messages 500`

Using `go run` to run the script to load 2000 messages into the recipes queue:

`go run messageGenerator/main.go -service-bus toffee-servicebus-stg.servicebus.windows.net -queue recipes -messages 2000`
