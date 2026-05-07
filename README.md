# bio-skills

Agent Skills for bioinformatics reproduction, BioContainers discovery, and
Zenodo research repository publishing workflows.

This repository stores skills under `skills/`. Each skill follows the
[Agent Skills specification](https://agentskills.io/specification) and can be
used by skills-compatible agents.

## Skills

| Skill | Description |
|-------|-------------|
| [`bio-reproducer`](skills/bio-reproducer) | Reproduce bioinformatics papers through a logged multi-phase workflow covering planning, bootstrap, provisioning, data acquisition, execution, and validation. |
| [`biocontainers`](skills/biocontainers) | Search BioContainers, inspect tools, list versions, and resolve full quay.io image tags through the GA4GH TRS API. |
| [`zenodo`](skills/zenodo) | Search or download Zenodo records and manage authenticated Zenodo deposits through the API. |
| [`paperutils`](https://github.com/vlln/paperutils.git) | Fetch paper dossiers, search for papers, or explain dataset accessions for biomedical and CS papers. |
| [`quay`](https://github.com/vlln/quay-skill.git) | Search Quay.io repositories, list image tags, inspect tag metadata, and resolve pullable quay.io image references for public or token-visible containers. |
| [`image-mirror-skill`](https://github.com/vlln/mip.git) | Accelerate and troubleshoot Docker/OCI image pulls with registry-aware mirror rewrite, probe, pull, and configuration workflows. |
| [`remote-exec-skill`](https://github.com/vlln/remote-exec-skill.git) | Run repeated shell commands on a remote machine over SSH, including connection checks, stdin scripts, and optional tmux-backed persistent state. |


## Installation

Recommended: install these skills with [`skit`](https://github.com/vlln/skit).
It fetches skills from their published sources, records them in one local
manifest, and activates symlinks for your agents.

### Install skit

```sh
# macOS / Linux via installer
curl -fsSL https://raw.githubusercontent.com/vlln/skit/main/install.sh | sh

# Or via Homebrew
brew install vlln/tap/skit

# Or from source
go install github.com/vlln/skit@latest
```

### Install skills from this repository

Install one skill by name:

```sh
skit install vlln/bio-skills/skills/bio-reproducer
skit install vlln/bio-skills/skills/biocontainers
skit install vlln/bio-skills/skills/zenodo
```

Install all skills in this repository at once:

```sh
skit install https://github.com/vlln/bio-skills/blob/main/skit.json
```

Preview without installing:

```sh
skit install --dry-run https://github.com/vlln/bio-skills/blob/main/skit.json
```

Search across the skills.sh ecosystem:

```sh
skit search biocontainers
skit search "paper doi"
```

List what is installed:

```sh
skit list
```

Update installed skills from their sources:

```sh
skit update
```

### Manual

Copy `skills/bio-reproducer`, `skills/biocontainers`, or `skills/zenodo` into
your agent's skills directory, then restart the agent if required.

Common locations:

- Codex CLI: `~/.codex/skills`
- Claude Code: `.claude/skills` in the project, or the configured user skills directory
- OpenCode: `~/.opencode/skills/bio-skills`

## Requirements

- Python 3 for the bundled helper scripts.
- Network access to BioContainers, Zenodo, SRA/ENA/GEO, or CrossRef APIs,
  depending on the skill and task.
- Nextflow plus a container runtime for full `bio-reproducer` pipeline runs.
- `ZENODO_ACCESS_TOKEN` for Zenodo write operations.

## License

No repository license file is currently included.
