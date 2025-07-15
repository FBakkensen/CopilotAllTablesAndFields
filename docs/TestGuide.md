# Copilot Data Explorer - Test Guide

This guide provides comprehensive testing instructions for the Copilot Data Explorer extension.

## Prerequisites

1. Business Central 2024 Wave 1 (v24.0) or later
2. Azure OpenAI resource (for custom deployment) or SaaS environment with managed AI
3. User with SUPER permissions for initial setup
4. Test data in Business Central tables

## Setup and Configuration

### 1. Deploy the Extension

```powershell
# Build the extension
.\scripts\build.ps1

# Deploy to your BC environment
# Use VS Code AL extension or admin center to deploy the .app file
```

### 2. Configure Data Explorer Setup

1. Search for "Data Explorer Setup" in Business Central
2. Configure based on your environment:

#### For SaaS with Managed AI:
- Enable "Use Managed Resource" toggle
- No additional configuration needed

#### For Custom Azure OpenAI:
- Disable "Use Managed Resource" toggle
- Enter your Azure OpenAI endpoint URL
- Enter deployment name (e.g., "gpt-4")
- Enter API key
- Click "Test Connection" to verify

### 3. Verify Copilot Capability

1. Go to Business Manager Role Center
2. Look for "Data Explorer with Copilot" action
3. Verify the action is visible and accessible

## Functional Tests

### Test 1: Basic Table Listing

**Objective**: Verify the get_tables function works correctly

**Steps**:
1. Open "Data Explorer with Copilot"
2. Enter prompt: "Show me all tables I can access"
3. Click Generate

**Expected Results**:
- List of accessible tables appears
- Each table shows: ID, Name, Caption, Type, Field Count
- Only tables with read permissions are shown

### Test 2: Filtered Table Listing

**Objective**: Test table filtering functionality

**Test Cases**:
1. Prompt: "Show me all Normal tables"
   - Should show only Normal table type
2. Prompt: "Show me System tables"
   - Should show only System tables
3. Prompt: "Show me Virtual tables"
   - Should show only Virtual tables

### Test 3: Field Information Retrieval

**Objective**: Verify get_fields function

**Test Cases**:
1. Prompt: "What fields are in the Customer table?"
   - Should list all Customer table fields
2. Prompt: "Show me fields for table 18"
   - Should show Customer fields (by ID)
3. Prompt: "Show fields in Item table"
   - Should show Item table fields

**Expected Results**:
- Field list includes: ID, Name, Type, Caption
- Primary key fields are marked
- Field relations are shown where applicable

### Test 4: Data Retrieval - Basic

**Objective**: Test basic data query functionality

**Test Cases**:
1. Prompt: "Show me all customers"
   - Should return first 20 customers
2. Prompt: "Get data from Item table"
   - Should return first 20 items
3. Prompt: "Show sales orders"
   - Should return sales order records

### Test 5: Data Retrieval - With Filters

**Objective**: Test filtering capabilities

**Test Cases**:
1. Prompt: "Show customers from Seattle"
   - Should filter by city
2. Prompt: "Show items where inventory is less than 10"
   - Should apply numeric filter
3. Prompt: "Show sales orders from last 30 days"
   - Should apply date filter

### Test 6: Data Retrieval - Pagination

**Objective**: Test pagination functionality

**Test Cases**:
1. Prompt: "Show me 50 customers"
   - Should return 50 records (if available)
2. Prompt: "Show page 2 of customers with 10 per page"
   - Should skip first 10 and show next 10

### Test 7: Complex Queries

**Objective**: Test advanced query capabilities

**Test Cases**:
1. Prompt: "Show customers from USA sorted by name"
   - Should filter and sort
2. Prompt: "Show top 5 items by unit price descending"
   - Should sort and limit
3. Prompt: "Show orders with amount > 1000 for customer 10000"
   - Should apply multiple filters

## Permission Tests

### Test 8: Permission Validation

**Objective**: Ensure security is enforced

