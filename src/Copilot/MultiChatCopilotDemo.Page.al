page 51399 "Multi-Chat Copilot Demo"
{
    Caption = 'Multi-Chat Copilot Demo (POC)';
    PageType = PromptDialog;
    Extensible = false;
    SourceTable = "Copilot Chat Buffer";
    SourceTableTemporary = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Prompt)
        {
            field(UserInput; UserInputText)
            {
                ApplicationArea = All;
                Caption = 'Ask me anything about Business Central';
                InstructionalText = 'Type your question here. Press Ctrl+Enter or click Send Message to send. I can remember our conversation context.';
                MultiLine = true;
                ShowCaption = false;
            }
        }
        area(Content)
        {
            part(ChatHistory; "Multi-Chat HTML History")
            {
                ApplicationArea = All;
                Caption = 'Conversation History';
                SubPageLink = "Session ID" = field("Session ID");
            }
        }
    }

    actions
    {
        area(SystemActions)
        {
            systemaction(Generate)
            {
                Caption = 'Send Message';
                ToolTip = 'Send your message and get AI response';

                trigger OnAction()
                begin
                    ProcessUserInput();
                end;
            }
            systemaction(Ok)
            {
                Caption = 'Clear Chat';
                ToolTip = 'Clear the conversation history and start fresh';
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::OK then
            ClearConversation();
        exit(true);
    end;

    trigger OnInit()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec."Session ID" := CreateGuid();
            Rec.Insert();
        end;
        InitializeAI();
    end;

    var
        TempChatBuffer: Record "Copilot Chat Buffer" temporary;
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        ConversationHistory: List of [Text];
        UserInputText: Text;
        ErrorText: Text;
        SessionId: Guid;
        DemoApiKey: SecretText;
        IsInitialized: Boolean;
        ResponseTimeMsg: Label ' [Response time: %1ms]', Comment = '%1 = Response time in milliseconds';
        AIAPIErrorMsg: Label 'AI API Error: %1', Comment = '%1 = Error message from AI API';
        ConversationFormatMsg: Label '%1: %2', Comment = '%1 = Message type (User/Assistant/System), %2 = Message content';

    local procedure InitializeAI()
    var
        TempSecretText: Text;
    begin
        if IsInitialized then
            exit;

        TempSecretText := 'demo-key';
        DemoApiKey := TempSecretText;

        if InitializeAIConnection() then begin
            SetupChatParameters();
            InitializeSystemMessage();
            SessionId := Rec."Session ID";
            IsInitialized := true;
            AddChatMessage('System', 'AI Assistant initialized. How can I help you with Business Central today?', CurrentDateTime);
        end else
            AddChatMessage('System', 'Error: ' + ErrorText, CurrentDateTime);
    end;

    local procedure InitializeAIConnection(): Boolean
    begin
        // Set the copilot capability for the generation - this links the AI call to our registered capability
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Data Explorer Preview");
        // Use Business Central managed AI resources (recommended for production)
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
            '- For headings: <h1>Main Title</h1>, <h2>Section Title</h2>, <h3>Subsection</h3>' +
            '- For paragraphs: <p>Your paragraph text here</p>' +
            '- For bold text: <strong>important text</strong>' +
            '- For italic text: <em>emphasized text</em>' +
            '- For lists: <ul><li>Item 1</li><li>Item 2</li></ul>' +
            '- For numbered lists: <ol><li>First item</li><li>Second item</li></ol>' +
            '- For line breaks: <br/>' +
            '' +
            'Example response format:' +
            '<h1>What is Business Central?</h1>' +
            '<p><strong>Microsoft Dynamics 365 Business Central</strong> is an integrated enterprise resource planning (ERP) solution.</p>' +
            '<h2>Key Features</h2>' +
            '<ul><li>Financial Management</li><li>Sales and Service</li><li>Operations Management</li></ul>' +
            '' +
            'Always respond with properly formatted HTML. Do not include response time or technical metadata.'
        );
    end;

    local procedure ProcessUserInput()
    var
        UserMessage: Text;
        AIResponse: Text;
    begin
        if UserInputText = '' then
            exit;

        UserMessage := UserInputText;
        UserInputText := ''; // Clear input field

        // Add user message to conversation buffer
        AddChatMessage('User', UserMessage, CurrentDateTime);

        // Get AI response with full conversation context
        if GetAIResponse(UserMessage, AIResponse) then begin
            AIResponse := RemoveResponseTime(AIResponse);
            // Add formatted HTML response
            AddChatMessage('Assistant', AIResponse, CurrentDateTime);
        end else
            AddChatMessage('System', 'Error getting AI response: ' + ErrorText, CurrentDateTime);

        CurrPage.Update();
    end;

    local procedure GetAIResponse(UserMessage: Text; var Response: Text): Boolean
    var
        StartTime: DateTime;
        ElapsedMs: Integer;
    begin
        if not IsInitialized then begin
            ErrorText := 'AI not initialized';
            exit(false);
        end;

        StartTime := CurrentDateTime;

        // Rebuild complete conversation context before each API call
        RebuildConversationContext();
        AOAIChatMessages.AddUserMessage(UserMessage);

        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);

        if AOAIOperationResponse.IsSuccess() then begin
            Response := AOAIChatMessages.GetLastMessage();
            ElapsedMs := CurrentDateTime - StartTime;

            // Add timing info for demo purposes
            if ElapsedMs > 1000 then
                Response += StrSubstNo(ResponseTimeMsg, ElapsedMs);

            exit(true);
        end else begin
            ErrorText := StrSubstNo(AIAPIErrorMsg, AOAIOperationResponse.GetError());
            exit(false);
        end;
    end;

    local procedure RebuildConversationContext()
    var
        TempLocalChatBuffer: Record "Copilot Chat Buffer" temporary;
    begin
        // Clear existing conversation context
        Clear(AOAIChatMessages);

        // Add system message first
        InitializeSystemMessage();

        // Copy from TempChatBuffer and sort by datetime to ensure proper order
        TempLocalChatBuffer.Copy(TempChatBuffer, true);
        TempLocalChatBuffer.SetCurrentKey("Session ID", "Message DateTime");
        TempLocalChatBuffer.SetRange("Session ID", SessionId);

        // Rebuild conversation from chat buffer (excluding system messages)
        if TempLocalChatBuffer.FindSet() then
            repeat
                case TempLocalChatBuffer."Message Type" of
                    'User':
                        AOAIChatMessages.AddUserMessage(TempLocalChatBuffer.GetMessageContent());
                    'Assistant':
                        AOAIChatMessages.AddAssistantMessage(TempLocalChatBuffer.GetMessageContent());
                // Skip 'System' messages as the initial system message is already added
                end;
            until TempLocalChatBuffer.Next() = 0;
    end;

    local procedure AddChatMessage(MessageType: Text[20]; MessageText: Text; MessageDateTime: DateTime)
    begin
        TempChatBuffer.Init();
        TempChatBuffer."Entry No." += 1;
        TempChatBuffer."Session ID" := SessionId;
        TempChatBuffer."Message Type" := MessageType;
        TempChatBuffer.SetMessageContent(MessageText); // Use new blob-based method
        TempChatBuffer."Message DateTime" := MessageDateTime;
        TempChatBuffer.Insert();

        // Keep conversation history for context (last 20 messages to manage token limits)
        ConversationHistory.Add(StrSubstNo(ConversationFormatMsg, MessageType, MessageText));
        if ConversationHistory.Count > 20 then
            ConversationHistory.RemoveAt(1);

        // Update the subpage with new data
        CurrPage.ChatHistory.Page.LoadData(TempChatBuffer, SessionId);
    end;

    local procedure ClearConversation()
    begin
        TempChatBuffer.DeleteAll();
        ConversationHistory.RemoveRange(1, ConversationHistory.Count);
        Clear(AOAIChatMessages);
        UserInputText := '';

        // Reinitialize with system message
        InitializeSystemMessage();

        AddChatMessage('System', 'Conversation cleared. How can I help you?', CurrentDateTime);
        CurrPage.Update();
    end;

    local procedure RemoveResponseTime(Response: Text): Text
    var
        ResponseTimePos: Integer;
    begin
        ResponseTimePos := StrPos(Response, ' [Response time:');
        if ResponseTimePos > 0 then
            exit(CopyStr(Response, 1, ResponseTimePos - 1));
        exit(Response);
    end;
}
