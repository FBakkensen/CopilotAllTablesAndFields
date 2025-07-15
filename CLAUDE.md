# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CopilotAllTablesAndFields is a Business Central extension that provides a natural language interface for querying Business Central data using Azure OpenAI. It enables users to explore tables, fields, and data through conversational queries powered by Copilot, following Microsoft's recommended patterns for AL development and Copilot integration.

## Development Commands

### Build and Compilation
```bash
# Compile with full code analysis (CodeCop, UICop, AppSourceCop)
pwsh.exe -File ".\scripts\build.ps1"
```

### AL Compiler Location
The scripts automatically locate the AL compiler (`alc.exe`) from your VS Code AL extension installation. Ensure you have the AL Language extension installed in VS Code.

## Workflow
**CRITICAL** Always ensure the build script runs with no errors or warnings before a task can be considered completed.

## Architecture Overview

### Directory Structure
```
CopilotAllTablesAndFields/
├── src/
│   ├── Copilot/                  # Core AI integration components
│   ├── Functions/                # AOAI function implementations
│   ├── Setup/                    # Configuration and credential management
│   ├── Helpers/                  # Utility codeunits
│   ├── Install/                  # Installation logic
│   ├── EnumExtensions/           # BC Copilot capability extension
│   └── PageExtensions/           # Role center integration
├── scripts/                      # Build automation
├── Translations/                 # Localization files
└── app.json                      # Application manifest
```

### Implemented Component Structure
The extension implements a layered architecture:

1. **Interface Layer**: `DataExplorerPrompt.Page` - PromptDialog with WebPageViewer for HTML responses
2. **Capability Layer**: `DataExplorerCapability.Codeunit` - Orchestrates AI interactions and function registration
3. **Function Layer**: Direct AOAI function implementations (no interface abstraction)
4. **Helper Layer**: Permission validation, filter building, error handling utilities
5. **Data Layer**: RecordRef for dynamic table access, GenerationBuffer for response storage

### Key Technical Components

#### Core Codeunits

**DataExplorerCapability (51310)**
- Central orchestrator for all AI interactions
- Registers the three AOAI functions
- Manages Azure OpenAI authentication (custom deployments supported)
- Formats responses as HTML (hardcoded in system prompt)
- Implements comprehensive telemetry logging (Event IDs: DEX-0001, DEX-0002, DEX-0003)

**Three Core Functions:**
1. **GetTablesFunction (51320)** - Lists accessible tables with metadata
   - Filters out system tables (ID >= 2000000000) and obsolete tables
   - Returns: ID, name, caption, type, field count, record count
2. **GetFieldsFunction (51321)** - Shows field details for specified table
   - Includes field types, options, relations, and primary key information
   - Handles option/enum fields with display values
3. **GetDataFunction (51322)** - Retrieves records with advanced querying
   - Supports filtering, sorting, and pagination (default 20, max 100 records)
   - Accepts display text for option/enum fields
   - Implements proper date/datetime formatting

#### Security & Configuration

**Secure Credential Management:**
- `DataExplorerSecretMgt.Codeunit` - Handles secure storage using IsolatedStorage
- `DataExplorerSetup.Table` - Stores GUID references to secrets (never the secrets themselves)
- `DataExplorerSecretInput.Page` - Password-style input for API keys
- Uses `SecretText` type throughout for sensitive data

**Permission Handling:**
- `TablePermissionHelper.Codeunit` - Validates user permissions before any data access
- Respects Business Central's built-in permission system
- Implements row-level security checks

#### Helper Components

- **FilterBuilder.Codeunit** - Dynamic filter construction (exists but not integrated with main functions)
- **DataExplorerErrorHandler.Codeunit** - User-friendly error messages with drill-down actions
- **DataExplorerInstall.Codeunit** - Setup during extension installation

### Azure OpenAI Integration

- Uses System.AI namespace from System Application
- Supports custom Azure OpenAI deployments
- Includes connection testing functionality
- Response format: HTML (configured in system prompt)
- Model: gpt-4o with temperature 0.7

### Performance Considerations

- SetLoadFields optimization available but commented out in some implementations
- Pagination implemented for all data queries
- Metadata caching opportunities identified but not implemented
- Record count capped at 100 for performance

## Business Central Requirements

- **Platform**: BC 2025 Wave 1 (v26.0) or later
- **Application**: v26.0.0.0 (as configured in app.json)
- **Runtime**: v15.0
- **ID Range**: 51300-51399

## AL Development Standards

Follow Microsoft AL coding guidelines:
- **Objects**: PascalCase naming (e.g., `DataExplorerCapability`)
- **Variables**: camelCase (e.g., `tableMetadata`)
- **Procedures**: PascalCase with clear verb-noun structure
- **Fields**: No spaces, PascalCase (e.g., `DeploymentName`)

## Testing Infrastructure

Comprehensive TestGuide.md included with:
- Functional test scenarios for all three functions
- Security and permission testing
- Performance testing guidelines
- UX/UI testing procedures
- No automated test codeunits currently implemented

## Current Project Status

The implementation is **complete** with all planned features operational:
- ✅ All three core functions implemented and working
- ✅ Azure OpenAI integration with custom deployment support
- ✅ Secure credential management system
- ✅ Permission-based security model
- ✅ Pagination and filtering capabilities
- ✅ Comprehensive error handling
- ✅ Telemetry logging
- ✅ Setup UI and configuration management
- ✅ Role center integration

### Notable Implementation Decisions

1. **No Interface Abstraction**: Functions directly implement AOAI Function pattern rather than using a separate interface
2. **HTML Response Format**: Hardcoded in system prompt rather than configurable
3. **ID Range Change**: Using 51300-51399 instead of originally planned 50100-50149
4. **FilterBuilder**: Helper exists but isn't integrated with main data retrieval functions
5. **SetLoadFields**: Optimization code present but commented out in some places

### Areas for Future Enhancement

- Implement interface abstraction for functions if extensibility needed
- Make response format configurable (HTML/Markdown/Plain text)
- Integrate FilterBuilder for more advanced query capabilities
- Add automated test codeunits
- Implement metadata caching for performance
- Add support for more complex data relationships