<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# Project Instructions

<ask_user_questions>
## User Questions

Use the `AskUserQuestion` tool when asking questions to ensure a consistent, structured interaction experience.

Guidelines:
- Ask questions through the AskUserQuestion tool for clarifications, confirmations, and decisions
- Split into multiple tool calls when you have many questions
- This applies across all contexts

Benefits:
- Structured responses with consistent UI
- Clear options users can see and select
- Questions are highlighted and easy to identify in the conversation
</ask_user_questions>

---

<research_with_mcp_tools>
## Technical Research

Use MCP tools for technical research rather than relying on pretrained knowledge. Libraries evolve rapidly with breaking changes, APIs differ between versions, and security vulnerabilities emerge after training cutoffs.

### When to Use MCP Tools

Use MCP tools when:
- Brainstorming solutions or architecture
- Implementing new features
- Debugging issues
- Comparing libraries or approaches
- Writing code with external dependencies
- Answering questions about any technology

### Tool Priority

1. **Context7** (Primary - library documentation)
   - `mcp__context7__resolve-library-id` - find library ID
   - `mcp__context7__get-library-docs` - retrieve documentation

2. **Exa** (Code context and web search)
   - `mcp__exa__get_code_context_exa` - code questions, examples
   - `mcp__exa__web_search_exa` - latest news, blog posts, releases

3. **DeepWiki** (GitHub repositories)
   - `mcp__deepwiki__ask_question` - GitHub repo documentation
   - `mcp__deepwiki__read_wiki_contents` - repo wiki content

### Pattern: Subagent for Research

Use the Task tool with a focused prompt to research documentation in isolated context and return only essential findings.

Example for brainstorming:
```
Task tool with prompt:
"Research the best approach for implementing authentication in NestJS using Context7 and Exa. Return:
- Recommended libraries (with latest versions)
- Best practices for 2024/2025
- Security considerations
- Example implementation
- Comparison of approaches (Passport vs built-in guards)"
```

Example for implementation:
```
Task tool with prompt:
"Look up NestJS Guards documentation using Context7. Return:
- How to implement a custom guard
- Required imports
- Example code snippet
- Common pitfalls to avoid"
```

### Benefits

- **Accuracy**: Current information from authoritative sources
- **Context efficiency**: Subagent handles verbose exploration
- **Reliability**: Only distilled, verified results return to main conversation
- **Safety**: Avoid deprecated or insecure patterns
</research_with_mcp_tools>

---

<parallel_tool_usage>
## Parallel Tool Execution

When tool calls have no dependencies between them, make all independent calls in parallel to maximize efficiency. For example, when reading multiple files or searching across different sources, execute these simultaneously rather than sequentially.

Reserve sequential execution for operations where one result informs the next.
</parallel_tool_usage>

---

<context_management>
## Long-Running Tasks

For complex, multi-step tasks:
- Plan work clearly before starting
- Save progress and state to memory as context approaches limits
- Complete tasks fully rather than stopping early due to context concerns
- Use git commits as checkpoints for code changes
- Track progress in structured formats (JSON for test results, text for notes)
</context_management>

---

<openkey_analysis>
## OpenKey Analysis

When analyzing OpenKey code or behavior:

1. **Use both sources in parallel**:
   - `mcp__deepwiki__ask_question` with repo `tuyenvm/OpenKey` - for high-level architecture and documentation
   - Local code analysis in `OpenKey/` directory - for implementation details

2. **Combine insights**: Cross-reference DeepWiki explanations with actual source code to ensure accuracy

Example:
```
Task tool with prompt:
"Analyze how OpenKey handles tone placement. Use:
1. DeepWiki (tuyenvm/OpenKey) for architecture overview
2. Local OpenKey/ directory for implementation details
Return the algorithm and key code references."
```
</openkey_analysis>
