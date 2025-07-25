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
}
