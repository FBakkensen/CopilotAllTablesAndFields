page 51397 "Multi-Chat HTML History"
{
    Caption = 'Chat History';
    PageType = CardPart;
    SourceTable = "Copilot Chat Buffer";
    SourceTableTemporary = true;
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
        TempChatBuffer: Record "Copilot Chat Buffer" temporary;
        ChatBubbleGenerator: Codeunit "Chat Bubble HTML Generator";
        CurrentSessionId: Guid;
        ChatDataLoaded: Boolean;
        IsControlAddInReady: Boolean;

    procedure LoadData(var SourceChatBuffer: Record "Copilot Chat Buffer" temporary; FilterSessionId: Guid)
    begin
        // Copy the source data to our temporary buffer
        TempChatBuffer.Reset();
        TempChatBuffer.DeleteAll();

        if SourceChatBuffer.FindSet() then
            repeat
                TempChatBuffer.Init();
                TempChatBuffer."Entry No." := SourceChatBuffer."Entry No.";
                TempChatBuffer."Session ID" := SourceChatBuffer."Session ID";
                TempChatBuffer."Message Type" := SourceChatBuffer."Message Type";
                TempChatBuffer."Message Text" := SourceChatBuffer."Message Text";
                TempChatBuffer."Message DateTime" := SourceChatBuffer."Message DateTime";
                TempChatBuffer."Message Content" := SourceChatBuffer."Message Content"; // Copy blob field explicitly
                TempChatBuffer.Insert();
            until SourceChatBuffer.Next() = 0;

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

        HTMLContent := ChatBubbleGenerator.GenerateChatHTML(TempChatBuffer, CurrentSessionId);
        CurrPage.HTMLViewer.SetContent(HTMLContent);
    end;

    procedure RefreshDisplay()
    begin
        UpdateHTMLDisplay();
    end;
}
