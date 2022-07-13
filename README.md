# sds-recipe-receiver
Demo app that reads messages from an Azure Service Bus queue and logs the messages it receives.

## Prerequisites 

### Repository secrets
There 3 secrets that are needed for workflows so they can function properly they are:
* AZURE_CREDENTIALS - the output from following [these instructions](https://github.com/marketplace/actions/azure-login#configure-deployment-credentials).

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

The script to load messages into a queue is located in the messageGenerator directory, you'll need go installed to run it. If go isn't already installed on your machine you can follow the [installation instructions](https://go.dev/doc/install) to get the latest version.

The message generator script takes 4 arguments:
- service-bus: hostname of the service bus (required)
- queue: the name of the queue (required)
- messages: the number of messages to load the queue with (default: 2000)
- watch: whether to watch the message count on the queue (default: false)

### Examples

#### Working with a PR queue
To load messages into a PR queue you can run a command very similar to below. For this to work the queue needs to exist, meaning the PR has to still be open. 

<details>
  <summary>SDS Example</summary>

Load 500 messages into a queue called recipes-pr10 and watch the queue:

`./messageGenerator/recipe-sender -service-bus toffee-servicebus-stg.servicebus.windows.net -queue recipes-pr10 -messages 500 -watch`

</details>

<details>
  <summary>CFT Example</summary>
Load 1000 messages into a queue called recipes-pr25 and watch the queue:

`./messageGenerator/recipe-sender -service-bus plum-servicebus-aat.servicebus.windows.net -queue recipes-pr25 -messages 1000 -watch`

</details>

#### Working with the static recipes queues
Each of the namespaces created have a permanent recipes queue which doesn't depend on a PR being open. You can send messages to this queue to test if keda and the demo app are working as expected.

<details>
  <summary>SDS Example</summary>

Load 2000 messages into the ithc recipes queue and watch the message count on the queue:

`go run messageGenerator/main.go -service-bus toffee-servicebus-ithc.servicebus.windows.net -queue recipes -messages 2000 -watch` 

</details>

<details>
  <summary>CFT Example</summary>
Load 2000 messages into the demo recipes queue and watch the queue:

`go run messageGenerator/main.go -service-bus plum-servicebus-demo.servicebus.windows.net -queue recipes -messages 2000 -watch`

</details>