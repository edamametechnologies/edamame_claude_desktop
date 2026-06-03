# Architecture

`edamame_claude_desktop` is the Claude Desktop workstation package in the EDAMAME agent-plugin family. It bridges Claude Desktop reasoning artifacts to the local EDAMAME host so EDAMAME can correlate expected behavior against observed system activity.

## Runtime Model

1. Claude Desktop produces Cowork session transcripts under the platform-specific local-agent-mode sessions directory.
2. `adapters/session_prediction_adapter.mjs` discovers recent transcripts and converts them into `RawReasoningSessionPayload`.
3. `service/claude_desktop_extrapolator.mjs` forwards the raw payload to the local EDAMAME MCP endpoint via `upsert_behavioral_model_from_raw_sessions`.
4. EDAMAME generates or updates the merged behavioral model, evaluates divergence, and exposes read-only posture and verdict state.
5. `bridge/claude_desktop_edamame_mcp.mjs` exposes the local control-center, healthcheck, posture-summary, and EDAMAME passthrough tools to Claude Desktop.

> **External transcript observer (additive, no change in this repo).** Starting with `edamame_core` 1.2.3, EDAMAME runs its own observer that reads the same Cowork (`local-agent-mode-sessions/`) transcript root directly and feeds the same `upsert_behavioral_model_from_raw_sessions` pipeline. The observer is the security primitive: divergence detection works as soon as Claude Desktop is **discovered** on disk, regardless of whether this Node-side package is installed. When the package **is** installed, its bridge also pushes models in-process and the observer hash-skips on duplicate payloads -- so the two paths are purely additive and this repo's install / MCP / pairing flow is unchanged. Operators can pause / resume / run-now per agent from the EDAMAME app's AI / Config tab. When the observer is paused while Claude Desktop is discovered on disk, EDAMAME's `unsecured_claude_desktop` internal threat trips on the next score cycle. Claude Code project transcripts under `~/.claude/projects/` are owned by the Claude Code integration to avoid double-counting the same intent as two agents.

## Observer vs plugin: the value boundary

The two paths above are **not** peers, and conflating them in either
direction is wrong: this package is neither the security control nor dead
weight.

| | EDAMAME host-side observer | This package (reasoning plane) |
|---|---|---|
| Role | **Security control of record** | **Cooperative enhancement** |
| Trust model | Observer-independent: runs in the system plane, so a compromised Claude Desktop cannot pause, blind, or silence it | Cooperative: Claude Desktop voluntarily declares intent; it can only *add* signal, never *weaken* a verdict |
| Needs | Claude Desktop's transcripts readable on the host (Claude Desktop **discovered** on disk) | Claude Desktop itself running this MCP bridge |
| Provides the guarantee? | **Yes** -- divergence detection works with zero plugin installed | **No** -- it adds coverage and convenience only |

The package earns its place in two ways, neither of which is the
guarantee itself:

- **Off-host coverage.** When Claude Desktop runs where the host observer
  cannot read its transcripts -- a remote box, SSH session, container, CI
  runner, VM, or a different user account -- this in-process bridge is the
  *only* path that delivers the behavioral model to EDAMAME.
- **Cooperative onboarding and UX.** MCP-native discovery, pairing, the
  in-agent read-only posture/verdict surface, health checks, intent
  export, and security-awareness rules and skills -- the turnkey ramp that
  gets a workstation monitored and lets the developer see verdicts from
  inside Claude Desktop.

Corollary: a security *decision* never moves into the package. Dismissing
findings, clearing divergence state, or any verdict-mutating capability
stays operator-only on the EDAMAME side (the MCP observer-independence
policy). The package observes and onboards; it never adjudicates.

## Host Modes

| Platform | Host of record | Notes |
|---|---|---|
| macOS / Windows | EDAMAME Security app | App-mediated pairing is the preferred path |
| Linux | `edamame_posture` | Local CLI/daemon hosts the MCP endpoint |

## Package Layout

| Path | Responsibility |
|---|---|
| `bridge/claude_desktop_edamame_mcp.mjs` | stdio MCP bridge, tool registration, control-center resource, refresh hooks |
| `bridge/edamame_client.mjs` | local HTTP MCP client for the EDAMAME host |
| `adapters/session_prediction_adapter.mjs` | transcript discovery, parsing, derived hint extraction, raw-session payload build |
| `service/claude_desktop_extrapolator.mjs` | raw-session ingest orchestration, repush/recovery behavior |
| `service/control_center.mjs` | pairing, status, host actions, control-center payload |
| `service/health.mjs` | config, credential, endpoint, divergence-engine, and model health checks |
| `service/posture_facade.mjs` | compact read-only posture and verdict summary |
| `service/verdict_reader.mjs` | CLI-readable verdict and score output |
| `service/config.mjs` | config loading, path resolution, state persistence |
| `setup/install.sh` / `setup/install.ps1` | per-user installation, config rendering, MCP registration |
| `tests/` | adapter, bridge, health, retry/recovery, and intent-injection coverage |

## MCP Surface

The bridge exposes three groups of tools:

- Claude Desktop local tools such as `claude_desktop_refresh_behavioral_model`, `claude_desktop_healthcheck`, and `claude_desktop_posture_summary`
- Control-center tools prefixed with `edamame_claude_desktop_control_center`
- Read-only EDAMAME passthrough tools such as `edamame_get_divergence_verdict`, `edamame_get_score`, and `edamame_get_sessions`

The control-center UI is served as the resource `ui://edamame/control-center.html`.

## Identity and Recovery

- Every behavioral-model slice uses `agent_type=claude_desktop`.
- `agent_instance_id` is stable per workstation or workspace depending on install input.
- The extrapolator keeps local state so it can avoid redundant pushes, retry transient LLM parse failures, and repush the last contributor when the remote store is empty after a host restart.
- When no active sessions remain, the package can republish a cached or heartbeat-style window so Claude Desktop still has an attributable contributor slice on the EDAMAME side.

## Design Goals

- Keep EDAMAME as the single source of truth for posture, telemetry, and divergence state.
- Keep the package local-state footprint limited to operational metadata such as config, PSK, and last extrapolation state.
- Prefer app-mediated pairing on workstations, but keep Linux usable through `edamame_posture`.
- Match the Cursor and Claude Code workstation bridge contract closely enough that drift is caught by tests and workflow checks.
