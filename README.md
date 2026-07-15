# slackpost

A GitHub Action that posts Slack notifications with links to GitHub Actions workflow logs.

## Usage

```yaml
- name: Notify Slack
  uses: air-ltd/slackpost@v5
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  with:
    SLACKURL: ${{ secrets.SLACK_POST_URL }}
    RUNNER: ${{ runner.environment }}
```

## Inputs

| Input | Required | Description |
|---|---|---|
| `SLACKURL` | Yes | Slack incoming webhook URL |
| `RUNNER` | No | `${{ runner.environment }}` (self-hosted vs github-hosted) |
| `CONTENT` | No | Text to include in the Slack message |
| `CONTENT_FILE` | No | Path to a file whose contents are included in the Slack message |
| `TESTMODE` | No | Set to `'true'` (case insensitive) to output JSON without posting to Slack |
| `SUPPRESS_VERSION_WARNING` | No | Set to `'true'` to suppress the update warning when a newer version is available |

`GITHUB_TOKEN` is read from the environment (set via `env:` on the step). It is not an action input.

## What it posts

The Slack message includes:

- **Header** - Workflow name, run number, and job name
- **Content** - Any `CONTENT` / `CONTENT_FILE` text (supports long messages, automatically split into 3000-char chunks)
- **Log links** - Direct links to raw logs and HTML logs for the job

## How it works

The action reads the GitHub context (`${{ github }}`) automatically and queries the API for job details to build log URLs. Special characters (single quotes, backticks) in event payloads are handled safely via `env:` + `printenv` in the composite action, avoiding shell interpretation issues.

By default, the action checks if a newer version is available on the same ref and emits a warning if so. Set `SUPPRESS_VERSION_WARNING: 'true'` to disable this check.

## Testing

The test workflow (`.github/workflows/test.yml`) runs on push to `main` and manual dispatch. It:

1. Tests `CONTENT_FILE`, `CONTENT`, and combined content in TESTMODE
2. Computes pass/fail step counts and posts a summary to Slack (TESTMODE: false)

## Secrets

- `SLACK_POST_URL` - Slack incoming webhook URL (stored in Bitwarden Secrets Manager)
- `BW_ACCESS_TOKEN` - Bitwarden Secrets Manager access token
- `GITHUB_TOKEN` - Standard GitHub token, auto-provided

## Versioning

Releases are tagged (v1, v2, v3, v4, v5, ...). Reference as `air-ltd/slackpost@v5`.
