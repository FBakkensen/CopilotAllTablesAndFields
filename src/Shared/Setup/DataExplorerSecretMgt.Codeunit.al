codeunit 51304 "Data Explorer Secret Mgt."
{
    Access = Internal;

    [NonDebuggable]
    procedure SetAPIKey(APIKeyText: Text)
    var
        DataExplorerSetup: Record "Data Explorer Setup";
        NewGuid: Guid;
    begin
        DataExplorerSetup.GetRecordOnce();

        // If there's an existing key, delete it from isolated storage
        if DataExplorerSetup.IsAPIKeySet() then
            IsolatedStorage.Delete(Format(DataExplorerSetup."API Key ID"), DataScope::Module);

        // Generate new GUID for this secret
        NewGuid := CreateGuid();
        DataExplorerSetup."API Key ID" := NewGuid;
        DataExplorerSetup.Modify();

        // Store the secret in isolated storage
        IsolatedStorage.Set(Format(NewGuid), APIKeyText, DataScope::Module);
    end;

    [NonDebuggable]
    procedure SetEndpoint(EndpointText: Text)
    var
        DataExplorerSetup: Record "Data Explorer Setup";
        NewGuid: Guid;
    begin
        DataExplorerSetup.GetRecordOnce();

        // If there's an existing endpoint, delete it from isolated storage
        if DataExplorerSetup.IsEndpointSet() then
            IsolatedStorage.Delete(Format(DataExplorerSetup."Endpoint ID"), DataScope::Module);

        // Generate new GUID for this secret
        NewGuid := CreateGuid();
        DataExplorerSetup."Endpoint ID" := NewGuid;
        DataExplorerSetup.Modify();

        // Store the secret in isolated storage
        IsolatedStorage.Set(Format(NewGuid), EndpointText, DataScope::Module);
    end;

    [NonDebuggable]
    procedure SetModel(ModelText: Text)
    var
        DataExplorerSetup: Record "Data Explorer Setup";
        NewGuid: Guid;
    begin
        DataExplorerSetup.GetRecordOnce();

        // If there's an existing model, delete it from isolated storage
        if DataExplorerSetup.IsModelSet() then
            IsolatedStorage.Delete(Format(DataExplorerSetup."Model ID"), DataScope::Module);

        // Generate new GUID for this secret
        NewGuid := CreateGuid();
        DataExplorerSetup."Model ID" := NewGuid;
        DataExplorerSetup.Modify();

        // Store the secret in isolated storage
        IsolatedStorage.Set(Format(NewGuid), ModelText, DataScope::Module);
    end;

    [NonDebuggable]
    procedure GetAPIKey(): SecretText
    var
        DataExplorerSetup: Record "Data Explorer Setup";
        APIKeySecret: SecretText;
        EmptySecret: SecretText;
    begin
        DataExplorerSetup.GetRecordOnce();

        if not DataExplorerSetup.IsAPIKeySet() then
            exit(EmptySecret);

        if not IsolatedStorage.Get(Format(DataExplorerSetup."API Key ID"), DataScope::Module, APIKeySecret) then
            exit(EmptySecret);

        exit(APIKeySecret);
    end;

    [NonDebuggable]
    procedure GetEndpoint(): SecretText
    var
        DataExplorerSetup: Record "Data Explorer Setup";
        EndpointSecret: SecretText;
        EmptySecret: SecretText;
    begin
        DataExplorerSetup.GetRecordOnce();

        if not DataExplorerSetup.IsEndpointSet() then
            exit(EmptySecret);

        if not IsolatedStorage.Get(Format(DataExplorerSetup."Endpoint ID"), DataScope::Module, EndpointSecret) then
            exit(EmptySecret);

        exit(EndpointSecret);
    end;

    [NonDebuggable]
    procedure GetModel(): SecretText
    var
        DataExplorerSetup: Record "Data Explorer Setup";
        ModelSecret: SecretText;
        EmptySecret: SecretText;
    begin
        DataExplorerSetup.GetRecordOnce();

        if not DataExplorerSetup.IsModelSet() then
            exit(EmptySecret);

        if not IsolatedStorage.Get(Format(DataExplorerSetup."Model ID"), DataScope::Module, ModelSecret) then
            exit(EmptySecret);

        exit(ModelSecret);
    end;

    [NonDebuggable]
    procedure ClearAPIKey()
    var
        DataExplorerSetup: Record "Data Explorer Setup";
    begin
        DataExplorerSetup.GetRecordOnce();

        if DataExplorerSetup.IsAPIKeySet() then begin
            IsolatedStorage.Delete(Format(DataExplorerSetup."API Key ID"), DataScope::Module);
            Clear(DataExplorerSetup."API Key ID");
            DataExplorerSetup.Modify();
        end;
    end;

    [NonDebuggable]
    procedure ClearEndpoint()
    var
        DataExplorerSetup: Record "Data Explorer Setup";
    begin
        DataExplorerSetup.GetRecordOnce();

        if DataExplorerSetup.IsEndpointSet() then begin
            IsolatedStorage.Delete(Format(DataExplorerSetup."Endpoint ID"), DataScope::Module);
            Clear(DataExplorerSetup."Endpoint ID");
            DataExplorerSetup.Modify();
        end;
    end;

    [NonDebuggable]
    procedure ClearModel()
    var
        DataExplorerSetup: Record "Data Explorer Setup";
    begin
        DataExplorerSetup.GetRecordOnce();

        if DataExplorerSetup.IsModelSet() then begin
            IsolatedStorage.Delete(Format(DataExplorerSetup."Model ID"), DataScope::Module);
            Clear(DataExplorerSetup."Model ID");
            DataExplorerSetup.Modify();
        end;
    end;

    procedure IsConfigured(): Boolean
    var
        DataExplorerSetup: Record "Data Explorer Setup";
    begin
        DataExplorerSetup.GetRecordOnce();
        exit(DataExplorerSetup.IsFullyConfigured());
    end;

    [NonDebuggable]
    procedure GetAPIKeyAsText(): Text
    var
        DataExplorerSetup: Record "Data Explorer Setup";
        ResultText: Text;
    begin
        DataExplorerSetup.GetRecordOnce();

        if not DataExplorerSetup.IsAPIKeySet() then
            exit('');

        if not IsolatedStorage.Get(Format(DataExplorerSetup."API Key ID"), DataScope::Module, ResultText) then
            exit('');

        exit(ResultText);
    end;

    [NonDebuggable]
    procedure GetEndpointAsText(): Text
    var
        DataExplorerSetup: Record "Data Explorer Setup";
        ResultText: Text;
    begin
        DataExplorerSetup.GetRecordOnce();

        if not DataExplorerSetup.IsEndpointSet() then
            exit('');

        if not IsolatedStorage.Get(Format(DataExplorerSetup."Endpoint ID"), DataScope::Module, ResultText) then
            exit('');

        exit(ResultText);
    end;

    [NonDebuggable]
    procedure GetModelAsText(): Text
    var
        DataExplorerSetup: Record "Data Explorer Setup";
        ResultText: Text;
    begin
        DataExplorerSetup.GetRecordOnce();

        if not DataExplorerSetup.IsModelSet() then
            exit('');

        if not IsolatedStorage.Get(Format(DataExplorerSetup."Model ID"), DataScope::Module, ResultText) then
            exit('');

        exit(ResultText);
    end;
}