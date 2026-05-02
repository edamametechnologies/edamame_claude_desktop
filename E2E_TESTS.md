# Claude Desktop Intent E2E Test

End-to-end test for the Claude Desktop reasoning-plane pipeline. Synthetic Claude Desktop transcripts are injected into the configured transcript roots, processed by `claude_desktop_extrapolator`, and verified by polling `get_behavioral_model` until the expected `session_key` values appear for the matching contributor.

## What It Validates

1. Provision checks: installed package layout, version alignment, MCP snippet presence, PSK file presence, and Claude Desktop plugin registration checks when enabled.
2. Synthetic transcript generation: creates Desktop-shaped transcript fixtures in the Cowork local-agent-mode root.
3. Extrapolator execution: `claude_desktop_extrapolator.mjs` builds a `RawReasoningSessionPayload` and pushes it to EDAMAME via `upsert_behavioral_model_from_raw_sessions`.
4. Behavioral model polling: `edamame_cli rpc get_behavioral_model` is polled until predictions exist for every injected `session_key` with the expected `agent_type` and `agent_instance_id`.

## Prerequisites

- EDAMAME Security app or `edamame_posture` running with MCP enabled and paired
- Agentic / LLM configured on the EDAMAME side
- `edamame_cli` built or installed
- `node` 18+ and `python3`

## Running Locally

```bash
bash tests/e2e_inject_intent.sh
```

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `EDAMAME_CLI` | auto-detect | Path to `edamame_cli` |
| `CLAUDE_DESKTOP_EDAMAME_CONFIG` | platform default | Override `config.json` path |
| `E2E_SKIP_PLUGIN_CHECK` | `0` | Skip Claude Desktop plugin and settings checks |
| `E2E_SKIP_PROVISION_STRICT` | `0` | Skip installed-package validation and repo/install version checks |
| `E2E_POLL_ATTEMPTS` | `36` | Poll attempts before timeout |
| `E2E_POLL_INTERVAL_SECS` | `5` | Delay between polls |
| `E2E_STRICT_HASH` | `0` | Require exact contributor-hash match |
| `E2E_DIAGNOSTICS_FILE` | unset | Write JSON diagnostics on timeout |
| `E2E_PROGRESS_POLL` | `0` | Print per-poll hints to stderr |
| `CLAUDE_DESKTOP_REPO_ROOT` | repo root | Override repo root used by the script |

## CI Integration

The `test_e2e.yml` workflow runs this test after provisioning the local EDAMAME host, configuring the required agentic inputs, and installing the plugin in the CI environment.

## Full Cross-Agent E2E Suite

The full cross-agent benchmark and trigger harness lives in the public `agent_security` repository under `tests/e2e/`. Use `--agent-type claude_desktop` when exercising the shared harness.
