table 51399 "Copilot Chat Buffer"
{
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Session ID"; Guid)
        {
            Caption = 'Session ID';
        }
        field(3; "Message Type"; Text[20])
        {
            Caption = 'Message Type';
        }
        field(4; "Message Text"; Text[2048])
        {
            Caption = 'Message Text';
        }
        field(5; "Message DateTime"; DateTime)
        {
            Caption = 'Message Date Time';
        }
        field(6; "Message Content"; Blob)
        {
            Caption = 'Message Content';
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Session; "Session ID", "Message DateTime")
        {
        }
    }

    procedure SetMessageContent(MessageText: Text)
    var
        OutStream: OutStream;
    begin
        "Message Content".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(MessageText);

        // Also set the legacy field with truncated content for backward compatibility
        "Message Text" := CopyStr(MessageText, 1, MaxStrLen("Message Text"));
    end;

    procedure GetMessageContent(): Text
    var
        InStream: InStream;
        MessageText: Text;
    begin
        if not "Message Content".HasValue() then begin
            // Fallback to legacy field if blob is empty
            if "Message Text" <> '' then
                exit("Message Text");
            exit('[DEBUG: No content in either field]');
        end;

        "Message Content".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(MessageText);

        if MessageText = '' then
            exit('[DEBUG: Blob exists but content is empty]');

        exit(MessageText);
    end;

    procedure CopyMessageContentTo(var TargetRecord: Record "Copilot Chat Buffer" temporary)
    begin
        // Copy all fields
        TargetRecord."Entry No." := "Entry No.";
        TargetRecord."Session ID" := "Session ID";
        TargetRecord."Message Type" := "Message Type";
        TargetRecord."Message Text" := "Message Text";
        TargetRecord."Message DateTime" := "Message DateTime";
        TargetRecord."Message Content" := "Message Content";
    end;
}
