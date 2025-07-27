codeunit 51305 "Data Explorer Error Handler"
{
    Access = Internal;

    procedure OpenDataExplorerSetup(ErrorInfo: ErrorInfo)
    var
        DataExplorerSetup: Page "Data Explorer Setup";
    begin
        DataExplorerSetup.RunModal();
    end;
}