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
            action("Multi-Chat Demo")
            {
                ApplicationArea = All;
                Caption = 'Multi-Chat Copilot Demo';
                ToolTip = 'Experience multi-turn conversations with AI using Azure OpenAI chat completions';
                Image = ElectronicDoc;
                RunObject = page "Multi-Chat Copilot Demo";
            }
            action("Data Explorer Setup")
            {
                ApplicationArea = All;
                Caption = 'Data Explorer Setup';
                ToolTip = 'Configure Azure OpenAI settings for Data Explorer';
                Image = Setup;
                RunObject = page "Data Explorer Setup";
            }
            action("ModernChatInterface")
            {
                ApplicationArea = All;
                Caption = 'Modern Data Explorer Chat (POC)';
                ToolTip = 'Open the modern chat interface for exploring Business Central data';
                Image = SparkleFilled;
                RunObject = page "Modern Chat Interface";
            }
        }
    }
}