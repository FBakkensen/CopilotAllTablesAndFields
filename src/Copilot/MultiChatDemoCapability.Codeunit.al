codeunit 51399 "Multi-Chat Demo Capability"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Page, Page::"Copilot AI Capabilities", 'OnRegisterCopilotCapability', '', false, false)]
    local procedure OnRegisterCopilotCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
    begin
        // Register the multi-chat demo capability using correct parameters
        CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Data Explorer Preview", 'Multi-Chat Demo');
    end;
}