**Steps**:
1. Create test user with limited permissions
2. Grant read access to Customer table only
3. Login as test user
4. Test various prompts

**Test Cases**:
1. "Show all tables" - Should only show Customer
2. "Show vendor data" - Should return permission error
3. "Show customer data" - Should work correctly

## Performance Tests

### Test 9: Large Dataset Handling

**Objective**: Verify performance with large data

**Test Cases**:
1. Query table with >10,000 records
2. Verify pagination works correctly
3. Check response time is acceptable
4. Ensure memory usage is reasonable

### Test 10: Concurrent Usage

**Objective**: Test multi-user scenarios

**Steps**:
1. Have multiple users access Copilot simultaneously
2. Execute different queries
3. Verify no interference between sessions

## Error Handling Tests

### Test 11: Invalid Queries

**Objective**: Test error handling

**Test Cases**:
1. Prompt: "Show data from NonExistentTable"
   - Should return "Table not found" error
2. Prompt: "Show InvalidField from Customer"
   - Should return "Field not found" error
3. Invalid filter syntax
   - Should return helpful error message

### Test 12: API Failures

**Objective**: Test Azure OpenAI error handling

**Steps**:
1. Configure invalid API key
2. Try to use Copilot
3. Should show connection error
4. Fix configuration and retry

## Integration Tests

### Test 13: History Tracking

**Objective**: Verify usage history is recorded

**Steps**:
1. Execute several queries
2. Navigate to "Data Explorer History"
3. Verify all queries are logged
4. Check timestamps and user info

### Test 14: Export Functionality

**Objective**: Test data export features

**Steps**:
1. Query data successfully
2. Use "Export to Excel" action
3. Verify Excel file is generated
4. Check data integrity in export

## Telemetry Tests

### Test 15: Telemetry Logging

**Objective**: Verify telemetry is captured

**Steps**:
1. Enable telemetry in setup
2. Execute various operations
3. Check Application Insights (if configured)
4. Verify events are logged correctly

## Test Scenarios by User Role

### Business User Tests
- Natural language queries for common tasks
- Report generation scenarios
- Data exploration workflows

### Power User Tests
- Complex filtering and sorting
- Cross-table queries
- Bulk data operations

### Administrator Tests
- Setup and configuration
- Permission management
- Monitoring and troubleshooting

## Regression Test Checklist

Before each release, verify:

- [ ] All three functions (get_tables, get_fields, get_data) work
- [ ] Permission checks are enforced
- [ ] Pagination works correctly
- [ ] Filters apply properly
- [ ] Sorting functions as expected
- [ ] Error messages are helpful
- [ ] Performance is acceptable
- [ ] History is tracked
- [ ] Export works correctly
- [ ] Setup page functions properly

## Known Limitations to Test

1. Maximum 100 records per page
2. Maximum 1000 tables in list
3. Complex joins not supported
4. Calculated fields may not appear
5. FlowFields require special handling

## Troubleshooting Guide

### Common Issues:

1. **"Capability not enabled" error**
   - Check Copilot capability registration
   - Verify user permissions

2. **No results returned**
   - Check table permissions
   - Verify filters are correct
   - Check for empty tables

3. **Slow performance**
   - Check number of records
   - Verify SetLoadFields is working
   - Monitor API response times

4. **Azure OpenAI errors**
   - Verify API key and endpoint
   - Check deployment name
   - Test connection from setup

## Performance Benchmarks

Expected response times:
- Simple table list: < 2 seconds
- Field information: < 1 second  
- Data query (20 records): < 3 seconds
- Data query (100 records): < 5 seconds
- Complex filtered query: < 5 seconds

## Security Test Cases

1. SQL injection attempts in filters
2. Permission elevation attempts
3. Cross-tenant data access attempts
4. API key exposure checks
5. Audit trail completeness

## Acceptance Criteria

The extension is ready for production when:
1. All functional tests pass
2. Performance meets benchmarks
3. Security tests show no vulnerabilities
4. Error handling is comprehensive
5. Documentation is complete
6. User feedback is positive