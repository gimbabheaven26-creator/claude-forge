---
description: Show your Claude Forge setup summary
argument-hint: ""
allowed-tools: ["Bash", "Read", "Glob"]
---

# /show-setup

Generate a summary of your Claude Forge configuration.

## Instructions

1. Count agents in ~/.claude/agents/
2. Count commands in ~/.claude/commands/
3. Count skills in ~/.claude/skills/
4. Count hooks in ~/.claude/hooks/
5. Count rules in ~/.claude/rules/
6. Display summary with ASCII art
7. Copy to clipboard for sharing

## Output Format

```
My Claude Forge Setup
━━━━━━━━━━━━━━━━━━━━━━
Agents:   XX
Commands: XX
Skills:   XX
Hooks:    XX
Rules:    XX
━━━━━━━━━━━━━━━━━━━━━━
github.com/sangrokjung/claude-forge
```

## Clipboard

After displaying the summary, copy the text to the system clipboard:
- macOS: `pbcopy`
- Linux/WSL: `xclip -selection clipboard` or `xsel --clipboard`

Tell the user the summary has been copied to clipboard and is ready to share on X/Twitter or other social platforms.
