table 51301 "Data Explorer Setup"
{
    Caption = 'Data Explorer Setup';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "API Key ID"; Guid)
        {
            Caption = 'API Key ID';
            DataClassification = SystemMetadata;
        }
        field(3; "Endpoint ID"; Guid)
        {
            Caption = 'Endpoint ID';
            DataClassification = SystemMetadata;
        }
        field(4; "Model ID"; Guid)
        {
            Caption = 'Model ID';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        TestField("Primary Key", '');
        "Primary Key" := '';
    end;

    procedure GetRecordOnce()
    begin
        if not Get() then begin
            Init();
            Insert();
        end;
    end;

    procedure IsAPIKeySet(): Boolean
    begin
        exit(not IsNullGuid("API Key ID"));
    end;

    procedure IsEndpointSet(): Boolean
    begin
        exit(not IsNullGuid("Endpoint ID"));
    end;

    procedure IsModelSet(): Boolean
    begin
        exit(not IsNullGuid("Model ID"));
    end;

    procedure IsFullyConfigured(): Boolean
    begin
        exit(IsAPIKeySet() and IsEndpointSet() and IsModelSet());
    end;
}