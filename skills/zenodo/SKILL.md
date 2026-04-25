---
name: zenodo
description: Search and download Zenodo records, and manage authenticated Zenodo deposits through the API, including drafts, metadata, files, deletion, and publishing.
compatibility: Requires Python 3, network access to Zenodo, and ZENODO_ACCESS_TOKEN for write operations.
metadata:
  skit:
    version: 0.1.0
    requires:
      bins:
        - python3
    keywords:
      - zenodo
      - research-data
      - deposits
      - doi
---

# Zenodo Skill

Interact with the Zenodo API through the bundled CLI for public record search/download and authenticated deposit management.

## When To Use

Use this skill for Zenodo-specific work: finding public records, downloading record files, listing deposits, creating draft deposits, editing metadata, uploading files, deleting drafts, and publishing deposits.

## Workflow

1. Resolve this skill directory and run the bundled `scripts/zenodo` helper from there; do not assume `zenodo` is already on `PATH`.
2. Use `search` and `download` without a token for public records.
3. Require `ZENODO_ACCESS_TOKEN` before `create`, `list`, `show`, `update`, `upload`, `delete`, or `publish`.
4. Use `--sandbox` for tests, dry runs, examples, or any workflow where the user has not explicitly asked to modify production Zenodo.
5. Before `publish`, confirm the target deposit ID, metadata, and uploaded files with the user unless they already gave explicit publish approval.

## Commands

| Command | Description |
|---------|-------------|
| `scripts/zenodo search [query]` | Search public records. Supports `--type`, `--size`, `--page`, and `--sort`. |
| `scripts/zenodo download <record-id>` | Download files from a public record. Supports `--output` and `--force`. |
| `scripts/zenodo create` | Create a draft deposit. Supports `--title`, `--description`, `--creators`, and `--keywords`. |
| `scripts/zenodo list` | List authenticated deposits. |
| `scripts/zenodo show <deposit-id>` | Show authenticated deposit details. |
| `scripts/zenodo update <deposit-id>` | Update draft metadata. |
| `scripts/zenodo upload <deposit-id> <file>` | Upload one file to a draft deposit. |
| `scripts/zenodo delete <deposit-id>` | Delete a draft deposit. |
| `scripts/zenodo publish <deposit-id>` | Publish a deposit. |

Global options: `--sandbox`, `--no-verify`, and `--help`.

## Examples

```bash
scripts/zenodo search "machine learning" --size 10
scripts/zenodo download 12345 --output ./downloads
scripts/zenodo --sandbox create --title "My Research" --description "Description here"
scripts/zenodo --sandbox upload 12345 ./myfile.zip
scripts/zenodo --sandbox publish 12345
```

## Rules

- Treat production write operations as persistent external changes.
- Never invent missing deposit metadata; ask for required title, description, creators, or files when absent.
- Do not use this skill for non-Zenodo repositories or browser-only workflows.
- Use `scripts/.env.example` only as a template for the required token name; do not write secrets into the skill repository.
- For production tokens, users can create tokens at `https://zenodo.org/account/settings/applications`; for sandbox tokens, use `https://sandbox.zenodo.org/account/settings/applications`.

## Output

For searches and downloads, report record IDs, titles, and local output paths. For deposit changes, report the deposit ID, environment (`production` or `sandbox`), and the action completed.
