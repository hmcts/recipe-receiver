package azureServiceBus

import (
	"context"
	"errors"
	"fmt"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"time"
)

func Receiver(fullyQualifiedNamespace *string, queue *string) error {
	zerolog.TimeFieldFormat = time.RFC3339

	client, err := azureAuth(*fullyQualifiedNamespace)
	if err != nil {
		return err
	}

	// Start receiver
	receiver, err := client.NewReceiverForQueue(
		"orders",
		nil,
	)
	fmt.Println("Starting Service Bus Message Receiver...")
	fmt.Printf("Testing connectivity to %s\n", *fullyQualifiedNamespace)

	if err := peekWithRetry(receiver); err != nil {
		panic(fmt.Sprintf("Failed to connect to Service Bus. Error: %s", err))
	}

	fmt.Println("Connectivity looks good...")

	//peekContext, cancel := context.WithTimeout(context.TODO(), time.Second*10)
	//defer cancel()
	//
	//// Retry 3 times
	//for i := 0; i < 3; i++ {
	//	_, err := receiver.PeekMessages(peekContext, 1, nil)
	//	if err == nil {
	//		fmt.Println("Connectivity looks good...")
	//		break
	//	}
	//	if i == 2 {
	//		panic(fmt.Sprintf("Failed to connect to Service Bus. Error: %s", err))
	//	}
	//}

	fmt.Printf("Ready to receive messages from Service Bus queue: %s/%s\n", *fullyQualifiedNamespace, *queue)

	for {
		func() {
			ctx, cancel := context.WithTimeout(context.TODO(), 60*time.Second)

			defer func() {
				defer cancel()
			}()

			messages, err := receiver.ReceiveMessages(ctx,
				1,
				nil,
			)

			if errors.Is(err, context.DeadlineExceeded) {
				if err := peekWithRetry(receiver); err != nil {
					panic(fmt.Sprintf("Failed to connect to Service Bus. Timeout: %s", err))
				}
			} else if err != nil {
				panic(err)
			}

			for _, message := range messages {
				var body []byte = message.Body

				log.Info().
					Str("status", "message received").
					Msg(fmt.Sprintf("%s", body))

				err = receiver.CompleteMessage(context.TODO(), message, nil)
				if err != nil {
					log.Error().Msg(fmt.Sprintf("%s", err))
				}
			}
		}()
	}
}
