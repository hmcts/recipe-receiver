package main

import (
	"fmt"
	"os"
	"service-bus-reciever/pkg/azureServiceBus"
	"service-bus-reciever/pkg/utils"
	"strings"
)

var (
	requiredVars = []string{
		"FULLY_QUALIFIED_NAMESPACE",
		"QUEUE",
	}
)

func main() {
	// Check correct environment variables are set
	missingEnvVars := utils.VarCheck(requiredVars)
	if len(missingEnvVars) > 0 {
		missingEnvVarsError := fmt.Sprintf("Environment Variables Missing:\n- %s", strings.Join(missingEnvVars, "\n- "))
		panic(missingEnvVarsError)
	}
	serviceBus, serviceBusQueue := os.Getenv("FULLY_QUALIFIED_NAMESPACE"), os.Getenv("QUEUE")

	// Start receiving messages
	err := azureServiceBus.Receiver(&serviceBus, &serviceBusQueue)
	if err != nil {
		panic(err)
	}
}
