# Makefile for AL (Business Central) Project
# Cross-platform build system for CopilotAllTablesAndFields

# =============================================================================
# Project Configuration
# =============================================================================

# Dynamic project discovery
PROJECT_ROOT := .

# Find app.json location (root or app subdirectory)
APP_JSON_LOCATIONS := $(PROJECT_ROOT)/app.json $(PROJECT_ROOT)/app/app.json
APP_JSON := $(firstword $(wildcard $(APP_JSON_LOCATIONS)))

# Determine project structure based on app.json location
ifeq ($(APP_JSON),$(PROJECT_ROOT)/app.json)
    # app.json in root - traditional structure
    SRC_DIR := $(PROJECT_ROOT)/src
    OUTPUT_DIR := $(PROJECT_ROOT)
else ifeq ($(APP_JSON),$(PROJECT_ROOT)/app/app.json)
    # app.json in app subdirectory
    SRC_DIR := $(PROJECT_ROOT)/app/src
    OUTPUT_DIR := $(PROJECT_ROOT)/app
else
    # No app.json found - use defaults and warn
    APP_JSON := $(PROJECT_ROOT)/app.json
    SRC_DIR := $(PROJECT_ROOT)/src
    OUTPUT_DIR := $(PROJECT_ROOT)
endif

PACKAGE_CACHE := $(OUTPUT_DIR)/.alpackages

# Dynamic app metadata reading from app.json
ifeq ($(OS),Windows_NT)
    # Windows PowerShell approach
    READ_JSON_CMD := powershell -NoProfile -Command "if (Test-Path '$(APP_JSON)') { $$json = Get-Content '$(APP_JSON)' | ConvertFrom-Json; "
    APP_NAME := $(shell $(READ_JSON_CMD) Write-Output $$json.name }")
    APP_VERSION := $(shell $(READ_JSON_CMD) Write-Output $$json.version }")
    PUBLISHER := $(shell $(READ_JSON_CMD) Write-Output $$json.publisher }")
else
    # Linux/macOS with jq (fallback to defaults if jq not available)
    APP_NAME := $(shell if command -v jq >/dev/null 2>&1 && [ -f "$(APP_JSON)" ]; then jq -r '.name // "UnknownApp"' "$(APP_JSON)"; else echo "UnknownApp"; fi)
    APP_VERSION := $(shell if command -v jq >/dev/null 2>&1 && [ -f "$(APP_JSON)" ]; then jq -r '.version // "1.0.0.0"' "$(APP_JSON)"; else echo "1.0.0.0"; fi)
    PUBLISHER := $(shell if command -v jq >/dev/null 2>&1 && [ -f "$(APP_JSON)" ]; then jq -r '.publisher // "UnknownPublisher"' "$(APP_JSON)"; else echo "UnknownPublisher"; fi)
endif

# Fallback values if app.json parsing fails
APP_NAME := $(if $(APP_NAME),$(APP_NAME),CopilotAllTablesAndFields)
APP_VERSION := $(if $(APP_VERSION),$(APP_VERSION),1.0.0.0)
PUBLISHER := $(if $(PUBLISHER),$(PUBLISHER),FBakkensen)

# Output file
OUTPUT_FILE := $(PUBLISHER)_$(APP_NAME)_$(APP_VERSION).app
OUTPUT_PATH := $(OUTPUT_DIR)/$(OUTPUT_FILE)

# =============================================================================
# Platform Detection and Error Handling
# =============================================================================

# Detect operating system
ifeq ($(OS),Windows_NT)
    DETECTED_OS := Windows
    PLATFORM := windows
else
    DETECTED_OS := $(shell uname -s)
    PLATFORM := linux
    # Improved error handling for non-Windows platforms
    SHELL := /bin/bash
    .SHELLFLAGS := -eu -o pipefail -c
endif

# =============================================================================
# Include Platform-specific Configuration
# =============================================================================

ifeq ($(PLATFORM),windows)
    include Makefile.windows
else
    include Makefile.linux
endif

# =============================================================================
# Targets
# =============================================================================

.PHONY: all build clean help install check-deps show-config analyze show-analyzers validate-project

# Default target
all: build

