# Setup

## Prerequisites

- Node.js 18+ with `fetch` support.
- A local EDAMAME host on the same machine:
  - macOS / Windows: the EDAMAME Security app
  - Linux: `edamame_posture`

## Install via EDAMAME app / posture CLI

EDAMAME downloads the latest release from GitHub (HTTP zipball -- no `git`
required) and copies files using native Rust file operations (no `bash` or
`python` required). Works on macOS, Linux, and Windows:

```bash
edamame-posture install-agent-plugin claude_desktop
edamame-posture agent-plugin-status claude_desktop
```

The provisioning engine automatically registers the `edamame` MCP server
entry in Claude Desktop's global configuration (`~/.claude.json`). Existing
servers in that file are preserved. Uninstalling the plugin
(`edamame-posture uninstall-agent-plugin claude_desktop`) removes the `edamame`
entry from the global config.

The EDAMAME Security app also exposes an "Agent Plugins" section in AI
Settings with one-click install, status display, and intent injection test
buttons.

## Install From Source (bash)

```bash
bash setup/install.sh [/optional/path/to/workspace]
```

The workspace argument is **optional**. When provided, it seeds
`transcript_project_hints` (to prioritize matching transcripts) and derives the
`agent_instance_id`. When omitted, the plugin monitors transcripts from **all**
your Claude Desktop projects -- no per-workspace install is needed.

The installer:

- copies the package into a **global per-user** install directory (one copy per
  machine, shared across all workspaces),
- renders a default package config (only on first install -- existing config
  is preserved),
- renders a Claude Desktop MCP snippet with fully resolved paths (including
  absolute `node` path),
- automatically injects the `edamame` server entry into Claude Desktop's
  global configuration (`~/.claude.json`), preserving any existing servers.

Once Claude Desktop launches the MCP bridge, the bridge itself refreshes the
behavioral model on the configured cadence while the session remains
connected.

## Install From Source (PowerShell, Windows)

```powershell
.\setup\install.ps1 [-WorkspaceRoot "C:\Users\me\projects\myapp"]
```

PowerShell equivalent of `install.sh` for native Windows environments. The
`-WorkspaceRoot` parameter is optional (same semantics as the bash installer).
Does the same file copy + template rendering without requiring bash or python.

## Config Paths

Primary config file:

- macOS: `~/Library/Application Support/claude-desktop-edamame/config.json`
- Windows: `%APPDATA%\claude-desktop-edamame\config.json`
- Linux: `~/.config/claude-desktop-edamame/config.json`

Default state directory:

- macOS: `~/Library/Application Support/claude-desktop-edamame/state`
- Windows: `%LOCALAPPDATA%\claude-desktop-edamame\state`
- Linux: `~/.local/state/claude-desktop-edamame`

The default local credential file lives inside the package state directory as
`edamame-mcp.psk`.

### Config Fields

| Field | Description | Default |
|---|---|---|
| `workspace_root` | Workspace this package monitors | Current working directory |
| `code_projects_root` | Claude Code-in-Desktop project storage | `~/.claude/projects` |
| `cowork_sessions_root` | Claude Cowork session storage | macOS: `~/Library/Application Support/Claude/local-agent-mode-sessions`, Windows: `%APPDATA%/Claude/local-agent-mode-sessions`, Linux: `~/.local/share/claude-desktop/local-agent-mode-sessions` |
| `agent_type` | Producer name attached to each behavioral-model slice | `claude_desktop` |
| `agent_instance_id` | Stable unique producer instance identifier | `<hostname>-<sha256(workspace)[:12]>` |
| `host_kind` | EDAMAME host type | `edamame_app` on macOS/Windows, `edamame_posture` on Linux |
| `edamame_mcp_endpoint` | Local EDAMAME MCP endpoint | `http://127.0.0.1:3000/mcp` |
| `edamame_mcp_psk_file` | Path to the credential file | `<state_dir>/edamame-mcp.psk` |
| `transcript_project_hints` | Substrings to match project directories for transcript discovery | Auto-inferred from workspace basename |
| `transcript_limit` | Maximum transcripts to process per extrapolation cycle | `6` |
| `transcript_recency_hours` | Only process transcripts modified within this window | `48` |
| `transcript_active_window_minutes` | Minimum recent-activity threshold for a transcript to be considered active | `5` |
| `divergence_interval_secs` | Seconds between automatic divergence verdict refreshes | `120` |
| `verdict_history_limit` | Number of verdict snapshots retained in state | `10` |
| `claude_desktop_llm_hosts` | Known LLM API hosts to exclude from anomaly detection | Anthropic, OpenAI, AWS, Cloudflare, Notion, Microsoft |
| `scope_parent_paths` | Process-tree parent path globs used for session scoping | Claude Desktop app paths, node, bridge script |
| `posture_cli_command` | Path or name of the posture CLI binary (Linux) | `edamame_posture` |
| `debug_bridge_log` | Enable verbose bridge debug logging | `false` |
| `debug_bridge_log_file` | Path for bridge debug log output | `<state_dir>/bridge-debug.log` |

Override the config path by setting the `CLAUDE_DESKTOP_EDAMAME_CONFIG`
environment variable.

## Pairing

Pairing connects the plugin's MCP bridge to the local EDAMAME Security
instance using a pre-shared key (PSK). Until pairing is complete, the bridge
cannot forward transcripts or read verdicts.

### macOS / Windows (host_kind = edamame_app)

1. Start the EDAMAME Security app.
2. Ensure the local MCP server is enabled (port `3000` by default).
3. In Claude Desktop, invoke the `edamame_claude_desktop_control_center` tool
   to open the interactive dashboard.
4. **Primary flow**: Click "Request pairing from app" in the control center.
   The app will prompt for approval. Once approved, the PSK is exchanged
   automatically.
