# Canonical Spec System - Installation Guide

## Overview

This system provides a complete Claude Code workflow for building production-quality software from natural language specs. It includes:

- **10 slash commands** for the build pipeline
- **9 agents** for expert review and testing
- **1 CLAUDE.md** for global instructions
- **1 settings.json** for permissions and hooks

---

## Directory Structure

After installation, your structure should look like this:

```
~/.claude/
├── commands/
│   ├── spec-check.md
│   ├── spec-check-design.md
│   ├── council-review.md
│   ├── design-system.md
│   ├── new-app.md
│   ├── clone-design.md
│   ├── add-effect.md
│   ├── add-python-component.md
│   ├── add-rule.md
│   └── deploy-production.md
├── agents/
│   ├── simplicity-enforcer.md
│   ├── conversion-architect.md
│   ├── seo-architect.md
│   ├── ux-critic.md
│   ├── growth-analyst.md
│   ├── security-reviewer.md
│   ├── accessibility-auditor.md
│   ├── council-arbitrator.md
│   └── test-runner.md
└── settings.json

your-project/
└── CLAUDE.md
```

---

## Installation Steps

### Step 1: Prerequisites and Directories

Install required tools:

```bash
# Install prerequisites
npm install -g prettier
brew install jq  # macOS
# apt install jq  # Linux/Ubuntu
```

Create directories:

```bash
mkdir -p ~/.claude/commands
mkdir -p ~/.claude/agents
```

### Step 2: Install Commands

Copy all command files to `~/.claude/commands/`:

```bash
# From your downloads folder (adjust path as needed)
cp spec-check.md ~/.claude/commands/
cp spec-check-design.md ~/.claude/commands/
cp council-review.md ~/.claude/commands/
cp design-system.md ~/.claude/commands/
cp new-app.md ~/.claude/commands/
cp clone-design.md ~/.claude/commands/
cp add-effect.md ~/.claude/commands/
cp add-python-component.md ~/.claude/commands/
cp add-rule.md ~/.claude/commands/
cp deploy-production.md ~/.claude/commands/
```

### Step 3: Install Agents

Copy all agent files to `~/.claude/agents/`:

```bash
cp simplicity-enforcer.md ~/.claude/agents/
cp conversion-architect.md ~/.claude/agents/
cp seo-architect.md ~/.claude/agents/
cp ux-critic.md ~/.claude/agents/
cp growth-analyst.md ~/.claude/agents/
cp security-reviewer.md ~/.claude/agents/
cp accessibility-auditor.md ~/.claude/agents/
cp council-arbitrator.md ~/.claude/agents/
cp test-runner.md ~/.claude/agents/
```

### Step 4: Install Settings

```bash
cp settings.json ~/.claude/settings.json
```

### Step 5: Install Project CLAUDE.md

Copy CLAUDE.md to each project root where you want to use the system:

```bash
cp CLAUDE.md /path/to/your-project/CLAUDE.md
```

---

## Verify Installation

### Check Commands

```bash
ls -la ~/.claude/commands/
```

Expected: 10 files

### Check Agents

```bash
ls -la ~/.claude/agents/
```

Expected: 9 files

### Check Settings

```bash
cat ~/.claude/settings.json
```

Expected: JSON with enabledPlugins, hooks, and permissions

### Test in Claude Code

Start Claude Code in your project directory and try:

```
/spec-check
```

If the command is recognized, installation is complete.

---

## Pipeline Overview

### Pre-Build (Quality Gates)

| Stage | Command | Purpose |
|-------|---------|---------|
| 1 | `/spec-check` | Verify spec is buildable, identify gaps |
| 2 | `/spec-check design` | Verify visual specs are complete |
| 3 | `/council-review` | Run 7-expert review, get approval |
| 4 | `/design-system` | Extract tokens, generate theme files |

### Build

| Stage | Command | Purpose |
|-------|---------|---------|
| 5 | `/new-app` | Pre-flight checks + build from spec |

### Post-Build

