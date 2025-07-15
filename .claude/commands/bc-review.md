# Business Central AL Code Review

Perform a comprehensive code review of this Business Central AL extension, focusing on identifying potential improvements without implementing them.

**IMPORTANT**: Use ultrathink mode throughout this review for deep analysis and comprehensive reasoning about code quality, architecture, and potential improvements.

**PRIMARY REFERENCES**: 
1. The official Microsoft AL guidelines from 'microsoft/alguidelines' - for code quality standards, naming conventions, and best practices
2. Microsoft Docs (via mcp__microsoft_docs_mcp__microsoft_docs_search) - for Business Central patterns, implementation details, and technical specifications

Every finding and recommendation must be grounded in these official sources. When citing issues, reference the specific guideline or documentation page.

## Phase 1: Research & Best Practices Gathering

Before analyzing the codebase, launch multiple sub-agents to gather Business Central best practices and standards:

<research_steps>
### Launch parallel research agents for:
**Note**: Instruct each sub-agent to use ultrathink mode for thorough analysis and pattern extraction.

1. **Project Documentation** - Check for `.aidocs` folder
   - Agent Task: "Search for and analyze any .aidocs folder in the project. Start with index.md if present. Extract architecture, data models, and workflow information."

2. **AL Coding Guidelines** - Official Microsoft standards (CRITICAL)
   - Agent Task: "Use mcp__context7__resolve-library-id to resolve 'microsoft/alguidelines', then use mcp__context7__get-library-docs to fetch comprehensive AL coding standards. This is the PRIMARY REFERENCE for the entire review. Extract ALL guidelines including: object naming conventions, code style rules, performance patterns, extension-model patterns, best practices, anti-patterns, and any other standards. Create a comprehensive reference that will be used to evaluate every aspect of the codebase."

3. **Microsoft Documentation** - Business Central patterns (CRITICAL)
   - Agent Task: "Use mcp__microsoft_docs_mcp__microsoft_docs_search to comprehensively search Microsoft Docs for Business Central documentation. This is a PRIMARY REFERENCE alongside microsoft/alguidelines. Search for: AL language documentation, Business Central development patterns, performance best practices, cloud optimization patterns, extension development guidelines, API patterns, event handling best practices, and any other official Microsoft documentation related to Business Central development. Create a comprehensive reference for the review."

4. **Standard BC Patterns** - Search FBakkensen/bc-w1 repository
   - Agent Task: "Use gh CLI to search FBakkensen/bc-w1 repository for: workflow implementations, event handling patterns, role center structures, and approval workflows. Extract patterns only - do not copy code."

5. **Innovation Examples** - Search microsoft/bctech repository
   - Agent Task: "Use gh CLI to search microsoft/bctech repository for: cutting-edge AL patterns, advanced event handling, and emerging object structures. Extract patterns only - do not copy code."

6. **URL Analysis** - If URLs provided in arguments
   - Agent Task: "If any URLs are provided, use WebFetch to get initial content and recursively follow relevant links to gather complete information about Business Central patterns or requirements."
</research_steps>

## Phase 2: Codebase Analysis

After gathering best practices, analyze the specific codebase:

1. **Examine CLAUDE.md** to understand project-specific guidelines and patterns
2. **Identify the extension scope** by reading app.json for:
   - ID ranges being used
   - Dependencies and platform requirements
   - Extension purpose and functionality
3. **Map the architecture** by analyzing the src/ directory structure to understand:
   - Component organization (Copilot, Functions, Setup, Helpers, etc.)
   - Layering patterns (Interface, Capability, Function, Helper, Data layers)
   - Integration points between components

Use Glob and Grep extensively to find patterns, dependencies, and potential issues across the codebase.

## Phase 3: Systematic Code Review

Compare the codebase against the best practices gathered in Phase 1. Analyze across multiple dimensions using XML tags to structure your analysis.

**USE ULTRATHINK MODE**: For each component and analysis dimension below, engage ultrathink to:
- Deeply analyze code patterns and their implications
- Consider multiple architectural perspectives
- Identify subtle issues and optimization opportunities
- Reason through complex interactions between components
- Evaluate design decisions against best practices

<thinking>
Think through each component systematically:
1. What is its purpose and responsibility?
2. How does it interact with other components?
3. What patterns does it follow or deviate from?
4. What risks or improvements do I see?
</thinking>

### 3.1 Performance Review
Identify performance optimization opportunities:
- **Database Operations**: Look for missing SetLoadFields, inefficient filters
- **Loop Efficiency**: Check for nested loops or repeated database calls
- **Record Count Operations**: Ensure counts are limited appropriately

### 3.2 Code Quality & Standards (Strict Adherence to Primary References)
Verify strict adherence to both microsoft/alguidelines and Microsoft Docs standards:
- **Naming Conventions**: Strictly validate against microsoft/alguidelines
  - Every identifier must follow the exact rules from the guidelines
  - Flag ANY deviation from the official naming standards
  - Reference specific sections of the guidelines when reporting issues
