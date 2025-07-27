codeunit 51301 "Get Tables Function" implements "AOAI Function"
{
    Access = Internal;

    var
        ReturnedTablesLbl: Label 'Returned %1 tables', Comment = '%1 = Number of tables';
        FunctionCalledLbl: Label '%1 function called', Comment = '%1 = Function name';
    procedure GetName(): Text
    begin
        exit('get_tables');
    end;

    procedure GetPrompt(): JsonObject
    var
        FunctionPrompt: JsonObject;
        FunctionObj: JsonObject;
        Parameters: JsonObject;
        Properties: JsonObject;
        FilterProp: JsonObject;
        FilterEnum: JsonArray;
        Required: JsonArray;
    begin
        FilterProp.Add('type', 'string');
        FilterProp.Add('description', 'Optional filter to limit table types');

        FilterEnum.Add('Normal');
        FilterEnum.Add('System');
        FilterEnum.Add('Virtual');
        FilterEnum.Add('All');
        FilterProp.Add('enum', FilterEnum);

        Properties.Add('filter', FilterProp);

        Parameters.Add('type', 'object');
        Parameters.Add('properties', Properties);
        Parameters.Add('required', Required);

        FunctionObj.Add('name', GetName());
        FunctionObj.Add('description', 'Retrieves a list of accessible Business Central tables with their metadata');
        FunctionObj.Add('parameters', Parameters);

        FunctionPrompt.Add('type', 'function');
        FunctionPrompt.Add('function', FunctionObj);

        exit(FunctionPrompt);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        TableMetadata: Record "Table Metadata";
        TablePermissionHelper: Codeunit "Table Permission Helper";
        Result: JsonObject;
        Tables: JsonArray;
        TableObj: JsonObject;
        FilterToken: JsonToken;
        FilterText: Text;
        ErrorMessage: Text;
        TableCount: Integer;
        HasPermission: Boolean;
        StartTime: DateTime;
        CustomDimensions: Dictionary of [Text, Text];
        Success: Boolean;
        ResultSummary: Text;
    begin
        StartTime := CurrentDateTime();
        TableMetadata.SetLoadFields(ID, Name, Caption, TableType, DataClassification, ObsoleteState);

        if Arguments.Get('filter', FilterToken) then begin
            FilterText := FilterToken.AsValue().AsText();
            if not TryApplyTableFilter(TableMetadata, FilterText) then begin
                ErrorMessage := GetLastErrorText();
                Result.Add('error', 'Filter application failed: ' + ErrorMessage);
                exit(Result);
            end;
        end;

        if not TableMetadata.FindSet() then begin
            Result.Add('tables', Tables);
            Result.Add('count', 0);
            Result.Add('message', 'No accessible tables found with the specified filter');
            exit(Result);
        end;

        repeat
            if TablePermissionHelper.TryHasTablePermission(TableMetadata.ID, HasPermission) then
                if HasPermission then
                    if TryCreateTableObject(TableMetadata, TableObj) then begin
                        Tables.Add(TableObj);
                        TableCount += 1;
                    end;
        until TableMetadata.Next() = 0;

        Result.Add('tables', Tables);
        Result.Add('count', TableCount);

        if TableCount = 0 then
            Result.Add('message', 'No tables found with sufficient permissions');

        // Log telemetry
        Success := not Result.Contains('error');
        if Success then
            ResultSummary := StrSubstNo(ReturnedTablesLbl, TableCount)
        else
            ResultSummary := 'Failed to retrieve tables';

        Clear(CustomDimensions);
        CustomDimensions.Add('FunctionName', GetName());
        CustomDimensions.Add('Parameters', Format(Arguments));
        CustomDimensions.Add('Success', Format(Success));
        CustomDimensions.Add('ResultSummary', ResultSummary);
        CustomDimensions.Add('ExecutionTimeMs', Format(CurrentDateTime() - StartTime));

        Session.LogMessage('DEX-0001', StrSubstNo(FunctionCalledLbl, GetName()),
            Verbosity::Normal, DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher, CustomDimensions);

        exit(Result);
    end;

    procedure ValidatePermissions(): Boolean
    begin
        exit(true);
    end;

    [TryFunction]
    local procedure TryApplyTableFilter(var TableMetadata: Record "Table Metadata"; FilterText: Text)
    begin
        case FilterText of
            'Normal':
                TableMetadata.SetRange(TableType, TableMetadata.TableType::Normal);
            'System':
                TableMetadata.SetRange(TableType, 1); // System = 1
            'Virtual':
                TableMetadata.SetRange(TableType, 5); // Virtual = 5
            'All', '':
                ;
            else
                Error('Invalid filter value. Use: Normal, System, Virtual, or All');
        end;
    end;


    [TryFunction]
    local procedure TryCreateTableObject(var TableMetadata: Record "Table Metadata"; var TableObj: JsonObject)
    var
        FieldCount: Integer;
        RecordCount: Integer;
    begin
        Clear(TableObj);

        TableObj.Add('id', TableMetadata.ID);
        TableObj.Add('name', TableMetadata.Name);
        TableObj.Add('caption', TableMetadata.Caption);
        TableObj.Add('type', Format(TableMetadata.TableType));
        TableObj.Add('dataClassification', Format(TableMetadata.DataClassification));

        TryGetFieldCount(TableMetadata.ID, FieldCount);
        TableObj.Add('fieldCount', FieldCount);
        
        // Add additional metadata for data understanding
        if TableMetadata.ObsoleteState <> TableMetadata.ObsoleteState::No then
            TableObj.Add('obsoleteState', Format(TableMetadata.ObsoleteState));
            
        TryGetRecordCount(TableMetadata.ID, RecordCount);
        TableObj.Add('recordCount', RecordCount);
    end;

    [TryFunction]
    local procedure TryGetFieldCount(TableId: Integer; var FieldCount: Integer)
    var
        FieldRec: Record Field;
    begin
        Clear(FieldCount);

        FieldRec.SetRange(TableNo, TableId);
        FieldRec.SetRange(Enabled, true);
        FieldRec.SetFilter(ObsoleteState, '<>%1', FieldRec.ObsoleteState::Removed);

        FieldCount := FieldRec.Count();
    end;

    [TryFunction]
    local procedure TryGetRecordCount(TableId: Integer; var RecordCount: Integer)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        i: Integer;
    begin
        RecordCount := 0;
        
        RecRef.Open(TableId);
        
        // Optimize by loading only primary key fields for count operation
        if RecRef.FieldCount > 0 then begin
            KeyRef := RecRef.KeyIndex(1); // Primary key
            for i := 1 to KeyRef.FieldCount do begin
                FieldRef := KeyRef.FieldIndex(i);
                RecRef.SetLoadFields(FieldRef.Number);
            end;
        end;
        
        RecordCount := RecRef.Count();
        RecRef.Close();
    end;
}