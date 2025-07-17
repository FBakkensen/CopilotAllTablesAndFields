# Codebase Structure and Conventions

## Folder and File Structure

The `src/` directory is organized into logical subfolders, each with a clear responsibility:

- **Copilot/**: Main AI capability logic, prompt page, and buffer table
- **EnumExtensions/**: Enum extension for Copilot capability
- **Functions/**: AOAI Function implementations (`get_tables`, `get_fields`, `get_data`)
- **Helpers/**: Security, filtering, and error handling utilities
- **Install/**: Capability registration logic
- **PageExtensions/**: UI integration with Business Manager Role Center
- **Setup/**: Configuration and secret management (pages, codeunits, table)

All files use Microsoft-recommended abbreviations for object types (e.g., `Codeunit`, `Page`, `Table`, `PageExt`, `EnumExt`).

## Object Naming Conventions

- All AL objects use PascalCase and are highly descriptive (e.g., `Data Explorer Capability`, `Get Tables Function`, `Table Permission Helper`, `Business Manager RC Ext`, `Data Explorer Setup`).
- File names match object names and use the correct abbreviations.

## Variable and Method Naming Conventions

- Procedures and local procedures use PascalCase and are descriptive (e.g., `GenerateCompletions`, `GetSystemMessage`, `RegisterFunctions`, `TryHasTablePermission`, `IsFullyConfigured`).
- Variable names are also PascalCase and descriptive (e.g., `Intent`, `Response`, `AzureOpenAI`, `AOAIChatMessages`).
- No snake_case or ambiguous names are present. Naming conventions are consistent and professional.

## Summary

The codebase is well-structured, modular, and follows AL and Microsoft best practices for naming and organization. This makes onboarding and maintenance straightforward for new developers.

---
For a high-level project overview, see [01_project_overview.md](./01_project_overview.md).
