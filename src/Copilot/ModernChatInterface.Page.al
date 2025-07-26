page 51398 "Modern Chat Interface"
{
    Caption = 'Data Explorer - Modern Chat';
    PageType = UserControlHost;
    ApplicationArea = All;
    UsageCategory = Tasks;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            usercontrol(ChatControl; "Chat Interface")
            {
                ApplicationArea = All;

                trigger AddInReady()
                begin
                    InitializeChatInterface();
                end;

                trigger MessageSent(message: Text)
                begin
                    ProcessUserMessage(message);
                end;

                trigger ChatCleared()
                begin
                    ClearChatHistory();
                end;
            }
        }
    }

    var
        ChatHistoryMgr: Codeunit "Chat History Manager";
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        SessionId: Guid;
        IsInitialized: Boolean;
        IsInterfaceReady: Boolean;

    local procedure InitializeChatInterface()
    begin
        // Initialize session ID
        SessionId := CreateGuid();

        // Initialize the JSON-based chat history
        ChatHistoryMgr.InitializeSession(SessionId);

        // Initialize AI
        InitializeAI();

        IsInterfaceReady := true;

        // Add initial welcome message
        AddChatMessage('System', 'Welcome to the Modern Data Explorer! Ask me anything about your Business Central data.', CurrentDateTime);
    end;

    local procedure ProcessUserMessage(UserMessage: Text)
    var
        AIResponse: Text;
    begin
        if UserMessage = '' then
            exit;

        // Add user message to chat history
        AddChatMessage('User', UserMessage, CurrentDateTime);

        // Show typing indicator
        if IsInterfaceReady then
            CurrPage.ChatControl.ShowTypingIndicator(true);

        // Get AI response
        if GetAIResponse(UserMessage, AIResponse) then
            AddChatMessage('Assistant', AIResponse, CurrentDateTime)
        else
            AddChatMessage('System', 'Error getting AI response. Please try again.', CurrentDateTime);
    end;

    local procedure ClearChatHistory()
    begin
        // Clear the JSON-based chat history
        ChatHistoryMgr.ClearSession(SessionId);

        // Clear messages in the control add-in
        if IsInterfaceReady then
            CurrPage.ChatControl.ClearMessages();

        // Add welcome message
        AddChatMessage('System', 'Chat cleared. How can I help you explore your Business Central data?', CurrentDateTime);
    end;

    local procedure AddChatMessage(MessageType: Text[20]; MessageText: Text; MessageDateTime: DateTime)
    var
        FormattedTime: Text;
    begin
        // Add message to JSON-based chat history
        ChatHistoryMgr.AddMessage(SessionId, MessageType, MessageText, MessageDateTime);

        // Format time for display
        FormattedTime := Format(MessageDateTime, 0, '<Hours24,2>:<Minutes,2>');

        // Add message to the control add-in
        if IsInterfaceReady then
            CurrPage.ChatControl.AddMessage(MessageType, MessageText, FormattedTime);
    end;

    local procedure InitializeAI()
    begin
        if IsInitialized then
            exit;

        if InitializeAIConnection() then begin
            SetupChatParameters();
            InitializeSystemMessage();
            IsInitialized := true;
        end;
    end;

    local procedure InitializeAIConnection(): Boolean
    begin
        // Set the copilot capability for the generation
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Data Explorer Preview");
        // Use Business Central managed AI resources
        SetAuthorization();
        exit(true);
    end;

    [NonDebuggable]
    local procedure SetAuthorization()
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
        APIKeySecret := DataExplorerSecretMgt.GetAPIKey();

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

    local procedure SetupChatParameters()
    begin
        AOAIChatCompletionParams.SetMaxTokens(1000);
        AOAIChatCompletionParams.SetTemperature(0.7);
        AOAIChatCompletionParams.SetPresencePenalty(0.0);
        AOAIChatCompletionParams.SetFrequencyPenalty(0.0);
    end;

    local procedure InitializeSystemMessage()
    begin
        AOAIChatMessages.AddSystemMessage(
            'You are a helpful AI assistant for Microsoft Dynamics 365 Business Central. ' +
            'You can help users understand Business Central functionality, answer questions about data, ' +
            'and provide guidance on using the system. Keep your responses concise but informative. ' +
            'Remember the conversation context and refer back to previous messages when relevant. ' +
            '' +
            'IMPORTANT: Format your responses using HTML tags directly. Do NOT use markdown. Use this HTML structure:' +
            '' +
            '- For headings: <h3>Section Title</h3>, <h4>Subsection</h4>' +
            '- For paragraphs: <p>Your paragraph text here</p>' +
            '- For bold text: <strong>important text</strong>' +
            '- For italic text: <em>emphasized text</em>' +
            '- For lists: <ul><li>Item 1</li><li>Item 2</li></ul>' +
            '- For numbered lists: <ol><li>First item</li><li>Second item</li></ol>' +
            '- For line breaks: <br/>' +
            '- For code: <code>inline code</code>' +
            '' +
            'Always respond with properly formatted HTML. Keep responses conversational and helpful.'
        );
    end;

    local procedure GetAIResponse(UserMessage: Text; var Response: Text): Boolean
    begin
        if not IsInitialized then
            exit(false);

        // Rebuild complete conversation context before each API call
        RebuildConversationContext();
        AOAIChatMessages.AddUserMessage(UserMessage);

        RegisterFunctions();

        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);

        if AOAIOperationResponse.IsSuccess() then begin
            Response := AOAIChatMessages.GetLastMessage();
            exit(true);
        end else
            exit(false);
    end;

    local procedure RebuildConversationContext()
    var
        JsonMessages: JsonArray;
        MessageToken: JsonToken;
        MessageObj: JsonObject;
        MessageTypeToken: JsonToken;
        MessageTextToken: JsonToken;
        MessageType: Text;
        MessageText: Text;
    begin
        // Clear existing conversation context
        Clear(AOAIChatMessages);

        // Add system message first
        InitializeSystemMessage();

        // Get messages from JSON history and rebuild conversation context
        JsonMessages := ChatHistoryMgr.GetSessionMessages(SessionId);

        foreach MessageToken in JsonMessages do begin
            MessageObj := MessageToken.AsObject();

            if MessageObj.Get('messageType', MessageTypeToken) then
                MessageType := MessageTypeToken.AsValue().AsText();

            if MessageObj.Get('messageText', MessageTextToken) then
                MessageText := MessageTextToken.AsValue().AsText();

            case MessageType of
                'User':
                    AOAIChatMessages.AddUserMessage(MessageText);
                'Assistant':
                    AOAIChatMessages.AddAssistantMessage(MessageText);
            // Skip 'System' messages as the initial system message is already added
            end;
        end;
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
}
