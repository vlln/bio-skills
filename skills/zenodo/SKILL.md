---
name: zenodo
description: Use this skill when you need to search or download Zenodo records, or manage authenticated Zenodo deposits — including creating drafts, editing metadata, uploading files, deleting drafts, and publishing research outputs.
license: MIT
metadata:
  author: vlln
  version: "0.1.0"
requires:
  bins:
    - python3
---

# Zenodo Skill

Interact with the Zenodo API for public record search/download and authenticated deposit management.

## Trigger Keywords

- **zenodo**: Any mention of Zenodo, Zenodo records, Zenodo deposits, or Zenodo API.
- **research data**: Publishing, searching, or downloading research datasets and outputs.
- **deposit**: Managing research deposits, drafts, or upload workflows.
- **DOI**: Minting or managing Digital Object Identifiers for research outputs.

## Workflow

1. For public records, search and download without authentication.
2. For authenticated operations (create, list, show, update, upload, delete, publish), require `ZENODO_ACCESS_TOKEN`.
3. Default to `--sandbox` unless the user explicitly requests production.
4. Before publishing, confirm the deposit ID, metadata, and uploaded files with the user unless they already gave explicit publish approval.

## Capabilities

| Operation | Description |
|-----------|-------------|
| Search public records | Query Zenodo with support for `--type`, `--size`, `--page`, and `--sort`. |
| Download a record | Download files from a public record by ID. Supports `--output` and `--force`. |
| Create a deposit | Create a draft deposit with `--title`, `--description`, `--creators`, and `--keywords`. |
| List deposits | List authenticated deposits. |
| Show deposit details | Show authenticated deposit details by ID. |
| Update deposit metadata | Update draft metadata by ID. |
| Upload a file | Upload one file to a draft deposit by ID. |
| Delete a deposit | Delete a draft deposit by ID. |
| Publish a deposit | Publish a deposit by ID. |

## Gotchas

- **Sandbox first**: Always default to `--sandbox` unless the user explicitly requests production. Sandbox and production are separate Zenodo instances with their own tokens.
- **Publishing is irreversible**: Once a deposit is published, its metadata and files cannot be changed. A DOI is minted at publish time.
- **Draft expiration**: Unpublished drafts on Zenodo may expire after a period of inactivity. Do not assume drafts persist indefinitely.
- **Token separation**: Sandbox and production tokens are different. Create sandbox tokens at `https://sandbox.zenodo.org/account/settings/applications`, production tokens at `https://zenodo.org/account/settings/applications`.
- **File uploads to drafts only**: Files can only be uploaded to unpublished drafts. Once published, the record is read-only.
- **Metadata requirements**: Zenodo requires at minimum a title, description, and creators for publishing. Do not invent missing metadata — ask the user.
- **Rate limiting**: Zenodo enforces API rate limits. For bulk operations, add delays between requests.

## Output

For searches and downloads, report record IDs, titles, and local output paths. For deposit changes, report the deposit ID, environment (`production` or `sandbox`), and the action completed.