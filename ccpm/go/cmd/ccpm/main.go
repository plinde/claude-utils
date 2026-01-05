package main

import (
	"os"

	"github.com/plinde/claude-utils/ccpm/internal/cli"
)

func main() {
	if err := cli.Execute(); err != nil {
		os.Exit(1)
	}
}