5. **Fallback**: Generate a PSK from the app's MCP controls, copy it, and
   paste it into the control center's manual pairing field.
6. Refresh the control center status. All indicators (MCP endpoint,
   divergence engine, behavioral model) should show healthy.

### Linux (host_kind = edamame_posture)

**Preferred -- auto-pair via control center:**

1. In Claude Desktop, invoke `edamame_claude_desktop_control_center`.
2. Use "Generate, start, and pair automatically".
3. Refresh status until the MCP endpoint, divergence engine, and behavioral
   model checks go healthy.

**Manual fallback:**

1. Generate a PSK:

```bash
edamame_posture mcp-generate-psk
```

2. Start the local MCP endpoint with the same PSK:

```bash
edamame_posture mcp-start 3000 "<PSK>"
```

3. Invoke `edamame_claude_desktop_control_center` in Claude Desktop and paste
   the PSK into the manual pairing field. Save.
4. Refresh status until all indicators are healthy.

## Health Check

The health check validates the full operational path from config to EDAMAME
connectivity:

```bash
bash setup/healthcheck.sh --strict --json
```

Checks performed:

| Check | What it validates |
|---|---|
| config | Local config file exists and is parseable |
| credential | PSK credential file exists and is non-empty |
| mcp_endpoint | EDAMAME MCP endpoint is reachable and responds |
| divergence_engine | Divergence engine is running on the EDAMAME host |
| behavioral_model | A behavioral model has been published for this agent |

Flags:

- `--strict` -- treat a missing behavioral model as a failure (useful for CI).
- `--json` -- emit machine-readable JSON output.
- `--config <path>` -- override the config file path.

Exit code `0` means all checks passed; `1` means at least one check failed.

## Troubleshooting

### MCP bridge not connecting

**Symptom**: Claude Desktop shows the `edamame` MCP server as unavailable or
the control center reports "MCP endpoint unreachable".

1. Verify EDAMAME Security is running. On macOS/Windows check that the app is
   open. On Linux verify the posture daemon:
   ```bash
   edamame-posture status
   ```
2. Confirm the MCP port is listening:
   ```bash
   curl -s http://127.0.0.1:3000/mcp
   ```
3. If the port is different, update `edamame_mcp_endpoint` in your config
   file to match.
4. Restart Claude Desktop after any config change so the MCP bridge
   reinitializes.

### Pairing stuck in "pending"

**Symptom**: The control center shows pairing as pending after requesting it
from the app.

1. Open the EDAMAME Security app and check for a pending pairing approval
   notification. Approve it.
2. If no notification appears, the app may not have its MCP server enabled.
   Open **Settings > MCP** in the app and enable the server.
3. Try the manual fallback: generate a PSK from the app, paste it into the
   control center.

### No behavioral model after pairing

**Symptom**: Health check reports `behavioral_model: FAIL` even though
pairing succeeded.

1. Ensure Claude Desktop has active session transcripts. The extrapolator
   only processes transcripts modified within the `transcript_recency_hours`
   window (default 48 hours).
2. Check that `transcript_project_hints` in the config matches your project
   directory names. The extrapolator uses these hints to locate relevant
   transcript folders under `~/.claude/projects/`.
3. Run the extrapolator manually to debug:
   ```bash
   node service/claude_desktop_extrapolator.mjs --config /path/to/config.json
   ```
4. Verify the EDAMAME host has agentic/LLM capabilities enabled (required for
   raw transcript ingest).

### `env: node: No such file or directory`

Claude Desktop may not inherit your shell's `PATH`. The manual installer
resolves this automatically by writing the absolute `node` path into the
rendered MCP snippet. If using the marketplace plugin path and this error
occurs, ensure `node` is on the system `PATH` or set the `CLAUDE_DESKTOP_EDAMAME_CONFIG`
environment variable pointing to a config with a corrected node path.

### Transcripts not being discovered

The extrapolator searches two locations:

- `~/.claude/projects/` for Code-in-Desktop sessions
- `~/Library/Application Support/Claude/local-agent-mode-sessions/` for
  Cowork sessions

If your transcripts are in a non-standard location, set `code_projects_root`
or `cowork_sessions_root` in the config file.

### Debug logging

Enable verbose bridge logging by setting `debug_bridge_log` to `true` in the
config file. Logs are written to the path specified by `debug_bridge_log_file`
(defaults to `<state_dir>/bridge-debug.log`).

## Configuration Customization

### Transcript Discovery

The extrapolator uses `transcript_project_hints` to match project directories.
By default, hints are auto-inferred from the workspace basename. Add explicit
hints for projects with non-obvious directory names:

```json
{
  "transcript_project_hints": ["my-project", "my-project.code-workspace"]
}
```

### LLM Host Allowlist

`claude_desktop_llm_hosts` lists known LLM API endpoints that should be
excluded from network anomaly detection. Add custom endpoints if you route
through a proxy or use additional providers:

```json
{
  "claude_desktop_llm_hosts": [
    "api.anthropic.com:443",
    "my-llm-proxy.internal.corp:443"
  ]
}
```

Entries are merged with the built-in defaults; you do not need to repeat the
defaults when adding custom hosts.

### Process Scope

`scope_parent_paths` controls which process-tree parent paths are considered
part of the Claude Desktop session for system-plane telemetry scoping. The
defaults cover standard Claude Desktop install locations across macOS,
Windows, and Linux. Override only if your installation uses a non-standard
path.

### Divergence Cadence

Adjust `divergence_interval_secs` to control how frequently the bridge
refreshes the divergence verdict from EDAMAME. Lower values give faster
detection at the cost of more MCP traffic. The default (120 seconds) is
suitable for most interactive development sessions.
