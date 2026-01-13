.PHONY: all build test clean install lint

BINARY := ccpm
BUILD_DIR := .
GO_FILES := $(shell find . -name '*.go' -type f)

# Default target
all: build

# Build the binary
build: $(BINARY)

$(BINARY): $(GO_FILES)
	go build -o $(BINARY) ./cmd/ccpm

# Run all tests
test:
	go test ./... -v

# Run tests with coverage
test-coverage:
	go test ./... -coverprofile=coverage.out
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report: coverage.html"

# Clean build artifacts
clean:
	rm -f $(BINARY) coverage.out coverage.html

# Install to ~/bin
install: build
	cp $(BINARY) ~/bin/ccpm-go
	@echo "Installed to ~/bin/ccpm-go"

# Install as main ccpm (replaces Bash version)
install-replace: build
	cp $(BINARY) ~/bin/ccpm
	@echo "Installed to ~/bin/ccpm (replaced Bash version)"

# Lint with golangci-lint (if available)
lint:
	@which golangci-lint > /dev/null || (echo "golangci-lint not installed"; exit 1)
	golangci-lint run

# Format code
fmt:
	go fmt ./...

# Run the binary
run: build
	./$(BINARY)

# Show help
help:
	@echo "Targets:"
	@echo "  build          - Build the binary"
	@echo "  test           - Run all tests"
	@echo "  test-coverage  - Run tests with coverage report"
	@echo "  clean          - Remove build artifacts"
	@echo "  install        - Install to ~/bin/ccpm-go"
	@echo "  install-replace - Install to ~/bin/ccpm (replace Bash)"
	@echo "  lint           - Run golangci-lint"
	@echo "  fmt            - Format code"
