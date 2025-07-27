page 51302 "Data Explorer Secret Input"
{
    PageType = StandardDialog;
    Caption = 'Enter Secret Value';

    layout
    {
        area(Content)
        {
            group(General)
            {
                ShowCaption = false;
                field(SecretValue; SecretValue)
                {
                    ApplicationArea = All;
                    Caption = 'Value';
                    ToolTip = 'Enter the secret value';
                    ExtendedDatatype = Masked;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                    end;
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::OK then
            exit(SecretValue <> '');
        exit(true);
    end;

    trigger OnOpenPage()
    begin
    end;

    var
        SecretValue: Text;

    procedure GetSecretValue(): Text
    begin
        exit(SecretValue);
    end;

    procedure SetSecretValue(Value: Text)
    begin
        SecretValue := Value;
    end;
}