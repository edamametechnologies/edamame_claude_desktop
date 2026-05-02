# EDAMAME for Claude Desktop

Runtime behavioral monitoring for Claude Desktop. Bridges Desktop Cowork
session transcripts to the EDAMAME Security two-plane divergence engine for
continuous workstation protection.

---

**Which plugin do I need?**

| Scenario | Install |
|---|---|
| Using the **Claude Desktop app** (Code + Cowork modes) | This plugin (`edamame_claude_desktop`) |
| Using only the **Claude Code CLI** (terminal) | [`edamame_claude_code`](https://github.com/edamametechnologies/edamame_claude_code) instead |
| Using **both** Desktop app and Code CLI | Install both -- they register under different MCP keys and do not conflict |

---

## How It Works

1. Claude Desktop produces Cowork session transcripts in the platform-specific local-agent-mode directory:
   - macOS: `~/Library/Application Support/Claude/local-agent-mode-sessions/`
   - Windows: `%APPDATA%/Claude/local-agent-mode-sessions/`
   - Linux: `~/.local/share/claude-desktop/local-agent-mode-sessions/`
2. This package parses transcripts and forwards them to EDAMAME via MCP
   (`upsert_behavioral_model_from_raw_sessions`).
3. EDAMAME evaluates behavioral intent against live system telemetry.
4. Divergence verdicts (`CLEAN`, `DIVERGENCE`, `NO_MODEL`, `STALE`) surface
   through the control center or health checks.

## Installation

### 1. EDAMAME Security app (recommended on macOS / Windows)

Open the EDAMAME Security app, navigate to **AI Settings > Agent Plugins**,
and install the Claude Desktop plugin from the list.

### 2. edamame_posture CLI

```bash
edamame-posture install-agent-plugin claude_desktop
edamame-posture agent-plugin-status claude_desktop
```

### 3. Manual install (bash)

```bash
bash setup/install.sh [/optional/path/to/workspace]
```

### 4. Manual install (PowerShell, Windows)

```powershell
.\setup\install.ps1 [-WorkspaceRoot "C:\Users\me\projects\myapp"]
```

The workspace argument is **optional**. It only affects `transcript_project_hints`
(used to prioritize which transcripts to process) and `agent_instance_id`. When
omitted, the plugin monitors transcripts from **all** your Claude Desktop
projects.

All installation paths install **once per user** into a global directory and
register a single `edamame` MCP server entry in `~/.claude.json`, preserving
any existing servers. There is no need to reinstall when switching workspaces.

### Post-install

1. Restart Claude Desktop so it discovers the new MCP server.
2. Run the `edamame_claude_desktop_control_center` tool inside Claude Desktop
   to open the pairing dashboard.
3. Pair with EDAMAME Security (see [docs/SETUP.md](docs/SETUP.md) for details).

## Prerequisites

- Node.js 18+ with `fetch` support.
- A local EDAMAME host on the same machine:
  - macOS / Windows: the EDAMAME Security app
  - Linux: `edamame_posture` CLI

## Directory Structure

```
bridge/                             # Local stdio MCP bridge, control center, forwarding
  claude_desktop_edamame_mcp.mjs    # MCP bridge entry point
  control_center_app.html           # Pairing and status UI
  edamame_client.mjs                # HTTP client for EDAMAME MCP endpoint
adapters/                           # Claude Desktop transcript parsing and payload assembly
  session_prediction_adapter.mjs
service/                            # Extrapolator, verdict reader, posture facade, health
  claude_desktop_extrapolator.mjs   # Transcript-to-model translation and push
  verdict_reader.mjs                # Read-only divergence verdict facade
  posture_facade.mjs                # Read-only posture/score/sessions facade
  control_center.mjs                # Pairing, status, and control center logic
  health.mjs                        # Health check implementation
  healthcheck_cli.mjs               # CLI health check entry point
  config.mjs                        # Configuration management
skills/                             # Agent skills
  security-posture/SKILL.md         # Posture assessment skill
  divergence-monitor/SKILL.md       # Divergence diagnosis skill
agents/                             # Custom agent configurations
  security-monitor.md               # Security-aware coding agent
commands/                           # Agent-executable commands
  healthcheck.md                    # Run EDAMAME health check
  export-intent.md                  # Force behavioral model refresh
prompts/                            # Prompt contract for EDAMAME raw-session ingest
setup/                              # Install and health-check scripts, config templates
  install.sh                        # Install the package (bash)
  install.ps1                       # Install the package (PowerShell, Windows)
  healthcheck.sh                    # Operator health check
docs/                               # Setup and architecture guidance
tests/                              # Unit tests and E2E intent injection
```

## Build and Test

```bash
node --test tests/*.test.mjs
bash setup/healthcheck.sh --strict --json
bash tests/e2e_inject_intent.sh
```

## Docs

- [docs/SETUP.md](docs/SETUP.md)
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- [docs/VALIDATION.md](docs/VALIDATION.md)
- [E2E_TESTS.md](E2E_TESTS.md)

## Detailed Setup

See [docs/SETUP.md](docs/SETUP.md) for configuration paths, pairing workflow,
health check details, and troubleshooting. See
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the runtime component map and
[docs/VALIDATION.md](docs/VALIDATION.md) for the validation matrix.

## Sibling Repositories

| Repository | Purpose |
|---|---|
| [edamame_claude_code](https://github.com/edamametechnologies/edamame_claude_code) | Claude Code CLI plugin (public) |
| [edamame_cursor](https://github.com/edamametechnologies/edamame_cursor) | Cursor developer workstation package (public) |
| [edamame_openclaw](https://github.com/edamametechnologies/edamame_openclaw) | OpenClaw agent integration package (public) |
| [agent_security](https://github.com/edamametechnologies/agent_security) | Research paper and publication pipeline (public) |
| [edamame_posture](https://github.com/edamametechnologies/edamame_posture) | EDAMAME Posture CLI (public) |

## License

Apache-2.0
