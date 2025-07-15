codeunit 51310 "Data Explorer Capability"
{
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";


    procedure GenerateCompletions(Intent: Text; var Response: Text): Boolean
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        SystemMessage: Text;
        UserMessage: Text;
        Success: Boolean;
    begin
        SystemMessage := GetSystemMessage();
        UserMessage := Intent;

        Clear(AOAIChatMessages);
        AOAIChatMessages.SetPrimarySystemMessage(SystemMessage);
        AOAIChatMessages.AddUserMessage(UserMessage);

        SetAuthorization(AzureOpenAI);

        // Set completion parameters
        AOAIChatCompletionParams.SetMaxTokens(2000);
        AOAIChatCompletionParams.SetTemperature(0);

        // Set the copilot capability for the generation - this links the AI call to our registered capability
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Data Explorer Preview");

        RegisterFunctions();

        // Generate completion
        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);

        Success := AOAIOperationResponse.IsSuccess();

        if Success then
            Response := AOAIChatMessages.GetLastMessage()
        else begin
            HandleAOAIError();
            Response := 'I encountered an error processing your request. Please try again.';
        end;

        exit(Success);
    end;

    local procedure GetSystemMessage(): Text
    var
        SystemMessageTxt: Label @'You are a helpful assistant for Business Central data exploration.
You help users discover and retrieve data from Business Central tables.
Use the provided functions to access table metadata, field information, and data records.
Always ensure you have permission to access requested data.
When retrieving data, be mindful of performance and use appropriate filters and pagination.

IMPORTANT: Always format your responses as valid HTML.
Use tables (<table>, <tr>, <td>) for tabular data, lists (<ul>, <ol>, <li>) for lists, and appropriate styling.
Include inline CSS for better presentation.
Include the full HTML structure in your response, including <html>, <head>, and <body> tags.', Locked = true;
    begin
        exit(SystemMessageTxt);
    end;

    local procedure RegisterFunctions()
    var
        GetTablesFunction: Codeunit "Get Tables Function";
        GetFieldsFunction: Codeunit "Get Fields Function";
        GetDataFunction: Codeunit "Get Data Function";
    begin
        AOAIChatMessages.AddTool(GetTablesFunction);
        AOAIChatMessages.AddTool(GetFieldsFunction);
        AOAIChatMessages.AddTool(GetDataFunction);
        AOAIChatMessages.SetToolInvokePreference(Enum::"AOAI Tool Invoke Preference"::Automatic);
    end;


    [NonDebuggable]
    local procedure SetAuthorization(var AzureOpenAI: Codeunit "Azure OpenAI")
    var
        DataExplorerSecretMgt: Codeunit "Data Explorer Secret Mgt.";
        APIKeySecret: SecretText;
        EndpointText: Text;
        ModelText: Text;
    begin
        // Check if setup is configured
        if not DataExplorerSecretMgt.IsConfigured() then
            ThrowNotConfiguredError();

        // Get values from secure storage
        EndpointText := DataExplorerSecretMgt.GetEndpointAsText();
        ModelText := DataExplorerSecretMgt.GetModelAsText();
        APIKeySecret := DataExplorerSecretMgt.GetAPIKey();  // Keep as SecretText

        // Validate we have all required values
        if (EndpointText = '') or (ModelText = '') then
            ThrowNotConfiguredError();

        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", EndpointText, ModelText, APIKeySecret);
    end;

    local procedure ThrowNotConfiguredError()
    var
        NotConfiguredErrorInfo: ErrorInfo;
        ErrorTitleLbl: Label 'Data Explorer Not Configured';
        ErrorMessageLbl: Label 'Data Explorer requires Azure OpenAI configuration to function. Please configure the endpoint, model, and API key in the setup page.';
        OpenSetupActionLbl: Label 'Open Data Explorer Setup';
        OpenSetupActionTooltipLbl: Label 'Opens the Data Explorer Setup page to configure Azure OpenAI settings';
    begin
        NotConfiguredErrorInfo.ErrorType(ErrorType::Client);
        NotConfiguredErrorInfo.Verbosity(Verbosity::Error);
        NotConfiguredErrorInfo.Title(ErrorTitleLbl);
        NotConfiguredErrorInfo.Message(ErrorMessageLbl);
        NotConfiguredErrorInfo.AddAction(OpenSetupActionLbl, Codeunit::"Data Explorer Error Handler", 'OpenDataExplorerSetup', OpenSetupActionTooltipLbl);
        Error(NotConfiguredErrorInfo);
    end;


    local procedure HandleAOAIError()
    var
        ErrorText: Text;
    begin
        ErrorText := AOAIOperationResponse.GetError();
        if ErrorText = '' then
            ErrorText := 'An error occurred while calling Azure OpenAI.';

        // Log error for debugging but don't throw error to maintain user experience
        Message('AI Generation Error: %1', ErrorText);
    end;

}