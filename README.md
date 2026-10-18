# dotagents

A collection of configurations, instructions, and skills I use across my AI coding agents.

## What's Included

- **Shared Instructions:** A single `AGENTS.md` source of truth shared across Pi, OpenCode, and Claude Code.
- **Agent Configurations:** Global settings, subagent definitions, and other agent-specific customizations.
- **Shared Skills:** Atlas skills maintained in `darknesskiller/skills`.
- **Skill Installer:** `scripts/install-agent-skills.sh` installs Atlas, Matt Pocock, Caveman, Pstack, and other selected skills using `skills@latest`, which detects available agents.

## Installation

Run the installer to link configurations for installed agents and install the selected skills:

```
./install.sh
```
