# Business Central Development Reference Guide 2025

This comprehensive reference document compiles Microsoft's official documentation and best practices for Business Central development as of 2025, specifically tailored for reviewing the CopilotAllTablesAndFields extension.

## Table of Contents
1. [Core AL Development Standards](#core-al-development-standards)
2. [Copilot and Azure OpenAI Integration](#copilot-and-azure-openai-integration)
3. [Performance Optimization Patterns](#performance-optimization-patterns)
4. [Security and Credential Management](#security-and-credential-management)
5. [Error Handling and Telemetry](#error-handling-and-telemetry)
6. [Testing Patterns](#testing-patterns)
7. [2025 Platform Updates](#2025-platform-updates)

## Core AL Development Standards

### Naming Conventions
- **Objects**: PascalCase naming (e.g., `DataExplorerCapability`)
- **Variables**: camelCase (e.g., `tableMetadata`)
- **Methods/Procedures**: PascalCase with clear verb-noun structure
- **Fields**: No spaces, PascalCase (e.g., `DeploymentName`)
- **API Pages**: camelCase for attributes, tables, APIPublisher, APIGroup, EntityName, and EntitySetName

### File Organization
- **One object per file** is best practice
- File names should contain: object name (A-Z, a-z, 0-9), object type, and .al extension
- Use prefix or suffix for all extension objects to avoid naming conflicts

### Code Structure
- Extensions should be in a single folder with:
  - `app.json` and `launch.json` files
  - `/src` folder for source code
  - `/res` folder for resources
  - `/test` folder for test code
- Blank line required between method declarations
- Parentheses required for method calls: `Init()`, `Modify()`, `Insert()`
- Variable declarations: `name: Type` (space after colon)

### Community Resources
- Check https://alguidelines.dev/ for emerging patterns and community discussions

## Copilot and Azure OpenAI Integration

### System.AI Namespace Architecture
The AI module in System Application provides:
- Support for text/chat completion and embeddings
- Large Language Model (LLM) integration (GPT models)
- Does NOT support image generation (DALL-E) or speech-to-text (Whisper)

### Implementation Pattern
1. **Capability Registration**: Every extension must register with the Copilot Capability codeunit
2. **Authorization Setup**: Using `SetAuthorization` with IsolatedStorage for secure credential storage
3. **Parameter Configuration**: Set max tokens and temperature (0-2)
4. **System Message**: Primary system message included in all chat histories

### 2025 Business Central AI Resources
- **Default Approach**: Use Microsoft-managed Azure OpenAI resources
- **Benefits**: 
  - No need for customer Azure OpenAI subscriptions
  - Proactive scaling, throttling, load balancing
  - Simplified onboarding and improved reliability
- **Authentication**: Use `SetManagedResourceAuthorization` method

### Key Components
- **PromptDialog Page**: Unified UI for generative AI experiences
- **Built-in Safety Controls**: Prompt guard rails for responsible AI
- **Telemetry Integration**: Usage insights for AI capabilities
- **Cross-Geography Data Movement**: Enabled by default from v25.0

### Supported Models
All Azure OpenAI models supported when using Business Central developer tools and AI resources

## Performance Optimization Patterns

### Partial Records with SetLoadFields
**Key Benefits:**
- 9x faster execution for single field loads
- Significant gains with table extensions
- Reduces database I/O and network traffic

**Implementation Pattern:**
```al
procedure ComputeAritmeticMean(MyRecordRef: RecordRef; FieldNo: Integer): Decimal
var
    SumTotal: Decimal;
    Counter: Integer;
begin
    MyRecordRef.SetLoadFields(FieldNo);
    if MyRecordRef.FindSet() then begin
        repeat
            SumTotal := MyRecordRef.Field(FieldNo).Value;
            Counter += 1;
        until MyRecordRef.Next() = 0;
        exit(SumTotal / Counter);
    end;
end;
```

**Important Notes:**
- Always loaded fields: Primary key, SystemId, data audit fields
- Only FieldClass = Normal supported
- Call before Get, Find, Next operations
- Platform auto-applies to reports, OData pages, list pages, lookups

### String Performance
- Use `Text` for < 5 concatenations
- Use `TextBuilder` for ≥ 5 concatenations or loops
- Prefer `TextBuilder` over `BigText`

### Set-Based Operations
Prefer `FindSet`, `CalcFields`, `CalcSums`, `SetAutoCalcFields` over loops

### Table Extension Optimization (2023+)
All table extension data stored in single companion table = at most one SQL join

## Security and Credential Management

### SecretText Type
- Non-debuggable string type for sensitive data
- Protects credentials from debugger inspection
- Required for API keys and sensitive values

### IsolatedStorage Pattern
```al
IsolatedStorage.SetEncrypted(Key: Text, Value: SecretText [, DataScope: DataScope])
```
- Provides isolation between extensions
- DataScope controls access levels (default: Module)
- Encrypted storage for sensitive data

### Permission Model
- Respect Business Central's built-in permission system
- Implement row-level security checks
- Test with non-SUPER users and ESSENTIAL license

## Error Handling and Telemetry

### Telemetry Configuration (2025 Update)
- **CRITICAL**: Transition to connection strings by March 31, 2025
- Instrumentation key-based ingestion ending
- Configure in Azure Application Insights

### Error Telemetry
- Automatic emission on user error dialogs
- Custom error telemetry: `Telemetry.LogError`
- Error method trace telemetry for debugging

### Telemetry Events
- Business Central 2025 wave 1 (v26.0) introduced new telemetry events
- Configure AL Function Timing and Logging Threshold for on-premises

### Performance Monitoring
- Long-running AL method telemetry
- Execution time breakdown by event subscribers
- Database time tracking

## Testing Patterns

### Test Codeunit Structure
- SubType Property set to `TestRunner`
- OnRun trigger for test execution
- OnBeforeTestRun/OnAfterTestRun for setup/teardown

### Testing Requirements
- Test with non-SUPER permissions
- Use ESSENTIAL license for testing
- Automate tests for unattended execution
- Integration with test management frameworks

## 2025 Platform Updates

### Business Central 2025 Wave 1 (v26.0)
- **Runtime**: v15.0
- **Focus**: Developer productivity and citizen developer empowerment
- **Profile Extensions**: New extensibility without code duplication

### Key Features
- Default cross-geography data movement (from v25.0)
- Enhanced table extension data model
- New telemetry capabilities
- Improved Copilot integration

### API Updates
- New v1 Azure OpenAI APIs (May 2025)
- Responses API combining chat completions and assistants
- Ongoing feature access without api-version updates

## Review Checklist for CopilotAllTablesAndFields

Based on this reference, key areas to review:

1. **Naming Conventions**: Verify PascalCase/camelCase usage
2. **Security**: Check SecretText usage for API keys, IsolatedStorage implementation
3. **Performance**: Verify SetLoadFields usage with RecordRef operations
4. **Error Handling**: Ensure proper telemetry logging (Event IDs: DEX-0001, etc.)
5. **AI Integration**: Validate System.AI namespace usage and capability registration
6. **Permissions**: Confirm TablePermissionHelper implementation
7. **Testing**: Check for test scenarios per TestGuide.md
8. **2025 Compliance**: Ensure v26.0 compatibility and features

## Additional Resources

- [AL Guidelines Community](https://alguidelines.dev/)
- [Microsoft Learn - Business Central](https://learn.microsoft.com/dynamics365/business-central/)
- [Azure OpenAI Documentation](https://learn.microsoft.com/azure/ai-services/openai/)