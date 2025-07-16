page 51300 "Data Explorer Prompt"
{
    PageType = PromptDialog;
    PromptMode = Prompt;
    Caption = 'Data Explorer with Copilot';
    DataCaptionExpression = '';
    ApplicationArea = All;
    UsageCategory = Tasks;
    Extensible = false;
    SourceTable = "Generation Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(Prompt)
        {
            field(UserPromptField; UserPrompt)
            {
                ApplicationArea = All;
                Caption = 'Ask about Business Central data';
                ShowCaption = false;
                MultiLine = true;
                InstructionalText = 'Ask questions like "Show me all customers from Seattle" or "What fields are in the Item table?"';

                trigger OnValidate()
                begin
                    CurrPage.Update();
                end;
            }
        }
        area(Content)
        {
            group(ResponseGroup)
            {
                ShowCaption = false;

                usercontrol(HTMLViewer; WebPageViewer)
                {
                    ApplicationArea = All;

                    trigger ControlAddInReady(callbackUrl: Text)
                    begin
                        CurrPage.HTMLViewer.Navigate('about:blank');
                        if ResponseReceived then
                            UpdateHTMLContent();
                    end;
                }
            }
        }
    }

    actions
    {
        area(SystemActions)
        {
            systemaction(Generate)
            {
                Caption = 'Generate';
                ToolTip = 'Process your data exploration request with Copilot';

                trigger OnAction()
                begin
                    ProcessUserPrompt();
                end;
            }
            systemaction(Regenerate)
            {
                Caption = 'Regenerate';
                ToolTip = 'Regenerate the response';

                trigger OnAction()
                begin
                    ProcessUserPrompt();
                end;
            }
            systemaction(Cancel)
            {
                Caption = 'Cancel';
                ToolTip = 'Cancel the operation';
            }
            systemaction(Ok)
            {
                Caption = 'Keep it';
                ToolTip = 'Accept the current results';
            }
        }
        area(PromptGuide)
        {
            action(ShowAllTables)
            {
                ApplicationArea = All;
                Caption = 'Show all tables';
                ToolTip = 'List all accessible tables';

                trigger OnAction()
                begin
                    UserPrompt := 'Show me all tables I can access';
                end;
            }
            action(ShowCustomerFields)
            {
                ApplicationArea = All;
                Caption = 'Customer fields';
                ToolTip = 'Show fields in the Customer table';

                trigger OnAction()
                begin
                    UserPrompt := 'What fields are available in the Customer table?';
                end;
            }
            action(ShowRecentSales)
            {
                ApplicationArea = All;
                Caption = 'Recent sales orders in yaml';
                ToolTip = @'Show me sales orders from the last 30 days in yml.';

                trigger OnAction()
                begin
                    UserPrompt := @'Show me sales orders from the last 30 days

make a proper yaml formatting of the result';
                end;
            }
            action(ShowInventoryItems)
            {
                ApplicationArea = All;
                Caption = 'Show Customers and Contacts';
                ToolTip = 'Show customers and their contacts, only for customers with contacts';

                trigger OnAction()
                begin
                    UserPrompt := @'show me a list of customers, show the name, address and phone, include their contacts.

First show one line with the customer and the indented lines with contacts

Only include customers with contacts.

Do not output any error messages or verbose information, only customers and contacts';
                end;
            }
            action(ShowItemCategories)
            {
                ApplicationArea = All;
                Caption = 'Item categories in JSON';
                ToolTip = 'Show all item categories formatted as JSON';

                trigger OnAction()
                begin
                    UserPrompt := @'Show me all item categories in JSON format.

Include the code, description, and parent category for each item category.

Format the output as proper JSON with proper indentation and structure.';
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        CheckCapabilityEnabled();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if ResponseHTML = Rec.GetResponseText() then
            exit; // No change in response, skip processing
        UserPrompt := Rec.GetInputText();
        ResponseHTML := Rec.GetResponseText();
        UpdateHTMLContent();
    end;

    var
        UserPrompt: Text;
        ResponseHTML: Text;
        ResponseReceived: Boolean;
        NoCapabilityErr: Label 'The Data Explorer capability is not enabled. Please contact your administrator.';
        ProcessingErr: Label 'An error occurred while processing your request: %1', Comment = '%1 = Error message details';
        ErrorFormatTxt: Label '<p style="color: red;">%1</p>', Locked = true;

    local procedure CheckCapabilityEnabled()
    var
        CopilotCapability: Codeunit "Copilot Capability";
    begin
        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Data Explorer Preview") then
            Error(NoCapabilityErr);
    end;

    local procedure ProcessUserPrompt()
    var
        DataExplorerCapability: Codeunit "Data Explorer Capability";
        Intent: Text;
        Response: Text;
        Success: Boolean;
    begin
        if UserPrompt = '' then
            exit;

        Intent := UserPrompt;

        Success := DataExplorerCapability.GenerateCompletions(Intent, Response);

        if Success then begin
            ResponseHTML := Response;
            ResponseReceived := true;
            Rec."Generation ID" += 1;
            Rec.SetInputText(UserPrompt);
            Rec.SetResponseText(ResponseHTML);
            Rec.ResponseGenerated := true;
            Rec.Insert();
        end else begin
            ResponseHTML := StrSubstNo(ErrorFormatTxt, StrSubstNo(ProcessingErr, GetLastErrorText()));
            ResponseReceived := true;
        end;

        UpdateHTMLContent();
    end;

    local procedure UpdateHTMLContent()
    begin
        CurrPage.HTMLViewer.SetContent(ResponseHTML);
    end;
}