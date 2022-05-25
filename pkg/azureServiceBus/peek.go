package azureServiceBus

import (
	"context"
	"fmt"
	"github.com/Azure/azure-sdk-for-go/sdk/messaging/azservicebus"
)

func peekWithRetry(receiver *azservicebus.Receiver) (err error) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	// Retry 3 times
	fmt.Println("Failed to connect to queue. Retrying...")
	for i := 0; i < 2; i++ {
		_, err = receiver.PeekMessages(ctx, 1, nil)
		if (err != nil) && (i == 1) {
			panic(err)
		}
	}
	return err
}
