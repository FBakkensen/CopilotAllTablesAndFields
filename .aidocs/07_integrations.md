# Integrations

## External System Integrations

### Azure OpenAI (REST API)
- **Purpose:** Enables natural language data exploration in Business Central via AI.
- **Communication Method:** REST API calls to Azure OpenAI endpoint.
- **Authentication:** API Key stored as `SecretText` in isolated storage; never exposed in plain text.
- **Configuration:**
  - Endpoint, model name, and API key are managed via the `Data Explorer Setup` page and stored securely using `DataExplorerSecretMgt.Codeunit.al`.
- **Key AL Objects:**
  - `DataExplorerCapability.Codeunit.al` (orchestrates calls)
  - `DataExplorerSecretMgt.Codeunit.al` (secret management)
  - `DataExplorerSetup.Table.al` (configuration storage)
- **Security:**
  - All secrets are stored in isolated storage, following best practices for Business Central SaaS extensions.

## Internal Integrations (with other BC Apps/Modules)

- **Copilot Capability Registration:**
  - The extension registers itself as a Copilot capability, integrating with the Business Central Copilot framework.
  - UI integration is provided via a page extension to the Business Manager Role Center (`BusinessManagerRCExt.PageExt.al`).
- **No other significant internal integrations** with standard modules or other apps are present.

---
For code quality and best practices, see [08_code_quality.md](./08_code_quality.md).

---
[Previous: 06_eventing_extensibility.md](./06_eventing_extensibility.md) | [Next: 08_code_quality.md](./08_code_quality.md) | [Back to Index](./index.md)
