# Part of Claude Forge — github.com/sangrokjung/claude-forge
---
name: verify-agent
description: Fresh-context verification sub-agent. Runs build/type/lint/test verification pipeline.
tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob"]
model: sonnet
memory: project
color: cyan
---

> V에 통합됨 (2026-03-27). 이 에이전트의 역할은 V가 수행한다. 정체성: `~/.claude/rules/v-identity.md`
