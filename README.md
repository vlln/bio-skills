<h1 align="center">bio-skills</h1>

<p align="center">
  <strong>Agent Skills for bioinformatics reproduction, container discovery, and research publishing.</strong><br/>
  Reproduce bioinformatics papers, search BioContainers, manage Zenodo deposits, fetch paper dossiers,
  resolve container images, and execute commands on remote machines.
</p>

<p align="center">
  <a href="https://github.com/vlln/bio-skills/stargazers"><img src="https://badgen.net/github/stars/vlln/bio-skills?label=%E2%98%85" alt="GitHub stars" /></a>
  <img src="https://badgen.net/badge/license/MIT/blue" alt="MIT" />
  <img src="https://badgen.net/badge/spec/Agent%20Skills/8257D0" alt="Agent Skills spec" />
</p>

---

## Installation

### [skit](https://github.com/vlln/skit) (Recommended)

```bash
skit install https://github.com/vlln/bio-skills/tree/main/skills/bio-reproducer
skit install https://github.com/vlln/bio-skills/tree/main/skills/biocontainers
skit install https://github.com/vlln/bio-skills/tree/main/skills/zenodo
```

Or install all skills at once:

```bash
skit install https://github.com/vlln/bio-skills/blob/main/skit.json
```

Preview without installing:

```bash
skit install --dry-run https://github.com/vlln/bio-skills/blob/main/skit.json
```

### Manually

| Agent | Command |
|-------|---------|
| **Claude Code** | `cp -r skills/<skill-name> .claude/skills/` |
| **Codex** | `cp -r skills/<skill-name> ~/.codex/skills/` |
| **OpenCode** | `git clone https://github.com/vlln/bio-skills.git ~/.opencode/skills/bio-skills` |
| **Kimi** | `cp -r skills/<skill-name> ~/.kimi/skills/` |

---

## Skills

| Skill | Description |
|-------|-------------|
| [`bio-reproducer`](skills/bio-reproducer/SKILL.md) | Reproduce bioinformatics papers through a logged multi-phase workflow covering planning, bootstrap, provisioning, data acquisition, execution, and validation. |
| [`biocontainers`](skills/biocontainers/SKILL.md) | Search BioContainers, inspect tools, list versions, and resolve full quay.io image tags through the GA4GH TRS API. |
| [`zenodo`](skills/zenodo/SKILL.md) | Search or download Zenodo records and manage authenticated Zenodo deposits through the API. |
| [`paperutils`](https://github.com/vlln/paperutils) | Fetch paper dossiers, search for papers, or explain dataset accessions for biomedical and CS papers. |
| [`quay`](https://github.com/vlln/quay-skill) | Search Quay.io repositories, list image tags, inspect tag metadata, and resolve pullable quay.io image references. |
| [`image-mirror-skill`](https://github.com/vlln/mip) | Accelerate and troubleshoot Docker/OCI image pulls with registry-aware mirror rewrite, probe, pull, and configuration workflows. |
| [`remote-exec-skill`](https://github.com/vlln/remote-exec-skill) | Run repeated shell commands on a remote machine over SSH, including connection checks, stdin scripts, and optional tmux-backed persistent state. |

## Requirements

- Python 3 for the bundled helper scripts.
- Network access to BioContainers, Zenodo, SRA/ENA/GEO, or CrossRef APIs, depending on the skill and task.
- Nextflow plus a container runtime for full `bio-reproducer` pipeline runs.
- `ZENODO_ACCESS_TOKEN` for Zenodo write operations.

## License

MIT