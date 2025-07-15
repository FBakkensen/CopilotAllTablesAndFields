codeunit 51311 "Table Permission Helper"
{
    Access = Internal;

    [TryFunction]
    procedure TryHasTablePermission(TableId: Integer; var HasPermission: Boolean)
    var
        TableMetadata: Record "Table Metadata";
        RecRef: RecordRef;
    begin
        HasPermission := false;

        if TableId >= 2000000000 then
            exit; // Skip system tables silently

        // First check if table is obsoleted
        if TableMetadata.Get(TableId) then begin
            if TableMetadata.ObsoleteState = TableMetadata.ObsoleteState::Removed then
                exit; // Skip obsoleted tables silently
            if TableMetadata.DataIsExternal then
                exit; // Skip external tables silently
            if TableMetadata.TableType <> TableMetadata.TableType::Normal then
                exit; // Skip non-normal tables silently
            if TableMetadata.Scope = TableMetadata.Scope::OnPrem then
                exit; // Skip on-prem tables silently
        end;
        // Then check permissions
        RecRef.Open(TableId);
        HasPermission := RecRef.ReadPermission();
        RecRef.Close();
    end;

    procedure HasTablePermission(TableId: Integer): Boolean
    var
        HasPermission: Boolean;
    begin
        if TryHasTablePermission(TableId, HasPermission) then
            exit(HasPermission);

        exit(false);
    end;
}