- **Code Style**: Validate all formatting against microsoft/alguidelines
  - Indentation, spacing, line breaks must match guidelines exactly
  - Reference the specific guideline rule for each violation
- **Code Organization**: Verify against structural patterns in guidelines
- **Error Handling**: Check against error handling best practices in guidelines
- **Documentation**: Validate documentation requirements from guidelines
- **Performance Patterns**: Verify against both sources:
  - Performance patterns from microsoft/alguidelines
  - Performance best practices from Microsoft Docs
- **IMPORTANT**: For EVERY finding, cite the specific section from either microsoft/alguidelines or Microsoft Docs (or both when applicable)

### 3.3 Architectural Concerns
Evaluate design and architecture:
- **Separation of Concerns**: Each component has single responsibility
- **Extensibility**: Identify areas that may need interface abstraction
- **Dependencies**: Check for circular dependencies or tight coupling
- **Consistency**: Verify consistent patterns across similar components
- **Technical Debt**: Note TODOs, commented code, or incomplete implementations

### 3.4 Business Central Specific (Using Microsoft Standards)
Check BC-specific best practices based on Phase 1 research:
- **Obsolete Handling**: Check for proper obsolete state management
- **Event Patterns**: Compare against patterns found in FBakkensen/bc-w1
  - Event subscribers and publishers
  - Integration events usage
  - Event naming conventions
- **Advanced Patterns**: Check against microsoft/bctech examples
  - Modern AL patterns
  - Performance optimizations
  - Cloud-ready implementations

### 3.5 Implementation Completeness
Assess implementation status:
- **Feature Completeness**: Check if all intended features are implemented
- **Error Scenarios**: Check handling of edge cases
- **Data Validation**: Input validation and boundary checks
- **Integration Points**: Verify external service error handling
- **TODO Items**: Identify incomplete implementations or technical debt

## Phase 4: Findings Report

**USE ULTRATHINK MODE**: When formulating findings and recommendations, engage ultrathink to:
- Provide deep insights into root causes
- Consider ripple effects of proposed changes
- Balance ideal solutions with practical constraints
- Prioritize improvements based on impact and effort

Structure your findings in this format:

<findings>
<critical>
[Issues that could cause data loss, system failures, or critical bugs]
- Location: [File:Line]
- Issue: [Clear description]
- Reference: [Specific section from microsoft/alguidelines and/or Microsoft Docs page]
- Impact: [What could go wrong]
- Recommendation: [Specific improvement suggestion based on guidelines]
</critical>

<major>
[Significant issues affecting performance, maintainability, or user experience]
- Location: [File:Line]
- Issue: [Clear description]
- Reference: [Specific section from microsoft/alguidelines and/or Microsoft Docs page]
- Impact: [Business or technical impact]
- Recommendation: [Improvement approach per guidelines]
</major>

<minor>
[Code quality, standards, or nice-to-have improvements]
- Location: [File:Line]
- Issue: [Description]
- Reference: [Specific section from microsoft/alguidelines and/or Microsoft Docs page]
- Recommendation: [Enhancement suggestion from guidelines]
</minor>

<positive>
[Good patterns and practices worth highlighting]
- What: [Description of good practice]
- Why: [Why it's beneficial]
- Where: [Examples in codebase]
</positive>
</findings>

## Phase 5: Improvement Roadmap

**USE ULTRATHINK MODE**: When creating the improvement roadmap, engage ultrathink to:
- Strategically sequence improvements for maximum impact
- Consider dependencies between different improvements
- Balance quick wins with long-term architectural changes
- Account for team capacity and business priorities

Based on the findings, suggest a prioritized improvement plan:

1. **Immediate Actions** (Critical stability fixes and bugs)
2. **Short-term Improvements** (1-2 sprints)
3. **Long-term Enhancements** (Architecture/design improvements)
4. **Technical Debt Items** (Refactoring opportunities)

## Review Guidelines

- Be specific with file names and line numbers
- **ALWAYS cite the specific section from microsoft/alguidelines and/or Microsoft Docs for every finding**
- Provide concrete examples for improvements based on the primary references
- When suggesting changes, show the compliant version according to official standards
- Balance idealism with pragmatism, but prioritize compliance with primary references
- Acknowledge when code correctly follows microsoft/alguidelines and Microsoft Docs patterns
- Focus on actionable feedback grounded in the official sources
- Every recommendation must reference the relevant section from either primary source

## Important Notes

- DO NOT implement any changes - only identify and suggest
- DO NOT create new files - only review existing code
- Focus on providing value through insightful analysis
- Consider the business context of a Copilot data exploration tool
- Remember this integrates with Azure OpenAI for natural language queries

$ARGUMENTS