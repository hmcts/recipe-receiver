package azureServiceBus

import (
	"context"
	"errors"
	"fmt"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"os"
	"time"
)

func Receiver(fullyQualifiedNamespace *string, queue *string, mode string) error {
	zerolog.TimeFieldFormat = time.RFC3339

	client, err := azureAuth(*fullyQualifiedNamespace)
	if err != nil {
		return err
	}

	// Start receiver
	receiver, err := client.NewReceiverForQueue(
		*queue,
		nil,
	)
	fmt.Println("Starting Service Bus Message Receiver...")
	fmt.Printf("Testing connectivity to %s/$s\n", *fullyQualifiedNamespace, *queue)

	if err := peekWithRetry(receiver); err != nil {
		panic(fmt.Sprintf("Failed to connect to Service Bus. Error: %s", err))
	}

	fmt.Println("Connectivity looks good...")

	fmt.Printf("Ready to receive messages from Service Bus queue: %s/%s\n", *fullyQualifiedNamespace, *queue)

	for {
		func() {
			ctx, cancel := context.WithTimeout(context.TODO(), 30*time.Second)

			defer func() {
				defer cancel()
			}()

			messages, err := receiver.ReceiveMessages(ctx,
				1,
				nil,
			)

			if (errors.Is(err, context.DeadlineExceeded)) && (mode == "job") {
				fmt.Println("No more messages to read. Exiting.")
				os.Exit(0)
			} else if errors.Is(err, context.DeadlineExceeded) && (mode == "daemon") {
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
