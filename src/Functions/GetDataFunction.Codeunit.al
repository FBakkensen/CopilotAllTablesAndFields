codeunit 51303 "Get Data Function" implements "AOAI Function"
{
    Access = Internal;

    var
        TableNotFoundErr: Label 'Table not found: %1', Comment = '%1 = Table identifier';
        InsufficientPermissionsErr: Label 'Insufficient permissions for table: %1', Comment = '%1 = Table identifier';
        FieldNotFoundErr: Label 'Field not found: %1', Comment = '%1 = Field name';
        InvalidOptionErr: Label 'Invalid option value "%1" for field "%2". Valid options are: %3', Comment = '%1 = Invalid value, %2 = Field name, %3 = Valid options';
        WildcardFilterTxt: Label '*%1*', Locked = true;
        SortingFormatTxt: Label 'SORTING(%1)', Locked = true;
        ReturnedRecordsLbl: Label 'Returned %1 records from page %2', Comment = '%1 = Number of records, %2 = Page number';
        FunctionCalledLbl: Label '%1 function called', Comment = '%1 = Function name';

    procedure GetName(): Text
    begin
        exit('get_data');
    end;

    procedure GetPrompt(): JsonObject
    var
        FunctionPrompt: JsonObject;
        FunctionObj: JsonObject;
        Parameters: JsonObject;
        Properties: JsonObject;
        TableIdProp: JsonObject;
        FieldsProp: JsonObject;
        FieldsItems: JsonObject;
        FiltersProp: JsonObject;
        FiltersItems: JsonObject;
        FilterProperties: JsonObject;
        SortingProp: JsonObject;
        SortingItems: JsonObject;
        SortingProperties: JsonObject;
        PageSizeProp: JsonObject;
        PageNumberProp: JsonObject;
        Required: JsonArray;
        OperatorEnum: JsonArray;
        DirectionEnum: JsonArray;
    begin
        TableIdProp.Add('type', 'string');
        TableIdProp.Add('description', 'Table ID or Name to retrieve data from');
        Properties.Add('table_identifier', TableIdProp);

        FieldsItems.Add('type', 'string');
        FieldsProp.Add('type', 'array');
        FieldsProp.Add('items', FieldsItems);
        FieldsProp.Add('description', 'List of field names to retrieve (empty = all fields)');
        Properties.Add('fields', FieldsProp);

        FilterProperties.Add('field', CreateStringProperty('Field name to filter on'));

        OperatorEnum.Add('=');
        OperatorEnum.Add('<>');
        OperatorEnum.Add('>');
        OperatorEnum.Add('>=');
        OperatorEnum.Add('<');
        OperatorEnum.Add('<=');
        OperatorEnum.Add('..');
        OperatorEnum.Add('*');
        FilterProperties.Add('operator', CreateEnumProperty('Filter operator', OperatorEnum));

        FilterProperties.Add('value', CreateStringProperty('Filter value. For option/enum fields, use display text (e.g., "Open", "Posted", "Released")'));

        FiltersItems.Add('type', 'object');
        FiltersItems.Add('properties', FilterProperties);
        FiltersProp.Add('type', 'array');
        FiltersProp.Add('items', FiltersItems);
        FiltersProp.Add('description', 'Array of filter conditions. For option/enum fields, use the display text (e.g., "Open", "Posted") rather than numeric values');
        Properties.Add('filters', FiltersProp);

        SortingProperties.Add('field', CreateStringProperty('Field name to sort by'));

        DirectionEnum.Add('ASC');
        DirectionEnum.Add('DESC');
        SortingProperties.Add('direction', CreateEnumProperty('Sort direction', DirectionEnum));

        SortingItems.Add('type', 'object');
        SortingItems.Add('properties', SortingProperties);
        SortingProp.Add('type', 'array');
        SortingProp.Add('items', SortingItems);
        SortingProp.Add('description', 'Array of sorting specifications');
        Properties.Add('sorting', SortingProp);

        PageSizeProp.Add('type', 'integer');
        PageSizeProp.Add('description', 'Number of records per page (max: 100, default: 20)');
        PageSizeProp.Add('default', 20);
        PageSizeProp.Add('minimum', 1);
        PageSizeProp.Add('maximum', 100);
        Properties.Add('page_size', PageSizeProp);

        PageNumberProp.Add('type', 'integer');
        PageNumberProp.Add('description', 'Page number to retrieve (1-based, default: 1)');
        PageNumberProp.Add('default', 1);
        PageNumberProp.Add('minimum', 1);
        Properties.Add('page_number', PageNumberProp);

        Required.Add('table_identifier');

        FunctionPrompt.Add('type', 'function');
        FunctionObj.Add('name', GetName());
        FunctionObj.Add('description', 'Retrieves data from a specified Business Central table with filtering and pagination. For option/enum fields, use display text values (e.g., Status = "Open", Document Type = "Invoice")');

        Parameters.Add('type', 'object');
        Parameters.Add('properties', Properties);
        Parameters.Add('required', Required);

        FunctionObj.Add('parameters', Parameters);
        FunctionPrompt.Add('function', FunctionObj);

        exit(FunctionPrompt);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        RecRef: RecordRef;
        TableIdToken: JsonToken;
        PageSizeToken: JsonToken;
        PageNumberToken: JsonToken;
        Result: JsonObject;
        Records: JsonArray;
        RecordObj: JsonObject;
        TableIdentifier: Text;
        TableId: Integer;
        PageSize: Integer;
        PageNumber: Integer;
        TotalRecords: Integer;
        RecordCount: Integer;
        SkipCount: Integer;
        StartTime: DateTime;
        CustomDimensions: Dictionary of [Text, Text];
        Success: Boolean;
        ResultSummary: Text;
    begin
        StartTime := CurrentDateTime();
        if not Arguments.Get('table_identifier', TableIdToken) then
            Error('table_identifier parameter is required');

        TableIdentifier := TableIdToken.AsValue().AsText();

        if not TryResolveTableId(TableIdentifier, TableId) then begin
            Result.Add('error', StrSubstNo(TableNotFoundErr, TableIdentifier));
            Result.Add('records', Records);
            exit(Result);
        end;

        RecRef.Open(TableId);

        if not RecRef.ReadPermission() then begin
            Result.Add('error', StrSubstNo(InsufficientPermissionsErr, TableIdentifier));
            Result.Add('records', Records);
            exit(Result);
        end;

        PageSize := 20;
        if Arguments.Get('page_size', PageSizeToken) then begin
            PageSize := PageSizeToken.AsValue().AsInteger();
            if PageSize > 100 then
                PageSize := 100;
            if PageSize < 1 then
                PageSize := 1;
        end;

        PageNumber := 1;
        if Arguments.Get('page_number', PageNumberToken) then begin
            PageNumber := PageNumberToken.AsValue().AsInteger();
            if PageNumber < 1 then
                PageNumber := 1;
        end;

        if not TryApplyFieldSelection(RecRef, Arguments) then begin
            Result.Add('error', 'Invalid field specified in field selection');
            Result.Add('records', Records);
            exit(Result);
        end;

        if not TryApplyFilters(RecRef, Arguments) then begin
            Result.Add('error', 'Invalid filter parameters specified');
            Result.Add('records', Records);
            exit(Result);
        end;

        ApplySorting(RecRef, Arguments);

        TotalRecords := RecRef.Count();
        SkipCount := (PageNumber - 1) * PageSize;

        if SkipCount >= TotalRecords then begin
            Result.Add('records', Records);
            Result.Add('pagination', CreatePaginationInfo(PageNumber, PageSize, TotalRecords, 0));
            Result.Add('message', 'Page number exceeds available data');
            exit(Result);
        end;

        if RecRef.FindSet() then
            repeat
                if SkipCount > 0 then
                    SkipCount -= 1
                else begin
                    begin
                        TryCreateRecordObject(RecRef, Arguments, RecordObj);
                        Records.Add(RecordObj);
                    end;
                    RecordCount += 1;

                    if RecordCount >= PageSize then
                        break;
                end;
            until RecRef.Next() = 0;

        Result.Add('records', Records);
        Result.Add('pagination', CreatePaginationInfo(PageNumber, PageSize, TotalRecords, RecordCount));

        // Log telemetry
        Success := not Result.Contains('error');
        if Success then
            ResultSummary := StrSubstNo(ReturnedRecordsLbl, RecordCount, PageNumber)
        else
            ResultSummary := 'Failed to retrieve data';

        Clear(CustomDimensions);
        CustomDimensions.Add('FunctionName', GetName());
        CustomDimensions.Add('Parameters', Format(Arguments));
        CustomDimensions.Add('Success', Format(Success));
        CustomDimensions.Add('ResultSummary', ResultSummary);
        CustomDimensions.Add('ExecutionTimeMs', Format(CurrentDateTime() - StartTime));

        Session.LogMessage('DEX-0003', StrSubstNo(FunctionCalledLbl, GetName()),
            Verbosity::Normal, DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher, CustomDimensions);

        exit(Result);
    end;

    procedure ValidatePermissions(): Boolean
    begin
        exit(true);
    end;

    local procedure CreateStringProperty(Description: Text): JsonObject
    var
        Prop: JsonObject;
    begin
        Prop.Add('type', 'string');
        Prop.Add('description', Description);
        exit(Prop);
    end;

    local procedure CreateEnumProperty(Description: Text; EnumValues: JsonArray): JsonObject
    var
        Prop: JsonObject;
    begin
        Prop.Add('type', 'string');
        Prop.Add('description', Description);
        Prop.Add('enum', EnumValues);
        exit(Prop);
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

        Error('Table not found');
    end;


    [TryFunction]
    local procedure TryApplyFieldSelection(var RecRef: RecordRef; Arguments: JsonObject)
    var
        FieldRef: FieldRef;
        FieldsToken: JsonToken;
        FieldToken: JsonToken;
        FieldsArray: JsonArray;
        FieldName: Text;
        FieldsToLoad: Text;
        i: Integer;
    begin
        if not Arguments.Get('fields', FieldsToken) then
            exit;

        FieldsArray := FieldsToken.AsArray();

        if FieldsArray.Count() = 0 then
            exit;

        for i := 0 to FieldsArray.Count() - 1 do begin
            FieldsArray.Get(i, FieldToken);
            FieldName := FieldToken.AsValue().AsText();

            TryGetFieldRefByName(RecRef, FieldName, FieldRef);

            if FieldsToLoad <> '' then
                FieldsToLoad += ',';
            FieldsToLoad += Format(FieldRef.Number);
        end;

        // SetLoadFields is not available with string parameter in this version
    end;


    [TryFunction]
    local procedure TryApplyFilters(var RecRef: RecordRef; Arguments: JsonObject)
    var
        FiltersToken: JsonToken;
        FiltersArray: JsonArray;
        FilterToken: JsonToken;
        FilterObj: JsonObject;
        i: Integer;
    begin
        if not Arguments.Get('filters', FiltersToken) then
            exit;

        FiltersArray := FiltersToken.AsArray();

        for i := 0 to FiltersArray.Count() - 1 do begin
            FiltersArray.Get(i, FilterToken);
            FilterObj := FilterToken.AsObject();
            TryApplySingleFilter(RecRef, FilterObj);
        end;
    end;

    [TryFunction]
    local procedure TrySetFieldRange(var FieldRef: FieldRef; FilterValue: Text)
    var
        OptionIndex: Integer;
    begin
        case FieldRef.Type of
            FieldType::Option:
                begin
                    // First try direct numeric value
                    if Evaluate(OptionIndex, FilterValue) then begin
                        FieldRef.SetRange(OptionIndex);
                        exit;
                    end;
                    
                    // Try to find the option by text
                    OptionIndex := GetOptionIndex(FieldRef, FilterValue);
                    if OptionIndex >= 0 then
                        FieldRef.SetRange(OptionIndex)
                    else
                        Error(''); // Will be caught by TryFunction
                end;
            else
                FieldRef.SetRange(FilterValue);
        end;
    end;

    local procedure GetOptionIndex(var FieldRef: FieldRef; OptionText: Text): Integer
    var
        FieldRec: Record Field;
        OptionString: Text;
        OptionParts: List of [Text];
        i: Integer;
    begin
        // Get field metadata
        if not FieldRec.Get(FieldRef.Record().Number, FieldRef.Number) then
            exit(-1);
            
        OptionString := FieldRec.OptionString;
        if OptionString = '' then
            exit(-1);
            
        // Split options and search
        OptionParts := OptionString.Split(',');
        for i := 1 to OptionParts.Count do
            if OptionParts.Get(i).Trim().ToUpper() = OptionText.Trim().ToUpper() then
                exit(i - 1); // Options are 0-based
                
        exit(-1); // Not found
    end;

    local procedure HandleFilterError(var FieldRef: FieldRef; FilterValue: Text)
    var
        FieldRec: Record Field;
        OptionString: Text;
    begin
        case FieldRef.Type of
            FieldType::Option:
                begin
                    if FieldRec.Get(FieldRef.Record().Number, FieldRef.Number) then
                        OptionString := FieldRec.OptionString;
                    Error(InvalidOptionErr, FilterValue, FieldRef.Caption, OptionString);
                end;
            else
                Error('Invalid filter value "%1" for field "%2"', FilterValue, FieldRef.Caption);
        end;
    end;

    [TryFunction]
    local procedure TryApplySingleFilter(var RecRef: RecordRef; FilterObj: JsonObject)
    var
        FieldRef: FieldRef;
        FieldToken: JsonToken;
        OperatorToken: JsonToken;
        ValueToken: JsonToken;
        FieldName: Text;
        Operator: Text;
        FilterValue: Text;
    begin
        if not FilterObj.Get('field', FieldToken) then
            Error('Missing field parameter');
        if not FilterObj.Get('operator', OperatorToken) then
            Error('Missing operator parameter');
        if not FilterObj.Get('value', ValueToken) then
            Error('Missing value parameter');

        FieldName := FieldToken.AsValue().AsText();
        Operator := OperatorToken.AsValue().AsText();
        FilterValue := ValueToken.AsValue().AsText();

        TryGetFieldRefByName(RecRef, FieldName, FieldRef);

        case Operator of
            '=':
                if not TrySetFieldRange(FieldRef, FilterValue) then
                    HandleFilterError(FieldRef, FilterValue);
            '<>':
                FieldRef.SetFilter('<>%1', FilterValue);
            '>':
                FieldRef.SetFilter('>%1', FilterValue);
            '>=':
                FieldRef.SetFilter('>=%1', FilterValue);
            '<':
                FieldRef.SetFilter('<%1', FilterValue);
            '<=':
                FieldRef.SetFilter('<=%1', FilterValue);
            '..':
                FieldRef.SetFilter(FilterValue);
            '*':
                FieldRef.SetFilter(StrSubstNo(WildcardFilterTxt, FilterValue));
            else
                Error('Invalid operator: %1', Operator);
        end;
    end;


    local procedure ApplySorting(var RecRef: RecordRef; Arguments: JsonObject)
    var
        FieldRef: FieldRef;
        SortingToken: JsonToken;
        SortToken: JsonToken;
        FieldToken: JsonToken;
        DirectionToken: JsonToken;
        SortingArray: JsonArray;
        SortObj: JsonObject;
        FieldName: Text;
        Direction: Text;
        i: Integer;
    begin
        if not Arguments.Get('sorting', SortingToken) then
            exit;

        SortingArray := SortingToken.AsArray();

        for i := 0 to SortingArray.Count() - 1 do begin
            SortingArray.Get(i, SortToken);
            SortObj := SortToken.AsObject();

            if not SortObj.Get('field', FieldToken) then
                continue;
            if not SortObj.Get('direction', DirectionToken) then
                Direction := 'ASC'
            else
                Direction := DirectionToken.AsValue().AsText();

            FieldName := FieldToken.AsValue().AsText();

            FieldRef := GetFieldRefByName(RecRef, FieldName);
            RecRef.CurrentKeyIndex(1);

            if i = 0 then
                RecRef.SetView(StrSubstNo(SortingFormatTxt, FieldRef.Name));
        end;
    end;

    [TryFunction]
    local procedure TryGetFieldRefByName(var RecRef: RecordRef; FieldName: Text; var FieldRef: FieldRef)
    var
        i: Integer;
    begin
        for i := 1 to RecRef.FieldCount() do begin
            FieldRef := RecRef.FieldIndex(i);
            if FieldRef.Name = FieldName then
                exit;
        end;

        Error('Field not found: %1', FieldName);
    end;

    local procedure GetFieldRefByName(var RecRef: RecordRef; FieldName: Text): FieldRef
    var
        FieldRef: FieldRef;
        i: Integer;
    begin
        for i := 1 to RecRef.FieldCount() do begin
            FieldRef := RecRef.FieldIndex(i);
            if FieldRef.Name = FieldName then
                exit(FieldRef);
        end;

        Error(FieldNotFoundErr, FieldName);
    end;

    [TryFunction]
    local procedure TryCreateRecordObject(var RecRef: RecordRef; Arguments: JsonObject; var RecordObj: JsonObject)
    var
        FieldRef: FieldRef;
        FieldsToken: JsonToken;
        FieldToken: JsonToken;
        FieldsArray: JsonArray;
        FieldName: Text;
        SpecificFields: Boolean;
        i: Integer;
    begin
        Clear(RecordObj);
        SpecificFields := Arguments.Get('fields', FieldsToken);

        if SpecificFields then begin
            FieldsArray := FieldsToken.AsArray();

            for i := 0 to FieldsArray.Count() - 1 do begin
                FieldsArray.Get(i, FieldToken);
                FieldName := FieldToken.AsValue().AsText();
                TryGetFieldRefByName(RecRef, FieldName, FieldRef);
                TryAddFieldToObject(RecordObj, FieldRef);
            end;
        end else
            for i := 1 to RecRef.FieldCount() do begin
                FieldRef := RecRef.FieldIndex(i);
                if FieldRef.Active then
                    TryAddFieldToObject(RecordObj, FieldRef);
            end;
    end;


    [TryFunction]
    local procedure TryAddFieldToObject(var RecordObj: JsonObject; var FieldRef: FieldRef)
    begin
        case FieldRef.Type of
            FieldType::Integer, FieldType::BigInteger:
                RecordObj.Add(FieldRef.Name, Format(FieldRef.Value));
            FieldType::Decimal:
                RecordObj.Add(FieldRef.Name, Format(FieldRef.Value));
            FieldType::Boolean:
                if Format(FieldRef.Value) = 'Yes' then
                    RecordObj.Add(FieldRef.Name, true)
                else
                    RecordObj.Add(FieldRef.Name, false);
            FieldType::Date:
                if Format(FieldRef.Value) <> '' then
                    RecordObj.Add(FieldRef.Name, Format(FieldRef.Value, 0, '<Year4>-<Month,2>-<Day,2>'))
                else
                    RecordObj.Add(FieldRef.Name, '');
            FieldType::DateTime:
                if Format(FieldRef.Value) <> '' then
                    RecordObj.Add(FieldRef.Name, Format(FieldRef.Value, 0, '<Year4>-<Month,2>-<Day,2> <Hours24>:<Minutes,2>:<Seconds,2>'))
                else
                    RecordObj.Add(FieldRef.Name, '');
            else
                RecordObj.Add(FieldRef.Name, Format(FieldRef.Value));
        end;
    end;


    local procedure CreatePaginationInfo(PageNumber: Integer; PageSize: Integer; TotalRecords: Integer; RecordsInPage: Integer): JsonObject
    var
        Pagination: JsonObject;
        TotalPages: Integer;
    begin
        TotalPages := (TotalRecords + PageSize - 1) div PageSize;

        Pagination.Add('currentPage', PageNumber);
        Pagination.Add('pageSize', PageSize);
        Pagination.Add('totalRecords', TotalRecords);
        Pagination.Add('totalPages', TotalPages);
        Pagination.Add('recordsInPage', RecordsInPage);
        Pagination.Add('hasNextPage', PageNumber < TotalPages);
        Pagination.Add('hasPreviousPage', PageNumber > 1);

        exit(Pagination);
    end;
}