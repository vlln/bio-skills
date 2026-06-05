---
name: bio-reproducer
description: Guide agents through reproducible bioinformatics paper reproduction using a logged multi-phase workspace, async long-running tasks, staged reports, data manifests, Nextflow orchestration, and validation.
compatibility: Requires Bash and Python 3 for helper scripts; Nextflow, a container runtime, and network access are needed only for phases that use them.
metadata:
  skit:
    version: 0.4.2
    requires:
      bins:
        - bash
        - python3
        - paperutils
    keywords:
      - bioinformatics
      - reproducibility
      - nextflow
      - paper-reproduction
---

# Bio-Reproducer

## When To Use

Use this skill to reproduce bioinformatics papers inside a project workspace
with phase-by-phase reports, data manifests, async long-running commands, and a
final validation report. Do not use it for quick tool lookup or generic
bioinformatics advice.

## Core Protocol

The filesystem is the state machine. `repro-data/execution_log.md` is the
state log. Recover by reading files, not by relying on chat memory.

1. Ensure `repro-data/` exists and work inside it for all reproduction state.
2. Initialize Git only inside `repro-data/` when `.git/` is absent.
3. Ensure `reproduction_options.md` exists before Phase 1. This file locks
   global options that later agents must read and must not silently change.
4. Read `execution_log.md`, then check `.task_status/` for submitted async
   tasks before starting new work.
5. Load the reference file for the current phase.
6. Read all completed prior phase outputs required by the current phase.

Small throwaway temp files may use `/tmp/`. Reproduction data, downloads,
Nextflow work directories, and results must stay under `repro-data/` or an
explicitly user-approved data/scratch path.

## Phase Map

| Phase | Output | Reference | Execution |
|-------|--------|-----------|-----------|
| 1 Reader | `01_plan/plan.md` | `references/01_reader.md` | Resource collection and extraction |
| 2 Bootstrap | `02_bootstrap/bootstrap.md` | `references/02_bootstrap.md` | Mixed; long-running setup async |
| 3 Provision | `03_provision/provision.md` | `references/03_provision.md` | Mixed; container/Nextflow operations async |
| 4 Data | `04_data/data_manifest.md` | `references/04_data.md` | Mixed; downloads/Nextflow operations async |
| 5 Run | `05_run/run_results.md` | `references/05_run.md` | Mixed; Nextflow orchestration runs async; optional figure generation |
| 6 Validate | `06_validate/report.md` | `references/06_validate.md` | Manual/automated comparison; optional figure validation |
| 7 Package | `README.md`, `run.sh`, `.gitignore` | `references/07_package.md` | Write README, entrypoint script, and gitignore |

State rules:

- No `reproduction_options.md`: create it before starting Phase 1, then log
  `Phase 1 - INFO: reproduction options initialized`.
- No `execution_log.md`: start Phase 1.
- Last log is `Phase N - SUBMITTED: ...`: check `.task_status/` and task logs.
- Last log is `Phase N - COMPLETED: ...` and output exists: start Phase N+1.
- Last log is `Phase N - FAILED: ...`: diagnose, retry, or rollback.
- `06_validate/report.md` exists and verdict is REPRODUCED/PARTIAL: start Phase 7.
- `README.md`, `run.sh`, and `.gitignore` exist: reproduction complete.

## Phase Handoff

Phase handoff is through explicit reports and manifests, not chained Nextflow
config inheritance.

- New agents must read `execution_log.md` and required outputs from completed
  prior phases.
- `nextflow.config` files are optional runtime configuration only; never treat
  them as the source of truth for prior phase accomplishments.
- If shared Nextflow settings are needed, create
  `02_bootstrap/nextflow.base.config`. Later phase configs may include that
  base file, but must not inherit another phase's config wholesale.

Key state files:

- `reproduction_options.md`
- `execution_log.md`
- `.task_status/{task}.status`, `.pid`, `.pgid`, `.log`
- `01_plan/plan.md`
- `02_bootstrap/bootstrap.md`
- `03_provision/provision.md`
- `04_data/data_manifest.md`
- `05_run/run_results.md`
- `06_validate/report.md`
- `README.md`
- `run.sh`
- `.gitignore`

## Logging

Log meaningful actions with:

`Phase N - STATUS: message`

Use these status values:

| Status | Use |
|--------|-----|
| `START` | A meaningful action began. |
| `END` | A meaningful action ended with `SUCCESS` or `FAILED`. |
| `SUBMITTED` | An async task was submitted. |
| `COMPLETED` | A phase completed and its required output exists. |
| `FAILED` | A phase or task failed. |
| `ROLLBACK` | Validation or diagnosis requires returning to an earlier phase. |
| `INFO` | Important context that affects future agents. |

Log phase starts/completions, async submissions, task status changes, failures,
and rollbacks. Do not log pure reads, directory creation, or simple environment
queries unless the result affects future work.
SUBMITTED entries must record the task log file path so future agents can
inspect it (use `async_submit.sh -L` or `append_log.sh -o`).

## Global Options

