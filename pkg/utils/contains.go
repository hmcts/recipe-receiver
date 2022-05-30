package utils

func Contains(stringToMatch string, stringsSlice []string) bool {
	for _, i := range stringsSlice {
		if stringToMatch == i {
			return true
		}
	}
	return false
}
