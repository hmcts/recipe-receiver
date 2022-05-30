package main

import (
	"context"
	"fmt"
	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/messaging/azservicebus"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"math/rand"
	"os"
	"strconv"
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
		fullyQualifiedNamespace string
		queueName               string
		numberOfMessages        int
	)

	if len(os.Args) < 3 {
		fmt.Println("Usage: go run main.go [servicebus hostname] [queue name] [no of messages to create]")
		os.Exit(1)
	}

	fullyQualifiedNamespace = os.Args[1]
	queueName = os.Args[2]
	numberOfMessages, err := strconv.Atoi(os.Args[3])

	client, err := azureAuth(fullyQualifiedNamespace)
	if err != nil {
		fmt.Printf("Unable to to authenticate: %s", err)
	}

	serviceBusSender, err := client.NewSender(queueName, nil)
	if err != nil {
		fmt.Printf("Unable to to create service bus sender: %s", err)
	}

	message := azservicebus.Message{}
	contentType := "plain/text"

	var wg = &sync.WaitGroup{}

	for i := 0; i < numberOfMessages; i++ {
		wg.Add(1)

		go func() {
			recipe := createRecipe()
			recipeName := recipe.name
			recipeIngredients := strings.Join(recipe.ingredients, ", ")
			messageString := fmt.Sprintf("Name: %s, Ingredients: %s.", recipeName, recipeIngredients)

			message.Body = []byte(messageString)
			message.ContentType = &contentType

			if err := serviceBusSender.SendMessage(context.TODO(), &message, nil); err != nil {
				panic(err)
			} else {
				log.Info().Msgf("%s has been sent! Ingredients: %s.", recipeName, recipeIngredients)
			}
			wg.Done()
		}()
	}
	wg.Wait()
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
