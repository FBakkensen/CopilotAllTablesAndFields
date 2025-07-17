
# Copilot Data Explorer - AI Agent Instructions

## Build & Deployment

### Build Workflow & Task Completion
- The primary build workflow is managed via `make build`, which invokes the AL compiler and restores symbols as needed (see `scripts/`).
- All code changes and tasks must be validated by running `make build` at the project root.
- **A task is not considered complete until `make build` runs without any errors or warnings.**
- Use `make clean` to remove build artifacts if needed.

#### Example:
```powershell
make build          # Cross-platform build using AL compiler
make clean          # Remove build artifacts
```

## Project Overview
This is a Microsoft Dynamics 365 Business Central AL extension that provides a natural language interface for exploring Business Central data using Azure OpenAI. The extension implements a Copilot capability that allows users to query tables, fields, and data through conversational AI.

## Architecture & Key Components

### Core System Pattern
- **Function-Based AI Tools**: Uses AL's `AOAI Function` interface to expose three main functions: `get_tables`, `get_fields`, and `get_data`
- **Capability Registration**: Registered as `"Data Explorer Preview"` in the Copilot Capability enum (ID: 51301)
- **Security-First Design**: All data access goes through Business Central's permission system - never bypass security

### Directory Structure
```
src/
├── Copilot/           # Main AI capability logic
├── Functions/         # AOAI Function implementations (get_tables, get_fields, get_data)
├── Helpers/          # Security, filtering, and error handling utilities
├── Setup/            # Configuration and secret management
├── Install/          # Capability registration on installation
├── EnumExtensions/   # Copilot capability enum extension
└── PageExtensions/   # UI integration (Business Manager Role Center)
```

### Critical Files
- `DataExplorerCapability.Codeunit.al`: Main orchestrator with system message and function registration
- `Get*Function.Codeunit.al`: Three core functions implementing `AOAI Function` interface
- `TablePermissionHelper.Codeunit.al`: Security layer for table access validation
- `DataExplorerSetup.Table.al`: Configuration storage using Isolated Storage for secrets

## Development Conventions

### AL-Specific Patterns
- **Object ID Range**: 51300-51399 (defined in app.json)
- **Access Modifiers**: Use `Access = Internal;` for implementation codeunits
- **SecretText Handling**: API keys stored as `SecretText` type, never as plain text
- **Error Handling**: Use `ThrowError()` pattern with localized error messages
- **Try Functions**: Use `[TryFunction]` for permission checks and external calls

### Function Implementation Pattern
All AI functions follow this structure:
```al
codeunit XXXXX "Function Name" implements "AOAI Function"
{
    procedure GetName(): Text // Return function name
    procedure GetPrompt(): JsonObject // Define function schema
    procedure Execute(Arguments: JsonObject): Variant // Core logic
}
```

### Security & Performance Conventions
- **Permission Checks**: Always validate table access via `TablePermissionHelper`
- **Result Limits**: Display first 50 tables/fields, first 100 data records
- **Smart Filtering**: Provide filtering suggestions when result sets are large
- **System Table Exclusion**: Skip tables with ID >= 2000000000 (system tables)



### Configuration Requirements
1. **SaaS Environment**: Uses managed Azure OpenAI (no setup required)
2. **Custom Deployment**: Requires Azure OpenAI endpoint, model name, and API key
3. **Permissions**: User needs SUPER permissions for initial setup

### Testing Strategy
- Test via "Data Explorer with Copilot" action in Business Manager Role Center
- Verify function calls work: `get_tables`, `get_fields`, `get_data`
- Test permission boundaries with different user roles
- Validate result truncation and filtering suggestions

## AI System Message Architecture

The system message in `DataExplorerCapability.Codeunit.al` defines critical behavior:
- **Discovery Protocol**: Always use `get_tables` first, then `get_fields`, then `get_data`
- **Smart Result Display**: Show first 50 items with total counts and filtering suggestions
- **HTML Output**: Return structured HTML with inline CSS for professional presentation
- **Token Management**: Work within constraints while providing maximum value

## Key Integration Points

### Capability Registration
- Registered in `OnInstallAppPerCompany()` trigger
- Only registers in SaaS environments (`EnvironmentInfo.IsSaaSInfrastructure()`)
- Links to learning URL for Copilot overview

### Secret Management
- Uses Isolated Storage for API keys, endpoints, and model names
- `DataExplorerSecretMgt.Codeunit.al` handles secure retrieval
- Setup page provides configuration UI with connection testing

### Error Handling Pattern
```al
if not AOAIOperationResponse.IsSuccess() then begin
    HandleAOAIError();
    Response := 'I encountered an error processing your request. Please try again.';
end;
```

## Common Patterns to Follow

1. **Function Registration**: Register all functions in `RegisterFunctions()` method
2. **Permission Validation**: Always check `HasTablePermission()` before data access
3. **Result Formatting**: Use structured JSON with clear metadata (counts, pagination)
4. **Error Messages**: Provide user-friendly messages with specific guidance
5. **Telemetry**: Log function calls and performance metrics for monitoring

## Debugging & Troubleshooting

- **Setup Issues**: Check Data Explorer Setup page for configuration
- **Permission Errors**: Verify user has access to requested tables
- **Function Failures**: Review system message constraints and parameter validation
- **Performance**: Monitor result set sizes and apply appropriate limits

When extending this system, maintain the function-based architecture and always prioritize security through Business Central's permission system.
