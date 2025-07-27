
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

### Build Output Analysis
- Build output is captured in `build.log` at the project root
- After running `make build`, examine `build.log` for detailed compiler output, errors, warnings, and build status
- Use `build.log` to diagnose compilation issues and verify successful builds

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
├── DataExplorerPrompt/       # Original PromptDialog interface
├── ModernChatInterface/      # Modern Control Add-in chat interface
│   └── ChatInterface/        # JavaScript/CSS for chat UI
├── MultiChatDemo/           # Multi-turn conversation demo
├── Shared/                  # Core shared components
│   ├── Functions/           # AOAI Function implementations (get_tables, get_fields, get_data)
│   ├── Helpers/             # Security, chat history, HTML generation
│   ├── Setup/               # Configuration and secret management
│   ├── Install/             # Capability registration on installation
│   ├── EnumExtensions/      # Copilot capability enum extension
│   └── PageExtensions/      # UI integration (Business Manager Role Center)
```

### Critical Files
- `DataExplorerCapability.Codeunit.al`: Main orchestrator with system message and function registration
- `Get*Function.Codeunit.al`: Three core functions implementing `AOAI Function` interface
- `ChatHistoryManager.Codeunit.al`: JSON-based chat history management system
- `ChatInterface.ControlAddIn.al`: Modern control add-in for chat UI with JavaScript bridge
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

### Chat History Architecture (JSON-Based)
- **ChatHistoryManager**: JSON-based in-memory chat session management
- **ChatHistoryAdapter**: Bridge for HTML generation from JSON data
- **SessionId Pattern**: All chat operations use GUID-based session management
- **Message Structure**: `{entryNo, sessionId, messageType, messageText, messageDateTime}`
- **HTML Generation**: `ChatBubbleHTMLGenerator` creates styled HTML from JSON arrays

### Control Add-in Patterns
- **Dual Interface**: Both directory structures for ModernChatInterface and legacy paths
- **JavaScript Bridge**: AL ↔ JavaScript communication via `Microsoft.Dynamics.NAV.InvokeExtensibilityMethod`
- **Event-Driven**: `MessageSent`, `ChatCleared`, `AddInReady` events from JS to AL
- **Table Processing**: Smart pipe-separated table detection and formatting in JavaScript
- **Typing Indicators**: Visual feedback during AI processing

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

### Modern Chat Interface Architecture
- **Three Chat Implementations**: PromptDialog (legacy), Modern ControlAddIn, Multi-turn demo
- **Control Add-in Communication**: `MessageSent(message: Text)`, `ChatCleared()`, `AddInReady()`
- **JavaScript Features**: Auto-table formatting, XSS protection, typing indicators, Enter-to-send
- **CSS Theming**: Catppuccin Mocha dark theme with responsive design
- **Session Management**: GUID-based sessions with JSON message persistence

### Capability Registration
- Registered in `OnInstallAppPerCompany()` trigger
- Only registers in SaaS environments (`EnvironmentInfo.IsSaaSInfrastructure()`)
- Links to learning URL for Copilot overview

### Secret Management
- Uses Isolated Storage for API keys, endpoints, and model names
- `DataExplorerSecretMgt.Codeunit.al` handles secure retrieval
- Setup page provides configuration UI with connection testing

### Chat History System
- **JSON-Based Architecture**: Replaces temporary table approach for better performance
- **Session Isolation**: Multiple concurrent conversations supported
- **Message Sorting**: Automatic chronological ordering by datetime
- **Export/Import**: Complete chat history serialization for persistence
- **HTML Generation**: Direct JSON-to-HTML rendering with bubble styling

### Error Handling Pattern
```al
if not AOAIOperationResponse.IsSuccess() then begin
    HandleAOAIError();
    Response := 'I encountered an error processing your request. Please try again.';
end;
```

## Common Patterns to Follow

### Chat Interface Development
1. **Control Add-in Structure**: JavaScript in `/js/`, CSS in `/css/`, startup script for initialization
2. **Event Communication**: Use `Microsoft.Dynamics.NAV.InvokeExtensibilityMethod` for AL-JavaScript bridge
3. **Table Formatting**: Pipe-separated content automatically converts to HTML tables
4. **State Management**: Track `isProcessing` and `typingIndicatorVisible` global states
5. **XSS Protection**: Always use `escapeHtml()` for user content

### JSON Chat History Management
1. **Session Initialization**: `ChatHistoryMgr.InitializeSession(SessionId)` before any operations
2. **Message Addition**: Include all required fields: `entryNo`, `sessionId`, `messageType`, `messageText`, `messageDateTime`
3. **HTML Generation**: Use `ChatHistoryAdapter.GenerateHTMLFromJson()` for display
4. **Memory Management**: Clear sessions when conversations end to prevent memory leaks

### Function Registration
1. **Function Registration**: Register all functions in `RegisterFunctions()` method
2. **Permission Validation**: Always check `HasTablePermission()` before data access
3. **Result Formatting**: Use structured JSON with clear metadata (counts, pagination)
4. **Error Messages**: Provide user-friendly messages with specific guidance
5. **Telemetry**: Log function calls and performance metrics for monitoring

## Debugging & Troubleshooting

### Build and Deployment
- **Primary Build**: Use `make build` (cross-platform via PowerShell/Bash scripts)
- **Build Validation**: Check `build.log` for detailed compiler output and errors
- **Task Completion**: All changes must pass `make build` without errors/warnings
- **Clean Build**: Use `make clean` to remove build artifacts when needed

### Development Issues
- **Setup Issues**: Check Data Explorer Setup page for configuration
- **Permission Errors**: Verify user has access to requested tables
- **Function Failures**: Review system message constraints and parameter validation
- **Performance**: Monitor result set sizes and apply appropriate limits

### Control Add-in Debugging
- **JavaScript Console**: Use browser developer tools for control add-in debugging
- **AL Communication**: Test `Microsoft.Dynamics.NAV.InvokeExtensibilityMethod` availability
- **Event Flow**: Verify `AddInReady()`, `MessageSent()`, `ChatCleared()` event sequence
- **Table Rendering**: Check pipe-separated content detection and HTML conversion

### Chat History Issues
- **Session Management**: Ensure `InitializeSession()` called before message operations
- **JSON Structure**: Validate session and message JSON structure integrity
- **Memory Usage**: Monitor JSON object sizes for large conversation histories
- **HTML Generation**: Test `ChatBubbleHTMLGenerator` output for styling issues

When extending this system, maintain the function-based architecture and always prioritize security through Business Central's permission system.
