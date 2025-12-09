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

---

# Mandatory Instructions

<context>
The current date is **December 2025**. Use this as the reference point for determining what is "latest" or "current" when discussing technologies, versions, or best practices.
</context>

<documentation_workflow>
## Always Fetch Latest Documentation

When working with any library, framework, technology, concept, or knowledge area that you are uncertain about or that may have changed since your training:

1. **Use `context7` MCP** to resolve library IDs and fetch up-to-date documentation, code examples, and API references
   - First call `resolve-library-id` to get the correct library ID
   - Then call `get-library-docs` with the appropriate topic and mode (`code` for API/examples, `info` for conceptual guides)

2. **Use `deepwiki` MCP** to explore GitHub repositories for understanding project architecture, implementation details, and best practices
   - Use `read_wiki_structure` to get documentation topics
   - Use `read_wiki_contents` for detailed documentation
   - Use `ask_question` for specific queries about a repository

3. **Use `web search`** to find the latest information not covered by MCP tools
   - Search for recent blog posts, release announcements, and changelogs
   - Find Stack Overflow solutions and community discussions
   - Discover real-world usage patterns and edge cases
   - Verify breaking changes or deprecations in recent versions

**When to apply this workflow:**
- Before implementing features using external libraries or frameworks
- When encountering unfamiliar APIs or patterns
- When the user mentions specific versions or latest features
- When best practices or conventions may have evolved
- When troubleshooting issues that might be version-specific

This ensures responses are accurate, up-to-date, and aligned with current best practices rather than relying on potentially outdated training data.
</documentation_workflow>
