page 51301 "Data Explorer Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Data Explorer Setup";
    Caption = 'Data Explorer Setup';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Azure OpenAI Configuration';

                field(EndpointStatus; GetEndpointStatus())
                {
                    ApplicationArea = All;
                    Caption = 'Endpoint Status';
                    ToolTip = 'Shows whether the endpoint URL is configured';
                    Editable = false;
                    StyleExpr = EndpointStatusStyle;

                    trigger OnDrillDown()
                    begin
                        DoSetEndpoint();
                    end;
                }
                field(ModelStatus; GetModelStatus())
                {
                    ApplicationArea = All;
                    Caption = 'Model Status';
                    ToolTip = 'Shows whether the model is configured';
                    Editable = false;
                    StyleExpr = ModelStatusStyle;

                    trigger OnDrillDown()
                    begin
                        DoSetModel();
                    end;
                }
                field(APIKeyStatus; GetAPIKeyStatus())
                {
                    ApplicationArea = All;
                    Caption = 'API Key Status';
                    ToolTip = 'Shows whether the API key is configured';
                    Editable = false;
                    StyleExpr = APIKeyStatusStyle;

                    trigger OnDrillDown()
                    begin
                        DoSetAPIKey();
                    end;
                }
            }
            group(Instructions)
            {
                Caption = 'Setup Instructions';
                field(InstructionText; InstructionTxt)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    Editable = false;
                    ShowCaption = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetEndpoint)
            {
                ApplicationArea = All;
                Caption = 'Set Endpoint';
                ToolTip = 'Configure the Azure OpenAI endpoint URL';
                Image = Setup;

                trigger OnAction()
                begin
                    DoSetEndpoint();
                end;
            }
            action(SetModel)
            {
                ApplicationArea = All;
                Caption = 'Set Model';
                ToolTip = 'Configure the Azure OpenAI model/deployment name';
                Image = Setup;

                trigger OnAction()
                begin
                    DoSetModel();
                end;
            }
            action(SetAPIKey)
            {
                ApplicationArea = All;
                Caption = 'Set API Key';
                ToolTip = 'Configure the Azure OpenAI API key';
                Image = Setup;

                trigger OnAction()
                begin
                    DoSetAPIKey();
                end;
            }
            action(ClearAllSettings)
            {
                ApplicationArea = All;
                Caption = 'Clear All Settings';
                ToolTip = 'Remove all configured settings';
                Image = Delete;

                trigger OnAction()
                begin
                    if Confirm(ClearAllConfirmQst) then
                        DoClearAllSettings();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(SetEndpoint_Promoted; SetEndpoint)
                {
                }
                actionref(SetModel_Promoted; SetModel)
                {
                }
                actionref(SetAPIKey_Promoted; SetAPIKey)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetRecordOnce();
        UpdateStyles();
        InstructionTxt := GetInstructions();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateStyles();
    end;

    var
        EndpointStatusStyle: Text;
        ModelStatusStyle: Text;
        APIKeyStatusStyle: Text;
        InstructionTxt: Text;
        ConfiguredTxt: Label 'Configured';
        NotConfiguredTxt: Label 'Not Configured - Click to Set';
        ClearAllConfirmQst: Label 'This will remove all configured settings. Do you want to continue?';
        SettingsClearedMsg: Label 'All settings have been cleared.';

    local procedure GetInstructions(): Text
    var
        InstructionLbl: Label @'To use the Data Explorer with Copilot, you need to configure your Azure OpenAI connection:

1. Endpoint URL: Your Azure OpenAI resource endpoint (e.g., https://your-resource.openai.azure.com/)
2. Model: Your deployment name (e.g., gpt-4.1)
3. API Key: Your Azure OpenAI API key

Click on each field above or use the actions to configure these settings. All values are stored securely using Business Central''s isolated storage.';

    begin
        exit(InstructionLbl);
    end;

    local procedure GetEndpointStatus(): Text
    begin
        if Rec.IsEndpointSet() then
            exit(ConfiguredTxt)
        else
            exit(NotConfiguredTxt);
    end;

    local procedure GetModelStatus(): Text
    begin
        if Rec.IsModelSet() then
            exit(ConfiguredTxt)
        else
            exit(NotConfiguredTxt);
    end;

    local procedure GetAPIKeyStatus(): Text
    begin
        if Rec.IsAPIKeySet() then
            exit(ConfiguredTxt)
        else
            exit(NotConfiguredTxt);
    end;

    local procedure UpdateStyles()
    begin
        if Rec.IsEndpointSet() then
            EndpointStatusStyle := 'Favorable'
        else
            EndpointStatusStyle := 'Attention';

        if Rec.IsModelSet() then
            ModelStatusStyle := 'Favorable'
        else
            ModelStatusStyle := 'Attention';

        if Rec.IsAPIKeySet() then
            APIKeyStatusStyle := 'Favorable'
        else
            APIKeyStatusStyle := 'Attention';
    end;

    local procedure DoSetEndpoint()
    var
        DataExplorerSecretMgt: Codeunit "Data Explorer Secret Mgt.";
        SecretInputPage: Page "Data Explorer Secret Input";
        EndpointValue: Text;
    begin
        SecretInputPage.Caption := 'Enter Azure OpenAI Endpoint';
        if SecretInputPage.RunModal() = Action::OK then begin
            EndpointValue := SecretInputPage.GetSecretValue();
            if EndpointValue <> '' then begin
                DataExplorerSecretMgt.SetEndpoint(EndpointValue);
                // Reload the record to get the updated GUID values
                Rec.Get();
                UpdateStyles();
                CurrPage.Update(false);
            end;
        end;
    end;

    local procedure DoSetModel()
    var
        DataExplorerSecretMgt: Codeunit "Data Explorer Secret Mgt.";
        SecretInputPage: Page "Data Explorer Secret Input";
        ModelValue: Text;
    begin
        SecretInputPage.Caption := 'Enter Azure OpenAI Model';
        if SecretInputPage.RunModal() = Action::OK then begin
            ModelValue := SecretInputPage.GetSecretValue();
            if ModelValue <> '' then begin
                DataExplorerSecretMgt.SetModel(ModelValue);
                // Reload the record to get the updated GUID values
                Rec.Get();
                UpdateStyles();
                CurrPage.Update(false);
            end;
        end;
    end;

    local procedure DoSetAPIKey()
    var
        DataExplorerSecretMgt: Codeunit "Data Explorer Secret Mgt.";
        SecretInputPage: Page "Data Explorer Secret Input";
        APIKeyValue: Text;
    begin
        SecretInputPage.Caption := 'Enter Azure OpenAI API Key';
        if SecretInputPage.RunModal() = Action::OK then begin
            APIKeyValue := SecretInputPage.GetSecretValue();
            if APIKeyValue <> '' then begin
                DataExplorerSecretMgt.SetAPIKey(APIKeyValue);
                // Reload the record to get the updated GUID values
                Rec.Get();
                UpdateStyles();
                CurrPage.Update(false);
            end;
        end;
    end;

    local procedure DoClearAllSettings()
    var
        DataExplorerSecretMgt: Codeunit "Data Explorer Secret Mgt.";
    begin
        DataExplorerSecretMgt.ClearEndpoint();
        DataExplorerSecretMgt.ClearModel();
        DataExplorerSecretMgt.ClearAPIKey();
        // Reload the record to get the updated GUID values
        Rec.Get();
        UpdateStyles();
        CurrPage.Update(false);
        Message(SettingsClearedMsg);
    end;
}