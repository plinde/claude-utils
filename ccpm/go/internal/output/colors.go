package output

import (
	"github.com/fatih/color"
)

var (
	// Color functions for consistent output
	Green  = color.New(color.FgGreen).SprintFunc()
	Yellow = color.New(color.FgYellow).SprintFunc()
	Blue   = color.New(color.FgBlue).SprintFunc()
	Red    = color.New(color.FgRed).SprintFunc()
	Dim    = color.New(color.Faint).SprintFunc()
	Bold   = color.New(color.Bold).SprintFunc()

	// Color print functions
	GreenPrint  = color.New(color.FgGreen).PrintFunc()
	YellowPrint = color.New(color.FgYellow).PrintFunc()
	BluePrint   = color.New(color.FgBlue).PrintFunc()
	RedPrint    = color.New(color.FgRed).PrintFunc()

	// Color println functions
	GreenPrintln  = color.New(color.FgGreen).PrintlnFunc()
	YellowPrintln = color.New(color.FgYellow).PrintlnFunc()
	BluePrintln   = color.New(color.FgBlue).PrintlnFunc()
	RedPrintln    = color.New(color.FgRed).PrintlnFunc()

	// Color printf functions
	GreenPrintf  = color.New(color.FgGreen).PrintfFunc()
	YellowPrintf = color.New(color.FgYellow).PrintfFunc()
	BluePrintf   = color.New(color.FgBlue).PrintfFunc()
	RedPrintf    = color.New(color.FgRed).PrintfFunc()
)

// DisableColors disables all color output
func DisableColors() {
	color.NoColor = true
}

// EnableColors enables color output
func EnableColors() {
	color.NoColor = false
}
