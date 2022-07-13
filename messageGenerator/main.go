package main

import (
	"context"
	"flag"
	"fmt"
	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/messaging/azservicebus"
	sbadmin "github.com/Azure/azure-sdk-for-go/sdk/messaging/azservicebus/admin"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"math/rand"
	"os"
	"strings"
	"sync"
	"time"
)

/*
Generate messages with recipes and their ingredients and sends
them to an Azure Service Bus Queue.
*/

type Recipe struct {
	name        string
	ingredients []string
}

var (
	recipeTypes = []string{
		"cake",
		"waffle",
		"filled pastry",
		"ice cream",
		"soup",
	}
	ingredientsSlice = []string{
		"apples",
		"milk",
		"strawberries",
		"chocolate sauce",
		"flour",
		"cinnamon",
		"eggs",
		"sugar",
		"honey",
		"vanilla extract",
		"icing sugar",
		"baking soda",
		"pecans",
		"hazelnuts",
		"carrots",
		"pears",
		"beetroot",
		"pineapple",
		"bananas",
		"walnuts",
		"coffee",
		"almond essence",
	}
	recipeQuality = []string{
		"terrific",
		"good",
		"mediocre",
		"bad",
		"terrible",
	}
)

func main() {
	zerolog.TimeFieldFormat = time.RFC3339

	var (
		fullyQualifiedNamespace *string
		queueName               *string
		numberOfMessages        *int
		watch                   *bool
	)

	fullyQualifiedNamespace = flag.String("service-bus", "", "Host name of the service bus to send messages to")
	queueName = flag.String("queue", "", "Name of the queue to send messages to")
	numberOfMessages = flag.Int("messages", 2000, "Number of messages to send to the queue")
	watch = flag.Bool("watch", false, "Watch the message count on the queue you're sending messages to")

	flag.Parse()

	if *fullyQualifiedNamespace == "" {
		fmt.Println("Service Bus host name must be specified.\nUsage:")
		flag.PrintDefaults()
		os.Exit(1)
	}
	if *queueName == "" {
		fmt.Println("Service Bus queue name must be specified.\nUsage:")
		flag.PrintDefaults()
		os.Exit(1)
	}

	client, err := azureAuth(*fullyQualifiedNamespace)
	if err != nil {
		fmt.Printf("Unable to to authenticate: %s", err)
	}

	serviceBusSender, err := client.NewSender(*queueName, nil)
	if err != nil {
		fmt.Printf("Unable to to create service bus sender: %s", err)
	}

	message := azservicebus.Message{}
	contentType := "plain/text"

	var wg = &sync.WaitGroup{}

	for i := 0; i < *numberOfMessages; i++ {
		wg.Add(1)

		go func() {
			recipe := createRecipe()
			recipeName := recipe.name
			recipeIngredients := strings.Join(recipe.ingredients, ", ")
			messageString := fmt.Sprintf("Name: %s, Ingredients: %s.", recipeName, recipeIngredients)

			recipeMessage := message
			recipeMessage.Body = []byte(messageString)
			recipeMessage.ContentType = &contentType

			if err := serviceBusSender.SendMessage(context.TODO(), &recipeMessage, nil); err != nil {
				panic(err)
			} else {
				log.Info().Msgf("%s has been sent! Ingredients: %s.", recipeName, recipeIngredients)
			}
			wg.Done()
		}()
	}
	wg.Wait()

	watchQueue := *watch
	if watchQueue {
		adminClient, err := sbAdminAuth(*fullyQualifiedNamespace)
		if err != nil {
			panic(err)
		}

		for queueLength := *numberOfMessages; queueLength > 0; time.Sleep(5 * time.Second) {
			queueResponse, err := adminClient.GetQueueRuntimeProperties(context.TODO(), "recipes", nil)
			if err != nil {
				panic(err)
			}

			queueLength = int(queueResponse.TotalMessageCount)
			fmt.Printf("Length of %s/%s queue is: %d\n", *fullyQualifiedNamespace, *queueName, queueLength)
		}
	}
}

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

func sbAdminAuth(fullyQualifiedNamespace string) (*sbadmin.Client, error) {
	credential, err := azidentity.NewDefaultAzureCredential(nil)
	if err != nil {
		return nil, err
	}

	client, err := sbadmin.NewClient(fullyQualifiedNamespace, credential, nil)
	if err != nil {
		return nil, err
	}

	return client, nil

}

func createRecipe() Recipe {
	rand.Seed(time.Now().UnixNano())

	ingredientsAvailable := ingredientsSlice
	ingredientsSliceLength := len(ingredientsAvailable)

	quality := recipeQuality[rand.Intn(len(recipeQuality))]
	recipeType := recipeTypes[rand.Intn(len(recipeTypes))]
	recipeName := fmt.Sprintf("A %s %s recipe", quality, recipeType)

	recipe := Recipe{recipeName, []string{
		ingredientsAvailable[rand.Intn(ingredientsSliceLength)],
		ingredientsAvailable[rand.Intn(ingredientsSliceLength)],
		ingredientsAvailable[rand.Intn(ingredientsSliceLength)],
		ingredientsAvailable[rand.Intn(ingredientsSliceLength)],
	}}
	return recipe
}
