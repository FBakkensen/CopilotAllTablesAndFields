permissionset 51321 "Copilot"
{
    Caption = 'Copilot All Tables Permission Set';
    Assignable = true;
    Permissions = table "Data Explorer Setup" = X,
        table "Generation Buffer" = X,
        page "Data Explorer Setup" = X,
        page "Data Explorer Secret Input" = X,
        page "Data Explorer Prompt" = X,
        codeunit "Data Explorer Capability" = X,
        codeunit "Data Explorer Secret Mgt." = X,
        codeunit "Data Explorer Install" = X,
        codeunit "Data Explorer Error Handler" = X,
        codeunit "Get Tables Function" = X,
        codeunit "Get Fields Function" = X,
        codeunit "Get Data Function" = X,
        codeunit "Table Permission Helper" = X,
        codeunit "Filter Builder" = X,
        tabledata "Data Explorer Setup" = RIMD,
        tabledata "Generation Buffer" = RIMD;
}