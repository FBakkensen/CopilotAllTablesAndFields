page 51398 "Multi-Chat History SubPage"
{
    Caption = 'Chat History';
    PageType = ListPart;
    SourceTable = "Copilot Chat Buffer";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(ChatMessages)
            {
                field("Message Type"; Rec."Message Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of message (User, Assistant, or System)';
                    Width = 10;

                    trigger OnDrillDown()
                    begin
                        Message(Rec."Message Text");
                    end;
                }
                field("Message Text"; Rec."Message Text")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the content of the message';
                    Width = 70;
                    MultiLine = true;

                    trigger OnDrillDown()
                    begin
                        Message(Rec."Message Text");
                    end;
                }
                field("Message DateTime"; Rec."Message DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the message was sent';
                    Width = 20;
                }
            }
        }
    }

    procedure LoadData(var SourceChatBuffer: Record "Copilot Chat Buffer" temporary; FilterSessionId: Guid)
    begin
        Rec.Copy(SourceChatBuffer, true);
        Rec.SetRange("Session ID", FilterSessionId);
        CurrPage.Update(false);
    end;
}
