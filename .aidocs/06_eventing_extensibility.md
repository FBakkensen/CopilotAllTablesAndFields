# Eventing Model and Extensibility

## Published Events

- **No custom business or integration events are published** by this extension. All extensibility is achieved through the function-based AOAI interface and modular codeunit design.

## Subscribed Events

- **No event subscribers are defined** in this extension. The system relies on direct function calls and page actions for orchestration.

## Interfaces

### AOAI Function Interface
- The extension implements the `AOAI Function` interface for all AI-exposed functions:
  - `GetTablesFunction.Codeunit.al`
  - `GetFieldsFunction.Codeunit.al`
  - `GetDataFunction.Codeunit.al`
- **Methods (as required by the interface):**
  - `GetName(): Text`
  - `GetPrompt(): JsonObject`
  - `Execute(Arguments: JsonObject): Variant`
- **Purpose:**
  - Standardizes the contract for AI-exposed functions, enabling modular registration and invocation by the Copilot orchestrator.
- **Implementations:**
  - Each function codeunit implements the interface, providing table discovery, field metadata, and data retrieval.

## API Pages/Queries

- **None defined.** The extension does not expose any API pages or queries.

## Other Extension Points

- **Function Registration:**
  - The orchestrator (`DataExplorerCapability.Codeunit.al`) registers all AOAI functions at runtime, allowing for future extensibility by adding new function codeunits implementing the interface.
- **Setup Table:**
  - `DataExplorerSetup.Table.al` provides a configuration point for secret and endpoint management.
- **Page Extensions:**
  - `BusinessManagerRCExt.PageExt.al` integrates the Copilot capability into the Business Manager Role Center, providing a UI entry point.

---
For integrations, see [07_integrations.md](./07_integrations.md).

---
[Previous: 05_key_flows.md](./05_key_flows.md) | [Next: 07_integrations.md](./07_integrations.md) | [Back to Index](./index.md)
