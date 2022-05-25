package azureServiceBus

import (
	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/messaging/azservicebus"
)

func azureAuth(fullyQualifiedNamespace string) (*azservicebus.Client, error) {
	credential, err := azidentity.NewDefaultAzureCredential(nil)
	if err != nil {
		return nil, err

	}

	client, err := azservicebus.NewClient(fullyQualifiedNamespace, credential, nil)
	if err != nil {
		return nil, err
	}

	return client, nil

}
