package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

const CMT_STR = "CMT_STR"

// getPrefix determines the prefix string based on command-line arguments and environment variables.
func getPrefix() string {
  prefix := "#" // Default prefix.
  if len(os.Args) > 1 && os.Args[1] != "" {
    prefix = os.Args[1] // Override with command-line argument.
  } else if envPrefix := os.Getenv(CMT_STR); envPrefix != "" {
    prefix = envPrefix // Override with environment variable.
  }
  return prefix
}

func main() {
	// Determine the prefix based on priority.
  prefix := getPrefix()

	// Print the prefix being used
	// fmt.Fprintf(os.Stderr, "Using prefix: %s\n", prefix)

	// Create a scanner to read from standard input.
	scanner := bufio.NewScanner(os.Stdin)

	// Loop through each line of input.
	for scanner.Scan() {
		line := scanner.Text()
		processedLine := processLine(line, prefix) // Pass the prefix to processLine.
		fmt.Println(processedLine)
	}

	// Check for any errors that occurred during scanning.
	if err := scanner.Err(); err != nil {
		fmt.Fprintln(os.Stderr, "Error reading standard input:", err)
	}
}

// processLine processes a single line of text.
// It removes a matching prefix string (and an optional space) from the beginning of the line.
// It preserves leading and trailing whitespace.
// If the only non-blank character is the prefix, it removes all whitespace.
// It preserves empty lines.
//
// The function handles these cases:
// 1. Empty lines: Returns the original line.
// 2. Lines starting with a specific prefix: Removes the prefix and an optional space.
// 3. Lines where the only non-blank character is the prefix: Removes all whitespace.
// 4. Lines without the prefix: Returns the original line.
func processLine(line string, prefix string) string {
	if line == "" {
		return line
	}

	trimmedLine := strings.TrimLeft(line, " ")

	if strings.HasPrefix(trimmedLine, prefix) {

		index := len(prefix)
		if index < len(trimmedLine) && trimmedLine[index:index+1] == " " {
			index++
		}

		remainingPart := trimmedLine[index:]

		// Check if the *only* non-space characters were the prefix.
		if strings.TrimSpace(line) == prefix {
			return "" // Remove all characters.
		}

		firstNonSpace := 0
		for firstNonSpace < len(line) && line[firstNonSpace] == ' ' {
			firstNonSpace++
		}

		return line[:firstNonSpace] + remainingPart
	}

	return line
}
