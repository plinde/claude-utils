package output

import (
	"fmt"
	"os"
)

// Info prints an info message in blue
func Info(format string, args ...interface{}) {
	BluePrintf(format+"\n", args...)
}

// Success prints a success message in green
func Success(format string, args ...interface{}) {
	GreenPrintf(format+"\n", args...)
}

// Warning prints a warning message in yellow
func Warning(format string, args ...interface{}) {
	YellowPrintf(format+"\n", args...)
}

// Error prints an error message in red
func Error(format string, args ...interface{}) {
	RedPrintf(format+"\n", args...)
}

// Errorf prints an error message in red to stderr
func Errorf(format string, args ...interface{}) {
	fmt.Fprintf(os.Stderr, Red(format)+"\n", args...)
}

// Print prints a plain message
func Print(format string, args ...interface{}) {
	fmt.Printf(format, args...)
}

// Println prints a plain message with newline
func Println(args ...interface{}) {
	fmt.Println(args...)
}

// Label prints a label: value pair
func Label(label string, value interface{}) {
	fmt.Printf("%s %v\n", Blue(label+":"), value)
}

// StatusLabel prints a status label with appropriate color
func StatusLabel(label string, status string, isGood bool) {
	statusColor := Red
	if isGood {
		statusColor = Green
	}
	fmt.Printf("%s %s\n", Blue(label+":"), statusColor(status))
}

// Verbose prints a message only if verbose mode is enabled
func Verbose(enabled bool, format string, args ...interface{}) {
	if enabled {
		fmt.Printf("%s %s\n", Dim("[verbose]"), fmt.Sprintf(format, args...))
	}
}

// DryRun prints a dry-run message
func DryRun(format string, args ...interface{}) {
	fmt.Printf("%s %s\n", Yellow("[dry-run]"), fmt.Sprintf(format, args...))
}
