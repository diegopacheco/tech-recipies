# Gemini CLI

# GEMINI.md

Create a file `GEMINI.md` and add on `~/.gemini/GEMINI.md` for global instructions.

# Custom Commands

You can create custom commands (TOML) for Gemini by adding executable scripts to the `~/.gemini/commands/` directory. These scripts can be written in any language, as long as they are executable.

Here is a sample: `~/.gemini/commands/cr.toml`

cr.toml
```toml
description = "Code review for bugs, style, and safety"

prompt = """
# CR

Review the changes in this file for:
- Bugs and edge cases
- Performance issues
- Security vulnerabilities
- Code style and best practices
- Missing error handling
- Make sure all tests are passing
- Make sure you dont add comments
- Make sure constants are in the left ie. if (null != myVar){}

Context:
{{args}}
"""
```