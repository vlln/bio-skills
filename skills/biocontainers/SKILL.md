---
name: biocontainers
description: Search BioContainers, inspect bioinformatics container metadata, list available versions, and resolve full quay.io image tags through the GA4GH TRS API.
compatibility: Requires Python 3 and network access to the BioContainers GA4GH TRS API.
metadata:
  skit:
    version: 0.1.0
    requires:
      bins:
        - python3
    keywords:
      - bioinformatics
      - containers
      - ga4gh-trs
      - biocontainers
---

# Biocontainers Skill

Query the [BioContainers Registry](https://biocontainers.pro/) through the bundled GA4GH Tool Registry Service (TRS) CLI.

## When To Use

Use this skill for BioContainers discovery tasks: finding tools by keyword, checking whether a named tool exists, listing its versions, and resolving the exact `quay.io/biocontainers/<tool>:<version>--<build>` image tag.

## Workflow

1. Resolve this skill directory and run the bundled `scripts/biocontainers` helper from there; do not assume `biocontainers` is already on `PATH`.
2. Search first when the exact BioContainers tool name is uncertain.
3. Use `inspect <tool>` for registry metadata and the latest version summary.
4. Use `inspect <tool>:<version>` when the user needs full image tags for a specific version.
5. Use `versions <tool>` when the user only needs available upstream versions.

## Commands

| Command | Description |
|---------|-------------|
| `scripts/biocontainers search <query> [--limit <n>]` | Search containers by keyword. |
| `scripts/biocontainers inspect <tool>` | Show tool details and latest version summary. |
| `scripts/biocontainers inspect <tool>:<version>` | Show specific version details and image tags. |
| `scripts/biocontainers versions <tool>` | List known versions for a tool. |

## Examples

```bash
scripts/biocontainers search bwa
scripts/biocontainers search aligner --limit 10
scripts/biocontainers inspect samtools
scripts/biocontainers inspect bwa:0.7.17
scripts/biocontainers versions blast
```

## Rules

- Prefer `inspect <tool>:<version>` over `versions <tool>` when the final answer needs a runnable image reference.
- Report full `quay.io/biocontainers/...` tags exactly as returned by the API.
- Do not use this skill for generic Docker Hub searches or for running containers locally.
- If the API endpoint must be overridden, set `BIOCONTAINERS_API_URL`; otherwise use the default `https://api.biocontainers.pro/ga4gh/trs/v2`.

## Output

Summarize the matching tool, relevant versions, and exact image tag or command the user can use next. Include uncertainty when a search returns multiple plausible tools.
