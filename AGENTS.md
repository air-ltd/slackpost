# AGENTS.md

## Overview

This is a GitHub composite action that posts Slack notifications with links to GitHub Actions workflow logs. It runs as a composite action using PowerShell.

## Architecture

The action is a **composite action** (not Docker). It has three steps in `action.yml`:

1. **Checkout** - Clones the `air-ltd/slackpost` repo itself into `./action-repo`
2. **secrets** - Bash step that maps all inputs to environment variables (prefixed `INPUT_`) and writes `GITHUB_CONTEXT` to `$GITHUB_ENV` using a heredoc
3. **step 1** - Runs `./action-repo/src/main.ps1` in PowerShell

### Key files

- `action.yml` - Composite action definition with input declarations
- `src/main.ps1` - Main entry point. Queries GitHub API for job info, builds Slack message body, posts to Slack
- `src/Send-SlackMessage.ps1` - Helper functions: `send-SlackMessage`, `split-message`, `write-SlackMessageBody`
- `.github/workflows/test.yml` - Regression test workflow that runs on push to main and manual dispatch

## Context passing (critical)

The action reads `${{ github }}` directly -- users do **not** pass a `GITHUB_CONTEXT` input.

**Problem that was solved:** If `GITHUB_CONTEXT` were passed inline in shell (e.g. `echo "${{ inputs.GITHUB_CONTEXT }}"`), single quotes from PR bodies break PowerShell strings, and backticks are interpreted as command substitution by bash.

**Solution (in `action.yml`):** The GitHub context is mapped to an environment variable via `env:`, then read with `printenv`:

```yaml
env:
  GH_CTX: ${{ toJson(github) }}
run: |
  echo "INPUT_GITHUB_CONTEXT<<GITHUB_CONTEXT_EOF" >> $GITHUB_ENV
  printenv GH_CTX >> $GITHUB_ENV
  echo "GITHUB_CONTEXT_EOF" >> $GITHUB_ENV
```

This completely bypasses shell string interpretation. This approach must be preserved if modifying `action.yml`.

## TESTMODE behavior

When `TESTMODE` is set to `'true'` (case insensitive), `main.ps1` outputs the JSON message body but does **not** post to Slack. When `TESTMODE` is empty/unset or any other value, it posts to Slack.

## `main.ps1` details

- Reads all config from `INPUT_*` environment variables (set by `action.yml`)
- Combines `INPUT_CONTENT` and `INPUT_CONTENT_FILE` (if file exists) into the message body
- Queries `gh api` for the first job's ID in the workflow run to build log URLs
- Calls `write-SlackMessageBody` to build Slack Block Kit JSON
- If `TESTMODE` is falsy, posts via `send-SlackMessage`

### Slack message format (Block Kit)

- Header section: `workflow_name #run_number/job_name`
- Divider
- Content sections (message split into 3000-char chunks)
- Divider
- Log links: Raw logs and HTML logs

## Test workflow (`test.yml`)

Runs on push to main and manual dispatch. Steps:

1. Fetches `SLACK_POST_URL` from Bitwarden Secrets Manager
2. Tests `CONTENT_FILE`, `CONTENT`, and combined content in TESTMODE
3. Computes pass/fail step counts via `gh api` + `jq` and posts a summary to Slack

### Workflow summary counting

The summary step queries the GitHub API for all jobs in the run, then counts step conclusions:

```bash
passed=$(echo "$jobs_json" | jq '[.jobs[].steps[].conclusion] | map(select(. == "success")) | length')
failed=$(echo "$jobs_json" | jq '[.jobs[].steps[].conclusion] | map(select(. == "failure")) | length')
total=$(echo "$jobs_json" | jq '[.jobs[].steps[].conclusion] | map(select(. != null)) | length')
```

Only completed steps (non-null conclusion) are counted in the denominator. Pending/running steps are excluded.

## Secrets

- `SLACK_POST_URL` - Stored in Bitwarden Secrets Manager, fetched via `bitwarden/sm-action`
- `BW_ACCESS_TOKEN` - GitHub secret for Bitwarden access
- `GITHUB_TOKEN` - Passed via `env:` on the step (not an action input), used by `gh api`

## Versioning

Releases are tagged (v1, v2, v3, v4, v5, ...). Consumers reference as `air-ltd/slackpost@v5`. The `main` branch is the development branch and also used directly in the test workflow for testing.

## Project notes

- `.project/todo.md` - Conversion plan from PowerShell to bash
