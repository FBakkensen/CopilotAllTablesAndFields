codeunit 51320 "Data Explorer Install"
{
    Subtype = Install;
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    trigger OnInstallAppPerCompany()
    begin
        RegisterCapability();
    end;

    local procedure RegisterCapability()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        CopilotCapability: Codeunit "Copilot Capability";
        LearnMoreUrlTxt: Label 'https://learn.microsoft.com/dynamics365/business-central/copilot-overview', Locked = true;
    begin
        // Only register capability in Business Central online (SaaS) environments
        if EnvironmentInfo.IsSaaSInfrastructure() then
            if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Data Explorer Preview") then
                CopilotCapability.RegisterCapability(
                    Enum::"Copilot Capability"::"Data Explorer Preview",
                    Enum::"Copilot Availability"::Preview,
                    LearnMoreUrlTxt);
    end;
}