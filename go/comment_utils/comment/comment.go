package main

import (
  "bufio"
  "fmt"
  "os"
  "strings"
)

const CMT_EMPTY, CMT_STR, CMT_LOWMEMORY = "CMT_EMPTY", "CMT_STR", "CMT_LOWMEMORY"

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

// getMinimumIndentation calculates the minimum indentation (number of leading spaces)
// among non-empty lines.
func getMinimumIndentation(lines []string) int {
  minIndentation := -1 // Initialize to an invalid value.
  for _, line := range lines {
    if strings.TrimSpace(line) != "" {
      indentation := len(line) - len(strings.TrimLeft(line, " "))
      if minIndentation == -1 || indentation < minIndentation {
        minIndentation = indentation
      }
    }
  }
  return minIndentation
}

// shouldIgnoreEmptyLines checks if empty lines should be ignored based on the
// presence of the CMT_EMPTY environment variable.
func shouldIgnoreEmptyLines() bool {
  _, exists := os.LookupEnv(CMT_EMPTY)
  return exists
}

// isLowMemoryMode checks if the program should run in low-memory mode
// based on the presence of the CMT_LOWMEMORY environment variable.
func isLowMemoryMode() bool {
  _, exists := os.LookupEnv(CMT_LOWMEMORY)
  return exists
}

func main() {
  prefix := getPrefix()

  // Print the prefix being used
  // fmt.Fprintf(os.Stderr, "Using prefix: %s\n", prefix)

  ignoreEmptyLines := shouldIgnoreEmptyLines()
  lowMemoryMode := isLowMemoryMode()

  if lowMemoryMode {
    processLinesLowMemory(prefix, ignoreEmptyLines)
  } else {
    processLinesInMemory(prefix, ignoreEmptyLines)
  }
}

// processLinesLowMemory processes lines directly from the scanner,
// without storing them in memory.  This is used when CMT_LOWMEMORY is set.
func processLinesLowMemory(prefix string, ignoreEmptyLines bool) {
  scanner := bufio.NewScanner(os.Stdin)

  for scanner.Scan() {
    line := scanner.Text()

    if strings.TrimSpace(line) == "" && ignoreEmptyLines {
      fmt.Println("")
      continue
    }

    fmt.Println(prefix + " " + line)
  }

  if err := scanner.Err(); err != nil {
    fmt.Fprintln(os.Stderr, "Error reading from stdin:", err)
    return
  }
}

// processLinesInMemory reads all lines into memory, calculates the minimum indentation,
// and then processes them.  This is the default mode.
func processLinesInMemory(prefix string, ignoreEmptyLines bool) {
  // Read all lines from standard input.
  var lines []string
  scanner := bufio.NewScanner(os.Stdin)
  for scanner.Scan() {
    lines = append(lines, scanner.Text())
  }
  if err := scanner.Err(); err != nil {
    fmt.Fprintln(os.Stderr, "Error reading from stdin:", err)
    return
  }

  // Calculate the minimum indentation.
  minIndentation := getMinimumIndentation(lines)

  // Check if all lines are empty.
  allLinesEmpty := minIndentation == -1

  // Process and output each line, unless all lines are empty.
  if !allLinesEmpty {
    for _, line := range lines {
      if strings.TrimSpace(line) == "" && ignoreEmptyLines {
        fmt.Println("")
        continue
      }

      padding := ""
      if len(line)-len(strings.TrimLeft(line, " ")) < minIndentation {
        padding = strings.Repeat(" ", minIndentation)
      } else {
        padding = line[:minIndentation]
      }
      trimmedLine := line[minIndentation:]

      fmt.Println(padding + prefix + " " + trimmedLine)
    }
  }
}
