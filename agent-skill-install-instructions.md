# Diagnostics Report Analyzer Skill Installation

The Diagnostics Report Analyzer Skill helps AI agents inspect `Diagnostics-Report.html` attachments by reading the embedded JSON payload first, while still understanding legacy HTML-only and mixed-format reports.

## Recommended: skills.sh

Install the skill with `npx skills`:

```bash
npx skills add https://github.com/AvdLee/Diagnostics --skill diagnostics-report-analyzer-skill
```

Then ask your agent to use it when analyzing a report:

```text
Use the diagnostics report analyzer skill to inspect Diagnostics-Report.html and summarize the most likely issue.
```

## Claude Code Plugin

This repository includes a Claude plugin manifest in `.claude-plugin/`.

For personal use in Claude Code:

1. Add this repository as a marketplace:

```bash
/plugin marketplace add AvdLee/Diagnostics
```

2. Install the plugin:

```bash
/plugin install diagnostics-report-analyzer@diagnostics-report-analyzer-skill
```

For project configuration, add the plugin to your repository's `.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "diagnostics-report-analyzer@diagnostics-report-analyzer-skill": true
  },
  "extraKnownMarketplaces": {
    "diagnostics-report-analyzer-skill": {
      "source": {
        "source": "github",
        "repo": "AvdLee/Diagnostics"
      }
    }
  }
}
```

Claude Code will prompt contributors to install the plugin when they open the project.

## Cursor Plugin

This repository includes a Cursor plugin manifest in `.cursor-plugin/plugin.json`.

Install or enable it using Cursor's plugin support, then ask Cursor to use the `diagnostics-report-analyzer-skill` when inspecting Diagnostics report attachments. See the [Cursor plugins documentation](https://cursor.com/docs/plugins) and [Cursor skills documentation](https://cursor.com/docs/context/skills#enabling-skills) for the latest installation flow.

## OpenAI-Compatible Tools and Codex

This repository includes OpenAI-compatible manifests at:

- `openai.yml`
- `agents/openai.yaml`

For tools that use local skill folders, copy or symlink the skill folder into your tool's skills directory:

```bash
cp -R diagnostics-report-analyzer-skill/ "$CODEX_HOME/skills/diagnostics-report-analyzer-skill"
```

See the [Codex skills documentation](https://developers.openai.com/codex/skills/) for where your client expects skills to be saved.

## pi Package Manager

This repository includes `package.json` metadata for pi-compatible skill installation:

```bash
pi install https://github.com/AvdLee/Diagnostics
```

The skill will be available automatically in pi sessions that load the package.

## Generic Plugin Manifest

Clients that support generic plugin discovery can read `plugins.json`. It points to:

```text
diagnostics-report-analyzer-skill/
```

Use this path as the canonical skill folder for any client that supports the Agent Skills open format.

## Manual Installation

1. Clone this repository.
2. Install or symlink `diagnostics-report-analyzer-skill/` into your AI client's skills directory.
3. Ask your agent to use the Diagnostics Report Analyzer Skill when inspecting `.html` report attachments.

To verify installation, ask your agent to inspect a Diagnostics report and confirm it reads `script#diagnostics-report-data` before falling back to rendered HTML.
