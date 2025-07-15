# Data Explorer Setup Page Refresh Test Guide

## Test Objective
Verify that the Data Explorer Setup page displays configuration status updates immediately after setting or clearing values, without requiring the page to be closed and reopened.

## Prerequisites
1. Business Central environment with the CopilotAllTablesAndFields extension installed
2. Access to the Business Manager Role Center
3. Permission to access administration pages

## Test Data Requirements
- Azure OpenAI endpoint URL (e.g., `https://your-resource.openai.azure.com/`)
- Azure OpenAI model/deployment name (e.g., `gpt-4`)
- Azure OpenAI API key

## Test Scenarios

### Scenario 1: Setting Configuration Values
**Purpose**: Verify immediate status update when setting configuration values

#### Test Steps:
1. Navigate to **Business Manager Role Center**
2. Click on **Data Explorer Setup** action
3. Observe initial status:
   - All three fields should show: "Not Configured - Click to Set"
   - Status style should be "Attention" (typically amber/orange)

4. **Set Endpoint URL**:
   - Click on the "Endpoint Status" field or use the "Set Endpoint" action
   - Enter a valid endpoint URL in the dialog
   - Click OK
   
   **Expected Result**:
   - Endpoint Status immediately changes to "Configured"
   - Status style changes to "Favorable" (typically green)
   - No page refresh or reopening required

5. **Set Model**:
   - Click on the "Model Status" field or use the "Set Model" action
   - Enter a model name in the dialog
   - Click OK
   
   **Expected Result**:
   - Model Status immediately changes to "Configured"
   - Status style changes to "Favorable" (typically green)

6. **Set API Key**:
   - Click on the "API Key Status" field or use the "Set API Key" action
   - Enter an API key in the dialog (will be masked)
   - Click OK
   
   **Expected Result**:
   - API Key Status immediately changes to "Configured"
   - Status style changes to "Favorable" (typically green)

### Scenario 2: Clearing All Settings
**Purpose**: Verify immediate status update when clearing all configuration values

#### Test Steps:
1. Ensure all three settings are configured (follow Scenario 1)
2. Click the "Clear All Settings" action
3. Confirm the action when prompted

**Expected Result**:
- All three status fields immediately change to "Not Configured - Click to Set"
- All status styles change to "Attention" (amber/orange)
- A message "All settings have been cleared." appears
- No page refresh or reopening required

### Scenario 3: Cancel Dialog Without Setting Value
**Purpose**: Verify no changes occur when canceling the input dialog

#### Test Steps:
1. Click on any "Not Configured" status field
2. When the input dialog appears, click Cancel or press ESC

**Expected Result**:
- Status remains "Not Configured - Click to Set"
- No changes to the page display

### Scenario 4: Setting Empty Value
**Purpose**: Verify no changes occur when entering empty value

#### Test Steps:
1. Click on any "Not Configured" status field
2. Leave the input field empty
3. Click OK

**Expected Result**:
- Dialog should not close (validation prevents empty values)
- If dialog does close, status should remain "Not Configured - Click to Set"

### Scenario 5: Overwriting Existing Configuration
**Purpose**: Verify status remains "Configured" when updating existing values

#### Test Steps:
1. Ensure a setting is already configured
2. Click on the "Configured" status field
3. Enter a new value
4. Click OK

**Expected Result**:
- Status remains "Configured"
- Status style remains "Favorable" (green)
- The new value is stored (though not visible in UI for security)

## Edge Cases

### Edge Case 1: Page Navigation
1. Configure some settings
2. Navigate away from the page (e.g., go to Home)
3. Return to Data Explorer Setup page

**Expected Result**:
- Previously configured settings still show as "Configured"

### Edge Case 2: Multiple Users
1. User A opens Data Explorer Setup page
2. User B opens the same page and configures settings
3. User A performs an action on their page

**Expected Result**:
- User A should see updated statuses after their next action

## Validation Checklist
- [ ] All status fields update immediately after setting values
- [ ] All status fields update immediately after clearing values
- [ ] Status styles (colors) change appropriately
- [ ] No manual page refresh required
- [ ] CurrPage.Update() is called after each modification
- [ ] Rec.Get() refreshes the record data before UI update
- [ ] Cancel action doesn't change any status
- [ ] Empty values are properly handled

## Technical Verification
1. Verify `Rec.Get()` is called after each secret management operation
2. Verify `UpdateStyles()` is called to refresh the style expressions
3. Verify `CurrPage.Update(false)` is called to refresh the UI
4. Confirm the setup table has only one record (Primary Key = '')

## Common Issues and Solutions
- **Issue**: Status not updating immediately
  - **Solution**: Ensure `Rec.Get()` is called to reload record data
  
- **Issue**: Styles not changing color
  - **Solution**: Verify `UpdateStyles()` is called before `CurrPage.Update()`

- **Issue**: Page performance
  - **Solution**: Using `CurrPage.Update(false)` instead of `true` to avoid unnecessary save

## Test Result Documentation
Document the following for each test scenario:
- Test Date: ___________
- Tester Name: ___________
- BC Version: ___________
- Extension Version: ___________
- Test Result: Pass / Fail
- Notes: ___________