| Stage | Command | Purpose |
|-------|---------|---------|
| 6 | `/deploy-production` | Full deployment checklist |

---

## Plugins

The system uses one external plugin:

| Plugin | Purpose |
|--------|---------|
| ralph-wiggum | Autonomous loop execution for multi-step builds |

This plugin is enabled in `settings.json`. It provides the `/ralph-loop` command referenced in CLAUDE.md. No separate file installation needed.

---

## Utility Commands

| Command | Purpose |
|---------|---------|
| `/clone-design` | Pixel-perfect design replication |
| `/add-effect` | Add motion effects to existing UI |
| `/add-python-component` | Add Python backend to project |
| `/add-rule` | Capture mistake as permanent rule |

---

## Agent Reference

### Council Agents (Spec Review)

| Agent | Domain |
|-------|--------|
| simplicity-enforcer | Scope, clarity, One Question filter |
| conversion-architect | Psychology, persuasion, NLP patterns |
| seo-architect | Discoverability, technical SEO |
| ux-critic | Flows, friction, cognitive load |
| growth-analyst | Distribution, retention, virality |
| accessibility-auditor | WCAG, inclusive design |
| council-arbitrator | Synthesize reviews, resolve conflicts |

### Build Agents

| Agent | Domain |
|-------|--------|
| security-reviewer | Code vulnerability analysis |
| test-runner | Test execution, failure analysis, fixes |

> **Note:** security-reviewer runs twice: once during `/council-review` (spec review) and again post-build (code review). This dual-gate approach catches security issues at both design and implementation stages.

---

## Quick Start

After installation, typical workflow:

1. Create SPEC.md in your project (or have Claude help write it)
2. Run `/spec-check` to validate
3. Run `/council-review` to get expert approval
4. Run `/design-system` if project has UI
5. Run `/new-app` to build

Claude handles all technical decisions. You provide direction in plain language.

---

## Troubleshooting

### Commands not recognized

- Verify files are in `~/.claude/commands/` (not a subdirectory)
- Verify file extensions are `.md`
- Restart Claude Code

### Agents not found

- Verify files are in `~/.claude/agents/`
- Check CLAUDE.md references correct path (`~/.claude/agents/`)

### Permissions errors

- Verify `settings.json` is valid JSON
- Check `permissions.allow` array includes needed operations

### Hooks not running

- Verify `prettier` is installed: `npm install -g prettier`
- Verify `jq` is installed: `brew install jq` (macOS) or `apt install jq` (Linux)

---

## Updating

To update the system, simply replace the files with newer versions. The system is stateless - all state lives in your project's SPEC.md, COUNCIL_REVIEW.md, and other generated files.

---

## Files Included

| File | Type | Location |
|------|------|----------|
| spec-check.md | Command | ~/.claude/commands/ |
| spec-check-design.md | Command | ~/.claude/commands/ |
| council-review.md | Command | ~/.claude/commands/ |
| design-system.md | Command | ~/.claude/commands/ |
| new-app.md | Command | ~/.claude/commands/ |
| clone-design.md | Command | ~/.claude/commands/ |
| add-effect.md | Command | ~/.claude/commands/ |
| add-python-component.md | Command | ~/.claude/commands/ |
| add-rule.md | Command | ~/.claude/commands/ |
| deploy-production.md | Command | ~/.claude/commands/ |
| simplicity-enforcer.md | Agent | ~/.claude/agents/ |
| conversion-architect.md | Agent | ~/.claude/agents/ |
| seo-architect.md | Agent | ~/.claude/agents/ |
| ux-critic.md | Agent | ~/.claude/agents/ |
| growth-analyst.md | Agent | ~/.claude/agents/ |
| security-reviewer.md | Agent | ~/.claude/agents/ |
| accessibility-auditor.md | Agent | ~/.claude/agents/ |
| council-arbitrator.md | Agent | ~/.claude/agents/ |
| test-runner.md | Agent | ~/.claude/agents/ |
| settings.json | Config | ~/.claude/ |
| CLAUDE.md | Config | Project root |