# Help target
help:
	@echo "AL Project Build System"
	@echo "======================="
	@echo ""
	@echo "Available targets:"
	@echo "  build         - Compile the AL project with analysis"
	@echo "  clean         - Remove build artifacts"
	@echo "  check-deps    - Check for required dependencies"
	@echo "  show-config   - Display current configuration"
	@echo "  show-analyzers - Show discovered analyzers"
	@echo "  validate-project - Validate project structure"
	@echo "  analyze       - Run analysis only (without compilation)"
	@echo "  install       - Install/setup dependencies"
	@echo "  help          - Show this help message"
	@echo ""
	@echo "Platform: $(DETECTED_OS)"

# Show current configuration
show-config:
	@echo "=== Configuration ==="
	@echo "Platform: $(DETECTED_OS)"
	@echo "App JSON: $(APP_JSON)"
	@echo "App Name: $(APP_NAME)"
	@echo "App Version: $(APP_VERSION)"
	@echo "Publisher: $(PUBLISHER)"
	@echo "Output File: $(OUTPUT_FILE)"
	@echo "Project Root: $(PROJECT_ROOT)"
	@echo "Source Dir: $(SRC_DIR)"
	@echo "Output Dir: $(OUTPUT_DIR)"
	@echo "Package Cache: $(PACKAGE_CACHE)"
	$(SHOW_CONFIG_CMD)

# Check dependencies
check-deps:
	@echo "Checking dependencies..."
	$(CHECK_DEPS_CMD)

# Build target - main compilation
build: check-deps
	$(BUILD_CMD)

# Analysis only
analyze: check-deps
	@echo "Running analysis..."
	$(ANALYZE_CMD)

# Show discovered analyzers
show-analyzers:
	@echo "Checking for AL analyzers..."
	$(SHOW_ANALYZERS_CMD)

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	$(CLEAN_CMD)

# Install/setup dependencies
install:
	@echo "Setting up dependencies for $(DETECTED_OS)..."
	$(INSTALL_CMD)

# Validate project structure
validate-project:
	@echo "=== Project Structure Validation ==="
ifeq ($(OS),Windows_NT)
	@powershell -NoProfile -Command \
		"if (Test-Path '$(APP_JSON)') { \
			Write-Host '✓ Found app.json: $(APP_JSON)'; \
			Write-Host '  - App Name: $(APP_NAME)'; \
			Write-Host '  - Version: $(APP_VERSION)'; \
			Write-Host '  - Publisher: $(PUBLISHER)' \
		} else { \
			Write-Host '✗ app.json not found in expected locations:'; \
			Write-Host '  - $(PROJECT_ROOT)/app.json'; \
			Write-Host '  - $(PROJECT_ROOT)/app/app.json' \
		}; \
		if (Test-Path '$(SRC_DIR)') { \
			Write-Host '✓ Source directory: $(SRC_DIR)'; \
			Write-Host '  - AL files: ' + (Get-ChildItem -Path '$(SRC_DIR)' -Recurse -Filter '*.al' -ErrorAction SilentlyContinue).Count \
		} else { \
			Write-Host '✗ Source directory not found: $(SRC_DIR)' \
		}; \
		Write-Host 'Output directory: $(OUTPUT_DIR)'; \
		Write-Host 'Package cache: $(PACKAGE_CACHE)'"
else
	@if [ -f "$(APP_JSON)" ]; then \
		echo "✓ Found app.json: $(APP_JSON)"; \
		echo "  - App Name: $(APP_NAME)"; \
		echo "  - Version: $(APP_VERSION)"; \
		echo "  - Publisher: $(PUBLISHER)"; \
	else \
		echo "✗ app.json not found in expected locations:"; \
		echo "  - $(PROJECT_ROOT)/app.json"; \
		echo "  - $(PROJECT_ROOT)/app/app.json"; \
	fi
	@if [ -d "$(SRC_DIR)" ]; then \
		echo "✓ Source directory: $(SRC_DIR)"; \
		echo "  - AL files: $$(find $(SRC_DIR) -name '*.al' 2>/dev/null | wc -l)"; \
	else \
		echo "✗ Source directory not found: $(SRC_DIR)"; \
	fi
	@echo "Output directory: $(OUTPUT_DIR)"
	@echo "Package cache: $(PACKAGE_CACHE)"
endif

# =============================================================================
# File Dependencies
# =============================================================================

# The app file depends on app.json changes (metadata changes require rebuild)
$(OUTPUT_FILE): $(APP_JSON)
	$(MAKE) build
