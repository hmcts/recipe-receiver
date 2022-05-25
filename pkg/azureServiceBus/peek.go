package azureServiceBus

import (
	"context"
	"github.com/Azure/azure-sdk-for-go/sdk/messaging/azservicebus"
	"time"
)

func peekWithRetry(receiver *azservicebus.Receiver) (err error) {
	ctx, cancel := context.WithTimeout(context.TODO(), time.Second*10)
	defer cancel()

	// Retry 3 times
	for i := 0; (i < 3) || (err != nil); i++ {
		_, err = receiver.PeekMessages(ctx, 1, nil)
	}
	return err
}
