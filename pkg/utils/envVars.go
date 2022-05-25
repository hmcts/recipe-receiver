package utils

import "os"

func VarCheck(envVars []string) (missingVars []string) {

	for _, envVar := range envVars {
		if _, varFound := os.LookupEnv(envVar); !varFound {
			missingVars = append(missingVars, envVar)
		}
	}
	return missingVars
}
