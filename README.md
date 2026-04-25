# bio-skills

Agent Skills for BioContainers discovery and Zenodo research repository
publishing workflows.

This repository stores skills under `skills/`. Each skill follows the
[Agent Skills specification](https://agentskills.io/specification) and can be
used by skills-compatible agents.

## Skills

| Skill | Description |
|-------|-------------|
| [`biocontainers`](skills/biocontainers) | Search BioContainers, inspect tools, list versions, and resolve full quay.io image tags through the GA4GH TRS API. |
| [`zenodo`](skills/zenodo) | Search or download Zenodo records and manage authenticated Zenodo deposits through the API. |

## Installation

Recommended: install these skills with `skit`. It fetches skills from the
published repository, keeps a lock file, and can diagnose declared
requirements.

### skit

Install `skit` with Homebrew:

```sh
brew install --cask vlln/tap/skit
```

For other platforms, see the
[skit installation instructions](https://github.com/vlln/skit#installation).

Install one skill:

```sh
skit install --global vlln/bio-skills/skills/biocontainers
skit install --global vlln/bio-skills/skills/zenodo
```

Install all skills in this repository:

```sh
skit install --global vlln/bio-skills --all
```

### Manual

Copy `skills/biocontainers` or `skills/zenodo` into your agent's skills
directory, then restart the agent if required.

Common locations:

- Codex CLI: `~/.codex/skills`
- Claude Code: `.claude/skills` in the project, or the configured user skills directory
- OpenCode: `~/.opencode/skills/bio-skills`

## Requirements

- Python 3 for the bundled helper scripts.
- Network access to BioContainers or Zenodo APIs.
- `ZENODO_ACCESS_TOKEN` for Zenodo write operations.

## License

No repository license file is currently included.
