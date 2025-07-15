codeunit 51302 "Get Fields Function" implements "AOAI Function"
{
    Access = Internal;

    var
        TableNotFoundErr: Label 'Table not found: %1', Comment = '%1 = Table identifier';
        InsufficientPermissionsErr: Label 'Insufficient permissions for table: %1', Comment = '%1 = Table identifier';
        TableFilterTxt: Label '@*%1*', Locked = true;
        ReturnedFieldsLbl: Label 'Returned %1 fields for %2 table', Comment = '%1 = Number of fields, %2 = Table name';
        FunctionCalledLbl: Label '%1 function called', Comment = '%1 = Function name';

    procedure GetName(): Text
    begin
        exit('get_fields');
    end;

    procedure GetPrompt(): JsonObject
    var
        FunctionPrompt: JsonObject;
        FunctionObj: JsonObject;
        Parameters: JsonObject;
        Properties: JsonObject;
        TableIdProp: JsonObject;
        IncludeFlowFieldsProp: JsonObject;
        Required: JsonArray;
    begin
        TableIdProp.Add('type', 'string');
        TableIdProp.Add('description', 'Table ID or Name to retrieve fields for');
        Properties.Add('table_identifier', TableIdProp);

        IncludeFlowFieldsProp.Add('type', 'boolean');
        IncludeFlowFieldsProp.Add('description', 'Include FlowFields in the result (default: false)');
        IncludeFlowFieldsProp.Add('default', false);
        Properties.Add('include_flowfields', IncludeFlowFieldsProp);

        Required.Add('table_identifier');

        Parameters.Add('type', 'object');
        Parameters.Add('properties', Properties);
        Parameters.Add('required', Required);

        FunctionObj.Add('name', GetName());
        FunctionObj.Add('description', 'Retrieves field metadata for a specified Business Central table');
        FunctionObj.Add('parameters', Parameters);

        FunctionPrompt.Add('type', 'function');
        FunctionPrompt.Add('function', FunctionObj);

        exit(FunctionPrompt);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        FieldRec: Record Field;
        TableMetadata: Record "Table Metadata";
        TablePermissionHelper: Codeunit "Table Permission Helper";
        Result: JsonObject;
        Fields: JsonArray;
        TableIdToken: JsonToken;
        IncludeFlowToken: JsonToken;
        TableIdentifier: Text;
        TableId: Integer;
        FieldCount: Integer;
        IncludeFlowFields: Boolean;
        StartTime: DateTime;
        CustomDimensions: Dictionary of [Text, Text];
        Success: Boolean;
        ResultSummary: Text;
    begin
        StartTime := CurrentDateTime();
        if not Arguments.Get('table_identifier', TableIdToken) then
            Error('table_identifier parameter is required');

        TableIdentifier := TableIdToken.AsValue().AsText();

        if Arguments.Get('include_flowfields', IncludeFlowToken) then
            IncludeFlowFields := IncludeFlowToken.AsValue().AsBoolean();

        if not TryResolveTableId(TableIdentifier, TableId) then begin
            Result.Add('error', StrSubstNo(TableNotFoundErr, TableIdentifier));
            Result.Add('fields', Fields);
            exit(Result);
        end;

        if not TablePermissionHelper.HasTablePermission(TableId) then begin
            Result.Add('error', StrSubstNo(InsufficientPermissionsErr, TableIdentifier));
            Result.Add('fields', Fields);
            exit(Result);
        end;

        TableMetadata.Get(TableId);
        Result.Add('tableId', TableId);
        Result.Add('tableName', TableMetadata.Name);
        Result.Add('tableCaption', TableMetadata.Caption);

        FieldRec.SetRange(TableNo, TableId);
        FieldRec.SetRange(Enabled, true);
        FieldRec.SetFilter(ObsoleteState, '<>%1', FieldRec.ObsoleteState::Removed);

        if not IncludeFlowFields then
            FieldRec.SetFilter(Class, '<>%1', FieldRec.Class::FlowField);

        if not FieldRec.FindSet() then begin
            Result.Add('fields', Fields);
            Result.Add('count', 0);
            Result.Add('message', 'No fields found for the specified table');
            exit(Result);
        end;

        repeat
            Fields.Add(CreateFieldObject(FieldRec));
            FieldCount += 1;
        until FieldRec.Next() = 0;

        Result.Add('fields', Fields);
        Result.Add('count', FieldCount);

        // Log telemetry
        Success := not Result.Contains('error');
        if Success then
            ResultSummary := StrSubstNo(ReturnedFieldsLbl, FieldCount, TableIdentifier)
        else
            ResultSummary := 'Failed to retrieve fields';

        Clear(CustomDimensions);
        CustomDimensions.Add('FunctionName', GetName());
        CustomDimensions.Add('Parameters', Format(Arguments));
        CustomDimensions.Add('Success', Format(Success));
        CustomDimensions.Add('ResultSummary', ResultSummary);
        CustomDimensions.Add('ExecutionTimeMs', Format(CurrentDateTime() - StartTime));

        Session.LogMessage('DEX-0002', StrSubstNo(FunctionCalledLbl, GetName()),
            Verbosity::Normal, DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher, CustomDimensions);

        exit(Result);
    end;

    [TryFunction]
    local procedure TryResolveTableId(TableIdentifier: Text; var TableId: Integer)
    var
        TableMetadata: Record "Table Metadata";
    begin
        TableId := 0;
        
        if Evaluate(TableId, TableIdentifier) then
            if TableMetadata.Get(TableId) then
                exit;

        TableMetadata.SetRange(Name, TableIdentifier);
        if TableMetadata.FindFirst() then begin
            TableId := TableMetadata.ID;
            exit;
        end;

        TableMetadata.Reset();
        TableMetadata.SetFilter(Caption, StrSubstNo(TableFilterTxt, TableIdentifier));
        if TableMetadata.FindFirst() then begin
            TableId := TableMetadata.ID;
            exit;
        end;

        Error('Table not found');
    end;



    local procedure CreateFieldObject(var FieldRec: Record Field): JsonObject
    var
        FieldObj: JsonObject;
        RelationInfo: JsonObject;
        ToolTip: Text;
        OptionCaption: Text;
    begin
        FieldObj.Add('id', FieldRec."No.");
        FieldObj.Add('name', FieldRec.FieldName);
        FieldObj.Add('caption', FieldRec."Field Caption");
        FieldObj.Add('type', Format(FieldRec.Type));
        FieldObj.Add('length', FieldRec.Len);
        FieldObj.Add('class', Format(FieldRec.Class));

        // Add tooltip if available
        if TryGetFieldToolTip(FieldRec.TableNo, FieldRec."No.", ToolTip) then
            if ToolTip <> '' then
                FieldObj.Add('toolTip', ToolTip);

        // Add option information
        if FieldRec.OptionString <> '' then begin
            FieldObj.Add('optionString', FieldRec.OptionString);
            
            if TryGetFieldOptionCaption(FieldRec.TableNo, FieldRec."No.", OptionCaption) then
                if OptionCaption <> '' then
                    FieldObj.Add('optionCaption', OptionCaption);
        end;

        // Add relation information with table caption
        if FieldRec.RelationTableNo <> 0 then begin
            RelationInfo.Add('tableId', FieldRec.RelationTableNo);
            RelationInfo.Add('fieldId', FieldRec.RelationFieldNo);
            TryAddRelatedTableCaption(FieldRec.RelationTableNo, RelationInfo);
            FieldObj.Add('relation', RelationInfo);
        end;

        FieldObj.Add('isPartOfPrimaryKey', IsPartOfPrimaryKey(FieldRec.TableNo, FieldRec."No."));
        
        // Add obsolete state if not blank
        if FieldRec.ObsoleteState <> FieldRec.ObsoleteState::No then
            FieldObj.Add('obsoleteState', Format(FieldRec.ObsoleteState));

        exit(FieldObj);
    end;


    local procedure IsPartOfPrimaryKey(TableNo: Integer; FieldNo: Integer): Boolean
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        i: Integer;
    begin
        RecRef.Open(TableNo);
        KeyRef := RecRef.KeyIndex(1);

        for i := 1 to KeyRef.FieldCount() do begin
            FieldRef := KeyRef.FieldIndex(i);
            if FieldRef.Number = FieldNo then
                exit(true);
        end;

        exit(false);
    end;

    [TryFunction]
    local procedure TryGetFieldToolTip(TableNo: Integer; FieldNo: Integer; var ToolTip: Text)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        ToolTip := '';
        RecRef.Open(TableNo);
        FieldRef := RecRef.Field(FieldNo);
        ToolTip := FieldRef.Caption(); // In BC, tooltip access requires page-level metadata
        RecRef.Close();
    end;

    [TryFunction]
    local procedure TryGetFieldOptionCaption(TableNo: Integer; FieldNo: Integer; var OptionCaption: Text)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        OptionCaption := '';
        RecRef.Open(TableNo);
        FieldRef := RecRef.Field(FieldNo);
        OptionCaption := FieldRef.OptionCaption();
        RecRef.Close();
    end;

    [TryFunction]
    local procedure TryAddRelatedTableCaption(TableNo: Integer; var RelationInfo: JsonObject)
    var
        TableMetadata: Record "Table Metadata";
    begin
        if TableMetadata.Get(TableNo) then
            RelationInfo.Add('tableCaption', TableMetadata.Caption);
    end;


}