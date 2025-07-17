# Project Overview: CopilotAllTablesAndFields

## Project Identification & Purpose

- **Name:** CopilotAllTablesAndFields
- **Publisher:** FBakkensen
- **Version:** 1.0.0.0
- **Description:** Natural language interface for exploring Business Central data using Azure OpenAI. This extension provides a Copilot-powered data exploration experience, allowing users to query tables, fields, and data through conversational AI.
- **Target Business Central Compatibility:**
  - **Platform:** 1.0.0.0
  - **Application:** 26.0.0.0 (Business Central 2024 Wave 1 or later)
- **Object ID Range:** 51300-51399
- **Runtime:** 15.2

## Development Environment & Practices (Inferred)

- **Code Analyzers Enabled:**
  - CodeCop (Microsoft AL best practices)
  - PerTenantExtensionCop (per-tenant extension guidelines)
  - UICop (UI guidelines)
- **Build System:**
  - Cross-platform Makefile for Windows, Linux, and macOS
  - Dynamic metadata reading from `app.json` for build outputs
  - Output `.app` files named using publisher, app name, and version
- **Source Control:**
  - Logical, modular folder structure under `src/`
  - Microsoft-recommended file naming conventions
- **Security:**
  - Follows Business Central permission system for all data access
- **Best Practices:**
  - Consistent use of PascalCase for object, method, and variable names
  - Modular code organization for maintainability and clarity

---
This document provides a high-level overview of the project and its development environment. For codebase structure and conventions, see [02_codebase_structure.md](./02_codebase_structure.md).
