# TODO: Convert to Bash

## Overview

Rewrite `main.ps1` and `Send-SlackMessage.ps1` as a single bash script (`main.sh`).
The action already uses bash for the `secrets` step, and all dependencies (`gh`, `jq`, `curl`) are pre-installed on all GitHub-hosted runners.

## Why bash

- No `pwsh` dependency — works on Linux/macOS self-hosted runners without extra setup
- Already used in the `secrets` step of `action.yml`
- `gh`, `jq`, `curl` are pre-installed on all GitHub-hosted runners (Linux, macOS, Windows via Git Bash)
- Simpler to maintain — one language across the entire action

## What needs to be ported

### From `main.ps1`
- Read `INPUT_*` environment variables
- Parse `INPUT_GITHUB_CONTEXT` JSON via `jq`
- Call `gh api` to get job ID (first job in the run)
- Build raw log and HTML log URLs from templates
- Build Slack Block Kit JSON with `jq`
- If `TESTMODE` is set, output JSON; otherwise POST to Slack

### From `Send-SlackMessage.ps1`
- `send-SlackMessage` → `curl -X POST` with JSON body
- `split-message` → split `CONTENT` into 3000-char chunks (bash string slicing or `fold`)
- `write-SlackMessageBody` → build blocks array with `jq`

## Key considerations

- **Message chunking**: Slack has a 3000-char limit per section. Need to split `CONTENT` into chunks. Use `jq -R` to read raw input and build the array.
- **JSON building**: Use `jq` with `--arg` / `--jsonargs` to construct the Block Kit payload natively — no string concatenation.
- **TESTMODE**: Check if `INPUT_TESTMODE` is non-empty; if so, just print the JSON.
- **Error handling**: `gh api` and `curl` should check exit codes. Add `set -euo pipefail` at the top.
- **Debug output**: Replace `write-debug` / `write-output` with `echo` (or a helper function that checks a DEBUG flag).

## `action.yml` changes

- Replace `shell: pwsh` with `shell: bash` on the step that runs the script
- Change `./action-repo/main.ps1` to `./action-repo/main.sh`
- Remove the checkout of `air-ltd/slackpost` if not needed (the composite action already checks out the repo)

## Testing

- Ensure `test.yml` still passes after the conversion
- Verify TESTMODE output matches the expected Slack Block Kit JSON structure
- Test with long messages (>3000 chars) to confirm chunking works
- Test with special characters in content (single quotes, backticks, emoji)

## Cleanup after conversion

- Delete `main.ps1` and `Send-SlackMessage.ps1`
- Remove any PowerShell-specific devcontainer setup (already done)
