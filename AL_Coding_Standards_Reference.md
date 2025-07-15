# Comprehensive AL Coding Standards Reference
## Microsoft Business Central Development Guidelines

This document serves as the primary reference for AL coding standards, compiled from official Microsoft documentation, community guidelines (alguidelines.dev), and code analyzer rules.

---

## Table of Contents
1. [File and Folder Organization](#file-and-folder-organization)
2. [Naming Conventions](#naming-conventions)
3. [Code Structure and Formatting](#code-structure-and-formatting)
4. [Variable Guidelines](#variable-guidelines)
5. [Method and Procedure Guidelines](#method-and-procedure-guidelines)
6. [Object Design Standards](#object-design-standards)
7. [Performance Best Practices](#performance-best-practices)
8. [Security and Compliance](#security-and-compliance)
9. [Code Analyzers Reference](#code-analyzers-reference)
10. [Copilot Integration Guidelines](#copilot-integration-guidelines)
11. [Error Handling Patterns](#error-handling-patterns)
12. [Testing Standards](#testing-standards)

---

## 1. File and Folder Organization

### Extension Structure
- Extensions must be contained in a single root folder
- Recommended folder structure:
  ```
  Extension/
  ├── app.json              # Application manifest
  ├── launch.json           # Debug configuration
  ├── src/                  # Source code
  ├── test/                 # Test code
  ├── res/                  # Resources
  └── Translations/         # Translation files (.xliff)
  ```

### File Naming Conventions
- Format: `<ObjectName>.<ObjectType>.al`
- Examples:
  - `Customer.Table.al`
  - `CustomerList.Page.al`
  - `CustomerCard.PageExt.al` (Extensions use 'Ext' suffix)
- Allowed characters: A-Z, a-z, 0-9
- No spaces or special characters in filenames

---

## 2. Naming Conventions

### Object Naming
- **Format**: Prefix with feature/group name + logical name
- **Case**: PascalCase
- **Examples**:
  ```al
  table 51310 "DataExplorer Setup"
  codeunit 51320 "DataExplorer Capability"
  page 51330 "DataExplorer Prompt"
  ```
- Objects are referenced by name, not ID
- "MS -" prefix is not required

### Variable Naming
- **Case**: PascalCase
- **Rules**:
  1. Must begin with a capital letter
  2. No blanks, periods, or special characters (%, &, parentheses)
  3. Compound words: Each word/abbreviation starts with capital letter
  4. Must contain object name when referring to AL objects
  
- **Examples**:
  ```al
  var
      Customer: Record Customer;
      CustomerLedgerEntry: Record "Cust. Ledger Entry";
      GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
      AmountLCY: Decimal;
      IsHandled: Boolean;
      TempJobWIPBuffer: Record "Job WIP Buffer" temporary;
  ```

### Field Naming
- No spaces in field names
- PascalCase
- Examples: `DeploymentName`, `ApiKey`, `RecordCount`

### Procedure/Method Naming
- PascalCase
- Clear verb-noun structure
- Examples: `CalculateTotalAmount()`, `ValidateCustomerData()`, `GetFieldMetadata()`

### Constants and Labels
- TextConst suffix conventions:
  - `Tok` - Token
  - `Msg` - Message
  - `Err` - Error
  - `Qst` - Question
  - `Lbl` - Label
  - `Txt` - Text

---

## 3. Code Structure and Formatting

### AL File Structure (Required Order)
1. Properties
2. Object-specific constructs (fields, keys, controls)
3. Global variables
4. Methods/Procedures

### Formatting Rules
- **Indentation**: 4 spaces (not tabs)
- **Keywords**: Always lowercase (`var`, `begin`, `end`, `if`, `then`)
- **Spacing**:
  - One space on each side of binary operators (`:=`, `+`, `-`, `and`, `or`)
  - One space after semicolons in parameter lists
  - No trailing spaces
- **Line breaks**:
  - Curly brackets `{}` start on new line
  - `begin` on same line as `then`, `else`, `do` (preceded by one space)
  - `end`, `if`, `repeat`, `until`, `for`, `while`, `case` always start a new line

### Code Examples
```al
// Correct formatting
procedure CalculateAmount(Quantity: Decimal; UnitPrice: Decimal): Decimal
var
    TotalAmount: Decimal;
begin
    if Quantity <> 0 then begin
        TotalAmount := Quantity * UnitPrice;
        exit(TotalAmount);
    end;
    
    exit(0);
end;

// Incorrect formatting to avoid
procedure BadExample(Quantity:Decimal;UnitPrice:Decimal):Decimal
var
TotalAmount:Decimal;
begin
    if Quantity<>0 then
    begin  // 'begin' should be on same line as 'then'
        TotalAmount:=Quantity*UnitPrice;  // Missing spaces around operators
        exit(TotalAmount);
    end;
end;
```

---

## 4. Variable Guidelines

### Variable Declaration Order
Objects and complex types first, then simple types:
1. Record
2. Report
3. Codeunit
4. XmlPort
5. Page
6. Query
7. Notification
8. BigText
9. DateFormula
10. RecordId
11. RecordRef
12. FieldRef
13. FilterPageBuilder
14. (Other complex types)
15. (Simple types: Text, Code, Integer, Decimal, Boolean, etc.)

### Variable Naming Best Practices
- Temporary variables: Prefix with "Temp"
- Boolean variables: Use "Is", "Has", "Can" prefixes
- Avoid abbreviations when possible
- If abbreviations necessary, use standard ones:
  - account → Acc
  - amount → Amt
  - customer → Cust
  - document → Doc
  - general → Gen
  - journal → Jnl
  - ledger → Ledg
  - posting → Post

---

## 5. Method and Procedure Guidelines

### Declaration Standards
```al
procedure PublicProcedure(CustomerNo: Code[20]; ShowDetails: Boolean): Decimal
var
    Customer: Record Customer;
    TotalAmount: Decimal;
begin
    // Implementation
end;

local procedure LocalProcedure(var TempBuffer: Record "Some Buffer" temporary)
begin
    // Implementation
end;
```

### Best Practices
- Include parentheses even for parameterless methods: `Initialize()`
- Blank line between method declarations
- Exit early pattern: Use `if not Condition then exit;`
- Avoid deeply nested code
- Single responsibility principle

### Event Patterns
- Publisher events: Use "On" prefix (e.g., `OnBeforePostDocument`)
- Subscriber naming: Include source object (e.g., `SalesHeader_OnBeforeValidateCustomer`)

---

## 6. Object Design Standards

### Table Design
- Primary key fields first
- Group related fields together
- Proper DataClassification on all fields
- CalcFormula for FlowFields must be optimized

### Page Design
- Set ApplicationArea on all UI elements
- ToolTip required for all fields and actions
- UsageCategory required for list pages
- Promoted actions for common tasks
- Use repeater groups for list pages

### Codeunit Design
- Write code in codeunits rather than on objects
- Single responsibility principle
- Avoid codeunits over 1000 lines
- Use clear, descriptive names

---

## 7. Performance Best Practices

### Database Access
- Use SetLoadFields for partial records:
  ```al
  Customer.SetLoadFields(Name, "Credit Limit");
  if Customer.Get(CustomerNo) then
      // Process customer
  ```
- Use DeleteAll(true) instead of loops when possible
- Avoid unnecessary database calls
- Use temporary tables for complex calculations

### Query Optimization
- Filter before sorting
- Limit result sets
- Use appropriate keys
- Avoid non-indexed field filtering

### General Performance
- Check IsTemporary before operations
- Minimize loop operations
- Cache frequently used data
- Use lazy loading patterns

---

## 8. Security and Compliance

### Critical Requirements
- **Never** use SUPER permissions
- All fields must have DataClassification
- Encrypt sensitive data (passwords, credit cards)
- Clean up temporary files after use
- Implement proper permission sets

### Azure OpenAI Integration
- Use SecretText type for API keys
- Store credentials in IsolatedStorage
- Never hardcode credentials
- Implement connection testing
- Include proper error handling

### Permission Handling
- Check permissions before data access
- Use `Record.ReadPermission`, `WritePermission`, etc.
- Provide meaningful error messages for permission failures

---

## 9. Code Analyzers Reference

### CodeCop Rules (AA prefix)
Key rules to follow:
- **AA0001**: One space on each side of binary operators
- **AA0003**: One space between NOT operator and argument
- **AA0005**: Only use BEGIN..END for compound statements
- **AA0008**: Function calls need parentheses
- **AA0013**: BEGIN on same line as THEN, ELSE, DO
- **AA0018**: Keywords start new line
- **AA0021**: Order variable declarations by type
- **AA0040**: Avoid nested WITH statements
- **AA0072**: Variable names must include type/object suffix
- **AA0137**: Remove unused variables
- **AA0139**: Avoid risky assignments
- **AA0194**: Only write actions on card pages
- **AA0198**: Avoid identical local/global variable names
- **AA0211**: CalcFields only on FlowFields
- **AA0220**: ToolTip required for page fields

### UICop Rules (AW prefix)
- **AW0001**: Show request page for reports
- **AW0005**: Actions need Image property
- **AW0006**: Pages need UsageCategory

### AppSourceCop Rules (AS prefix)
- **AS0011**: Provide prefix/suffix for objects
- **AS0062**: ApplicationArea required
- **AS0079**: Maintain affix consistency

### PerTenantExtensionCop (PTE prefix)
- **PTE0008**: ApplicationArea required for fields

---

## 10. Copilot Integration Guidelines

### Implementation Standards
- Use PromptDialog mode for AI interactions
- Implement proper telemetry (Event pattern: XXX-0001)
- Format responses appropriately (HTML/Markdown)
- Handle rate limiting gracefully
- Remove trailing spaces in action names

### Function Registration
```al
procedure RegisterCapability()
var
    CopilotCapability: Codeunit "Copilot Capability";
begin
    CopilotCapability.RegisterCapability(
        Enum::"Copilot Capability Type"::"My Capability",
        LearnMoreUrl);
end;
```

---

## 11. Error Handling Patterns

### Best Practices
- Use specific error messages
- Include actionable guidance
- Implement drill-down actions where appropriate
- Log errors to telemetry
- Use Error() not Message() for failures

### Pattern Examples
```al
// Good error handling
if not Customer.Get(CustomerNo) then
    Error(CustomerNotFoundErr, CustomerNo);

// Error with action
Error(InsufficientPermissionErr, TableCaption, GetMissingPermissionAction());
```

---

## 12. Testing Standards

### Requirements
- Test without SUPER permissions
- Cover positive and negative scenarios
- Test permission boundaries
- Verify error messages
- Test on current BC version
- Use ESSENTIAL license for testing

### Test Method Naming
```al
[Test]
procedure GetTables_UserHasPermission_ReturnsTableList()
begin
    // Arrange
    // Act
    // Assert
end;
```

---

## Anti-Patterns to Avoid

1. **Never** hardcode IDs or magic numbers
2. **Avoid** nested WITH statements
3. **Don't** use AssertError outside test codeunits
4. **Avoid** OnBeforeCompanyOpen/OnAfterCompanyOpen
5. **Don't** insert into Profile table
6. **Never** require specific printer selection
7. **Avoid** using specific time zones
8. **Don't** create files without cleanup

---

## Conclusion

These standards ensure:
- Consistent, readable code
- Optimal performance
- Security compliance
- Maintainability
- AppSource readiness

Always run code analysis with CodeCop, UICop, and AppSourceCop enabled during development. Address all warnings and errors before considering code complete.