`reproduction_options.md` is created once before Phase 1 and is part of the
reproduction state. Every phase must read it before making figure-related
decisions. Later agents may change it only after explicit user approval, and
must log the change with the reason. If the agent asks the user for startup
options, record the exact decision in this file; if no question is asked,
record the conservative agent default and the capability assumption behind it.

Template:

```markdown
# Reproduction Options

## Figure Reproduction
| Field | Value |
|-------|-------|
| Mode | off / generate-only / visual-validate |
| Locked | yes |
| Initialized By | agent/user |
| Initialized At | YYYY-MM-DD |
| Reason | ... |

## Decision Record
| Field | Value |
|-------|-------|
| Decision Source | user / agent-default |
| User Prompt | exact prompt or N/A |
| User Choice | off / generate-only / visual-validate / N/A |
| Agent Default | off / generate-only / visual-validate / N/A |
| Capability Assumption | current agent has / lacks reliable visual multimodal capability |
| Decision Time | YYYY-MM-DD HH:MM TZ |
| Change Policy | explicit user approval required |

## Capability Requirements
| Phase | Requires Visual Multimodal Capability | Reason |
|-------|---------------------------------------|--------|
| 1 Reader | yes/no | Figure image and panel understanding |
| 5 Run | no | Plotting code execution can be non-visual |
| 6 Validate | yes/no | Visual figure comparison |

## PDF Markdown Extraction
| Field | Value |
|-------|-------|
| Required | yes |
| Output Directory | 01_plan/paper_markdown/ |
| Tool | available PDF-to-Markdown parser |
```

Figure mode rules:

- Startup decisions are state, not chat context. Record user choices or
  agent-default choices in `Decision Record` before Phase 1 extraction begins.
- `visual-validate` is the default only when the initializing agent/model has
  reliable visual multimodal capability. Phase 1 and Phase 6 must then be run
  by visual multimodal agents; otherwise stop and report the capability block.
- `off` is the default when the initializing agent/model lacks visual
  multimodal capability. Do not infer figure patterns from images and do not
  perform figure-level validation.
- `generate-only` is a user-approved non-visual fallback for running available
  plotting code and saving figures. It is not evidence of visual figure
  reproduction unless later upgraded by a visual multimodal agent with user
  approval.

## Helper Scripts

Resolve scripts from this skill's `scripts/` directory.

```bash
async_submit.sh p4_data_fetch_batch1 "nextflow run data.nf -resume" . -l p4_data_fetch_batch1.log -L execution_log.md
# The -L flag auto-appends a SUBMITTED entry with the log file path.
# Use plain append_log.sh for entries not tied to async tasks:
append_log.sh "Phase 3 - COMPLETED: provision ready" . -p 3 -s COMPLETED
check_status.sh p4_data_fetch_batch1 . status
check_status.sh ignored . list
check_status.sh p4_data_fetch_batch1 . log
paperutils get 10.1234/example --json
paperutils explain PRJEB12345 --json
```

Async task names should use `{phase}_{action}_{instance}`, for example
`p4_data_fetch_batch1` or `p5_run_retry_001`.

## Rules

- Write reproduction state only inside `repro-data/`, except for user-approved
  external data/scratch paths.
- All phase artifacts, intermediate files, and logs must be stored inside that
  phase's own output directory (e.g., logs for Phase 3 go under
  `03_provision/`, never at the workspace root). Only `execution_log.md`,
  `reproduction_options.md`, `.task_status/`, and the final
  `README.md`/`run.sh`/`.gitignore` live at the `repro-data/` root.
- Commit meaningful state changes inside `repro-data/`; never commit files
  outside that Git repository.
- Check whether phase outputs already exist before writing them.
- In Phases 2-5, run installation, downloads, container pulls/builds, Nextflow
  runs, and other long-running or unpredictable operations through
  `async_submit.sh`.
- Synchronous commands are allowed for state reads, script generation, config
  edits, and short checks.
- Phase 1 collects information from the paper and obtains lightweight cited
  resources such as supplementary files, code repositories, protocol pages, and
  metadata pages. Do not install environments or download analysis-scale data.
- Phase 1 must inspect article landing pages, supplementary-material tabs, and
  versioned repository records; do not infer that supplements are absent from
  PDF text alone. Follow `references/01_reader.md` for the required resource
  completeness check.
- Phase 1 may resolve paper-provided DOI/accession identifiers through external
  metadata APIs, but must record those results separately from paper claims in
  `01_plan/plan.md`; do not estimate, search broadly, or decide data strategy.
- Use `nextflow ... -resume` for Phase 3-5 Nextflow orchestration runs.
- Scripts and code must never use hardcoded or absolute paths/parameters.
  All paths, thresholds, and configurable values must be derived from plan.md,
  data manifests, environment variables, or relative paths within the workspace.
  The goal is that another person can clone the repo and reproduce without
  editing any script.
- Before deciding a long task has failed or succeeded, check its task status,
  process state, and logs.

## Rollback

When validation or execution shows an earlier phase is wrong:

1. Identify the earliest faulty phase.
2. Log `Phase N - ROLLBACK: returning to Phase M because...`.
3. Log `Phase M - START: retry after rollback`.
4. Fix the phase output and rerun affected later phases.
