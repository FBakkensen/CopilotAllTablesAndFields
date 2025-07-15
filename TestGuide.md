# Data Explorer for Business Central - Comprehensive Test Guide

## Overview
This guide provides step-by-step instructions for testing the Data Explorer Copilot extension for Business Central. Follow these procedures to validate functionality, performance, security, and user experience.

## Prerequisites
- Business Central 2024 Wave 1 (v24.0) or later
- Azure OpenAI access (managed or custom deployment)
- Admin permissions for initial setup
- Test company with sample data

## 1. Installation and Setup Testing

### 1.1 Extension Installation
1. **Compile the extension**
   ```powershell
   .\scripts\build.ps1
   ```
   - Verify no compilation errors
   - Check all objects are within ID range 50100-50149

2. **Deploy to sandbox**
   - Use VS Code: F5 or Ctrl+F5
   - Verify extension appears in Extension Management
   - Check version number matches app.json

### 1.2 Initial Configuration
1. **Navigate to Data Explorer Setup**
   - Search for "Data Explorer Setup" in Tell Me
   - Verify page opens without errors

2. **Test Managed Resource (SaaS only)**
   - Enable "Use Managed Resource"
   - Save and verify no errors
   - Test connection should succeed

3. **Test Custom Resource**
   - Disable "Use Managed Resource"
   - Enter Azure OpenAI endpoint (e.g., https://your-resource.openai.azure.com/)
   - Enter deployment name (e.g., gpt-4o)
   - Enter API key
   - Click "Test Connection"
   - Verify success message

### 1.3 Permission Set Testing
1. **Admin User**
   - Assign "Data Explorer" permission set
   - Verify access to all features

2. **Standard User**
   - Assign "Data Explorer User" permission set
   - Verify can use prompt dialog but not setup

## 2. Functional Testing

### 2.1 Get Tables Function
1. **Open Data Explorer**
   - From Business Manager Role Center, click "Data Explorer with Copilot"
   - Or search "Data Explorer Prompt" in Tell Me

2. **Test Queries**
   ```
   Query: "Show me all tables"
   Expected: List of accessible tables with ID, name, caption, type, field count
   
   Query: "Show me only Normal tables"
   Expected: Filtered list showing only Normal table type
   
   Query: "List System tables"
   Expected: System tables only
   ```

3. **Validation Points**
   - ✓ Tables respect user permissions
   - ✓ Results limited to 1000 tables
   - ✓ Each table shows accurate field count

### 2.2 Get Fields Function
1. **Test Queries**
   ```
   Query: "What fields are in the Customer table?"
   Expected: All fields from Customer table with metadata
   
   Query: "Show fields for table 18"
   Expected: Customer table fields (using ID)
   
   Query: "Show Item table fields including FlowFields"
   Expected: All fields including calculated fields
   ```

2. **Validation Points**
   - ✓ Field details include: ID, name, caption, type, length
   - ✓ Option fields show option strings
   - ✓ Related fields show relation info
   - ✓ Primary key fields marked correctly

### 2.3 Get Data Function
1. **Basic Queries**
   ```
   Query: "Show me all customers"
   Expected: First 20 customer records
   
   Query: "Show customers from Seattle"
   Expected: Filtered customer list
   
   Query: "Find items with inventory below 10"
   Expected: Filtered item records
   ```

2. **Advanced Queries**
   ```
   Query: "Show sales orders over $10,000 from last month"
   Expected: Filtered and date-ranged results
   
   Query: "List the first 50 vendors sorted by name"
   Expected: Sorted results with pagination
   ```

3. **Validation Points**
   - ✓ Pagination works (20 records default)
   - ✓ Filters apply correctly
   - ✓ Sorting functions properly
   - ✓ Date filters calculate correctly

## 3. Security Testing

### 3.1 Permission Validation
1. **Create test user with limited permissions**
   - Remove read permission for Vendor table
   - Assign Data Explorer User permission

2. **Test restricted access**
   ```
   Query: "Show me all vendors"
   Expected: Error message about insufficient permissions
   ```

### 3.2 Input Validation
1. **Test injection attempts**
   ```
   Query: "Show customers where name = '; DROP TABLE Customer;--"
   Expected: Safe handling, no SQL injection
   
   Query: "Get data from table <script>alert('test')</script>"
   Expected: Input sanitized or rejected
   ```

### 3.3 Data Classification
1. **Verify sensitive data handling**
   - Check that tables with sensitive classification require appropriate permissions
   - Verify audit trail in Data Explorer History

## 4. Performance Testing

### 4.1 Large Dataset Queries
1. **Setup**
   - Ensure test company has >100k records in a table (e.g., Item Ledger Entry)

2. **Test queries**
   ```
   Query: "Show Item Ledger Entries from last year"
   Expected: Response within 5 seconds with pagination
   
   Query: "Count all General Ledger Entries"
   Expected: Efficient count without timeout
   ```

### 4.2 Concurrent Usage
1. **Multi-user test**
   - Have 5 users query simultaneously
   - Monitor response times
   - Check for any locks or conflicts

## 5. Error Handling Testing

### 5.1 API Errors
1. **Test rate limiting**
   - Make rapid repeated requests
   - Verify graceful error message

2. **Test invalid API key**
   - Change API key to invalid value
   - Verify clear error message

### 5.2 Data Errors
1. **Test invalid table names**
   ```
   Query: "Show data from NonExistentTable"
   Expected: "Table not found" message
   ```

2. **Test invalid field names**
   ```
   Query: "Show Customer.InvalidField"
   Expected: "Field not found" error
   ```

## 6. User Experience Testing

### 6.1 Prompt Guide
1. **Test each suggested prompt**
   - Click "Show all tables"
   - Click "Customer fields"
   - Click "Recent sales"
   - Click "Low inventory"
   - Verify each works correctly

### 6.2 Response Display
1. **Verify response formatting**
   - Check readability of responses
   - Verify data grid displays properly
   - Test "Show Details" for records

### 6.3 Export Functionality
1. **Test Excel export**
   - Query for data
   - Click "Export to Excel"
   - Verify file downloads and opens correctly

## 7. History and Audit Testing

### 7.1 History Recording
1. **Make several queries**
2. **Open Data Explorer History**
   - Verify all queries recorded
   - Check timestamps are accurate
   - Verify success/failure status

### 7.2 History Management
1. **Test cleanup**
   - Set retention to 1 day
   - Run cleanup process
   - Verify old entries removed

## 8. Integration Testing

### 8.1 Telemetry
1. **Enable telemetry in setup**
2. **Make various queries**
3. **Check Application Insights** (if configured)
   - Verify events logged
   - Check custom dimensions

### 8.2 Multi-language
1. **Change user language**
2. **Test queries in different language**
3. **Verify responses adapt appropriately**

## 9. Upgrade Testing

### 9.1 Version Compatibility
1. **Install on older BC version**
   - Verify appropriate error if incompatible

2. **Upgrade extension**
   - Modify version in app.json
   - Rebuild and deploy
   - Verify data preserved

## Test Checklist Summary

### Setup & Configuration
- [ ] Extension compiles without errors
- [ ] Setup page accessible and functional
- [ ] Managed resource connection works (SaaS)
- [ ] Custom resource connection works
- [ ] Permission sets apply correctly

### Core Functions
- [ ] Get tables returns accurate results
- [ ] Get fields shows complete metadata
- [ ] Get data retrieves records correctly
- [ ] Filtering works as expected
- [ ] Pagination functions properly
- [ ] Sorting applies correctly

### Security & Compliance
- [ ] Permissions enforced correctly
- [ ] Input validation prevents injection
- [ ] Sensitive data protected
- [ ] Audit trail maintained

### Performance & Reliability
- [ ] Large datasets handled efficiently
- [ ] Concurrent usage supported
- [ ] Error messages clear and helpful
- [ ] Recovery from API failures

### User Experience
- [ ] Natural language understanding accurate
- [ ] Response formatting clear
- [ ] Export functionality works
- [ ] History tracking complete

## Troubleshooting Common Issues

### "Copilot capability not registered"
- Run Data Explorer Management codeunit
- Execute RegisterCapability function

### "Invalid API response"
- Check Azure OpenAI deployment
- Verify API key is valid
- Check endpoint URL format

### "No data returned"
- Verify user has table permissions
- Check if filters too restrictive
- Ensure data exists in table

### Performance issues
- Review SetLoadFields usage
- Check for missing table indexes
- Verify pagination implemented

## Support Resources
- Technical documentation: /docs/technical-guide.md
- API reference: /docs/api-reference.md
- Microsoft AL Guidelines: https://alguidelines.dev
- BC Copilot Docs: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/ai-integration-landing-page