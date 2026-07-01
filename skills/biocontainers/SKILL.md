---
name: biocontainers
description: Use this skill when searching for bioinformatics containers, inspecting BioContainers metadata, listing available tool versions, or resolving full quay.io image tags through the GA4GH TRS API.
license: MIT
metadata:
  author: vlln
  version: "0.1.0"
requires:
  bins:
    - python3
---

# Biocontainers Skill

Query the [BioContainers Registry](https://biocontainers.pro/) through the GA4GH Tool Registry Service (TRS) API.

## Trigger Keywords

- **Domain terms:** biocontainers, BioContainers, bioinformatics container, containerized bioinformatics tool
- **Image references:** quay.io/biocontainers, bioinformatics Docker image
- **API terms:** GA4GH TRS, TRS API, Tool Registry Service
- **Workflow:** find bioinformatics tool container, look up container version, resolve image tag

## Capabilities

| Capability | Description |
|-----------|-------------|
| Search | Find containers by keyword (e.g., tool name, function). |
| Inspect | Show tool metadata and the latest version summary. |
| Inspect (version) | Show details for a specific version, including the full image tag. |
| List versions | Enumerate all known upstream versions for a tool. |

### Workflow

1. Search first when the exact BioContainers tool name is uncertain.
2. Inspect a tool for registry metadata and the latest version summary.
3. Inspect a specific version when the user needs full `quay.io/biocontainers/…` image tags.
4. List versions when the user only needs available upstream versions.

Prefer inspecting a specific version over listing versions when the final answer needs a runnable image reference.

## Gotchas

- **Version tags include build hashes.** A BioContainers image tag is not just a semantic version — it uses the format `<version>--<build>` (e.g., `0.7.17--h5bf99c6_12`). The `--` separator is part of the BioContainers convention.
- **Multiple entries per tool.** Some tools have separate BioContainers entries from different conda channels. When a search returns multiple plausible tools, present the ambiguity and let the user choose.
- **API version.** The BioContainers API follows GA4GH TRS **v2**, not v1. Endpoints and response schemas differ.
- **API base URL.** The default endpoint is `https://api.biocontainers.pro/ga4gh/trs/v2`. Override with `BIOCONTAINERS_API_URL` only when necessary.
- **Not for Docker Hub.** BioContainers images live on `quay.io`, not Docker Hub. Do not use this skill for generic Docker Hub searches or for running containers locally.

## Output

Summarize the matching tool, relevant versions, and the exact image tag or command the user can use next. Report full `quay.io/biocontainers/…` tags exactly as returned by the API. Include uncertainty when a search returns multiple plausible tools.