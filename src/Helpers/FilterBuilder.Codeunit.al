codeunit 51313 "Filter Builder"
{
    var
        InvalidFilterErr: Label 'Invalid filter expression: %1', Comment = '%1 = The filter expression that was invalid';
        WildcardFilterTxt: Label '*%1*', Locked = true;
        CaseInsensitiveFilterTxt: Label '@*%1*', Locked = true;
        
    [TryFunction]
    procedure TryBuildFilterFromJson(var RecRef: RecordRef; FiltersArray: JsonArray)
    var
        FilterToken: JsonToken;
        FilterObj: JsonObject;
        i: Integer;
    begin
        for i := 0 to FiltersArray.Count() - 1 do begin
            FiltersArray.Get(i, FilterToken);
            if FilterToken.IsObject() then begin
                FilterObj := FilterToken.AsObject();
                TryApplySingleFilter(RecRef, FilterObj);
            end;
        end;
    end;

    procedure BuildFilterFromJson(var RecRef: RecordRef; FiltersArray: JsonArray)
    begin
        TryBuildFilterFromJson(RecRef, FiltersArray);
    end;
    
    [TryFunction]
    procedure TryApplySingleFilter(var RecRef: RecordRef; FilterObj: JsonObject)
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
        
        if not TryGetFieldRefByName(RecRef, FieldName, FieldRef) then
            Error('Field not found: %1', FieldName);
        
        case Operator of
            '=':
                FieldRef.SetRange(FilterValue);
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
            'LIKE':
                FieldRef.SetFilter(StrSubstNo(CaseInsensitiveFilterTxt, FilterValue));
            else
                Error('Invalid operator: %1', Operator);
        end;
    end;

    procedure ApplySingleFilter(var RecRef: RecordRef; FilterObj: JsonObject)
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
            exit;
        if not FilterObj.Get('operator', OperatorToken) then
            exit;
        if not FilterObj.Get('value', ValueToken) then
            exit;
        
        FieldName := FieldToken.AsValue().AsText();
        Operator := OperatorToken.AsValue().AsText();
        FilterValue := ValueToken.AsValue().AsText();
        
        FieldRef := GetFieldRefByName(RecRef, FieldName);
        
        case Operator of
            '=':
                FieldRef.SetRange(FilterValue);
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
            'LIKE':
                FieldRef.SetFilter(StrSubstNo(CaseInsensitiveFilterTxt, FilterValue));
            else
                Error(InvalidFilterErr, Operator);
        end;
    end;
    
    procedure ParseDateFilter(FilterValue: Text): Text
    var
        DateFormula: DateFormula;
        DateValue: Date;
    begin
        if Evaluate(DateValue, FilterValue) then
            exit(Format(DateValue));
        
        if Evaluate(DateFormula, FilterValue) then
            exit(Format(CalcDate(DateFormula, Today)));
        
        exit(FilterValue);
    end;
    
    procedure ValidateFilterSyntax(FilterExpression: Text): Boolean
    var
        TempRecRef: RecordRef;
        TempFieldRef: FieldRef;
    begin
        TempRecRef.Open(Database::Customer);
        TempFieldRef := TempRecRef.Field(1);
        
        TempFieldRef.SetFilter(FilterExpression);
        
        exit(true);
    end;
    
    [TryFunction]
    local procedure TryGetFieldRefByName(var RecRef: RecordRef; FieldName: Text; var FieldRef: FieldRef)
    var
        i: Integer;
    begin
        for i := 1 to RecRef.FieldCount() do begin
            FieldRef := RecRef.FieldIndex(i);
            if UpperCase(FieldRef.Name) = UpperCase(FieldName) then
                exit;
        end;
        
        Error('Field not found');
    end;

    local procedure GetFieldRefByName(var RecRef: RecordRef; FieldName: Text): FieldRef
    var
        FieldRef: FieldRef;
        i: Integer;
    begin
        for i := 1 to RecRef.FieldCount() do begin
            FieldRef := RecRef.FieldIndex(i);
            if UpperCase(FieldRef.Name) = UpperCase(FieldName) then
                exit(FieldRef);
        end;
        
        Error('Field not found: %1', FieldName);
    end;
}