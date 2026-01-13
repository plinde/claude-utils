.PHONY: all build test clean install lint

BINARY := ccpm
DIST_DIR := dist
GO_FILES := $(shell find . -name '*.go' -type f)

# Default target
all: build

# Build the binary to dist/
build: $(DIST_DIR)/$(BINARY)

$(DIST_DIR)/$(BINARY): $(GO_FILES) | $(DIST_DIR)
	go build -o $(DIST_DIR)/$(BINARY) ./cmd/ccpm

$(DIST_DIR):
	mkdir -p $(DIST_DIR)

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
	rm -rf $(DIST_DIR) coverage.out coverage.html

# Install to ~/bin
install: build
	cp $(DIST_DIR)/$(BINARY) ~/bin/$(BINARY)
	@echo "Installed to ~/bin/$(BINARY)"

# Lint with golangci-lint (if available)
lint:
	@which golangci-lint > /dev/null || (echo "golangci-lint not installed"; exit 1)
	golangci-lint run

# Format code
fmt:
	go fmt ./...

# Run the binary
run: build
	./$(DIST_DIR)/$(BINARY)

# Show help
help:
	@echo "Targets:"
	@echo "  build          - Build the binary to dist/"
	@echo "  test           - Run all tests"
	@echo "  test-coverage  - Run tests with coverage report"
	@echo "  clean          - Remove build artifacts"
	@echo "  install        - Install to ~/bin/ccpm"
	@echo "  lint           - Run golangci-lint"
	@echo "  fmt            - Format code"
