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
	mode  string
	modes = []string{"daemon", "job"}
)

func main() {
	mode = os.Getenv("MODE")

	// Set which mode to run in
	if mode == "" {
		mode = "daemon"
	} else if !utils.Contains(mode, modes) {
		mode = "daemon"
		fmt.Printf("Warning: %s is not a valid mode, falling back to daemon mode. Please set env var MODE to either %s.\n", mode, strings.Join(modes, " or "))
	}

	fmt.Printf("MODE=%s\n", mode)

	// Check correct environment variables are set
	missingEnvVars := utils.VarCheck(requiredVars)
	if len(missingEnvVars) > 0 {
		missingEnvVarsError := fmt.Sprintf("Environment Variables Missing:\n- %s", strings.Join(missingEnvVars, "\n- "))
		panic(missingEnvVarsError)
	}
	serviceBus, serviceBusQueue := os.Getenv("FULLY_QUALIFIED_NAMESPACE"), os.Getenv("QUEUE")

	// Start receiving messages
	err := azureServiceBus.Receiver(&serviceBus, &serviceBusQueue, mode)
	if err != nil {
		panic(err)
	}
}
