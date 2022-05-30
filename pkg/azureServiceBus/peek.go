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
	for i := 0; i < 3; i++ {
		_, err = receiver.PeekMessages(ctx, 1, nil)
		fmt.Println("Failed to connect to queue, retrying...")

		// Panic after third failed try
		if (err != nil) && (i == 2) {
			panic(err)
		} else if err == nil {
			break
		}
	}
	return nil
}
