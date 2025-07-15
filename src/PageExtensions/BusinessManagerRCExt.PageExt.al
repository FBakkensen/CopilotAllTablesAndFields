pageextension 51300 "Business Manager RC Ext" extends "Business Manager Role Center"
{
    actions
    {
        addlast(Processing)
        {
            action("Data Explorer")
            {
                ApplicationArea = All;
                Caption = 'Data Explorer with Copilot';
                ToolTip = 'Explore Business Central data using natural language queries powered by Copilot';
                Image = Sparkle;
                RunObject = page "Data Explorer Prompt";
            }
            action("Data Explorer Setup")
            {
                ApplicationArea = All;
                Caption = 'Data Explorer Setup';
                ToolTip = 'Configure Azure OpenAI settings for Data Explorer';
                Image = Setup;
                RunObject = page "Data Explorer Setup";
            }
        }
    }
}