page 51397 "Multi-Chat HTML History"
{
    Caption = 'Chat History';
    PageType = CardPart;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(ChatDisplay)
            {
                ShowCaption = false;

                usercontrol(HTMLViewer; WebPageViewer)
                {
                    ApplicationArea = All;

                    trigger ControlAddInReady(callbackUrl: Text)
                    begin
                        CurrPage.HTMLViewer.Navigate('about:blank');
                        IsControlAddInReady := true;
                        if ChatDataLoaded then
                            UpdateHTMLDisplay();
                    end;

                    trigger DocumentReady()
                    begin
                        // Document is ready, can now safely set content
                    end;

                    trigger Callback(data: Text)
                    begin
                        // Handle any callbacks if needed
                    end;

                    trigger Refresh(callbackUrl: Text)
                    begin
                        if ChatDataLoaded then
                            UpdateHTMLDisplay();
                    end;
                }
            }
        }
    }

    var
        ChatHistoryMgr: Codeunit "Chat History Manager";
        ChatHistoryAdapter: Codeunit "Chat History Adapter";
        CurrentSessionId: Guid;
        ChatDataLoaded: Boolean;
        IsControlAddInReady: Boolean;

    /// <summary>
    /// Load data from a JSON-based chat history manager
    /// </summary>
    /// <param name="SourceChatHistoryMgr">Source chat history manager with data</param>
    /// <param name="FilterSessionId">Session ID to display</param>
    procedure LoadDataFromJson(var SourceChatHistoryMgr: Codeunit "Chat History Manager"; FilterSessionId: Guid)
    var
        JsonText: Text;
    begin
        // Import the complete history from source
        JsonText := SourceChatHistoryMgr.ExportToJson();
        ChatHistoryMgr.ImportFromJson(JsonText);

        CurrentSessionId := FilterSessionId;
        ChatDataLoaded := true;

        // Update the HTML display
        UpdateHTMLDisplay();
    end;

    local procedure UpdateHTMLDisplay()
    var
        HTMLContent: Text;
    begin
        if not ChatDataLoaded then
            exit;

        if not IsControlAddInReady then
            exit;

        // Generate HTML using the adapter
        HTMLContent := ChatHistoryAdapter.GenerateHTMLFromJson(ChatHistoryMgr, CurrentSessionId);
        CurrPage.HTMLViewer.SetContent(HTMLContent);
    end;

    procedure RefreshDisplay()
    begin
        UpdateHTMLDisplay();
    end;
}