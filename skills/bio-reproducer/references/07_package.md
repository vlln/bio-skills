# Phase 7: Package

## Goal
将通过验证的复现产出打包为可交付状态：写 README 和顶层入口脚本，
使他人 clone 后可以理解复现内容并一键运行。

## Prerequisites
- `06_validate/report.md` 存在且 Verdict 为 REPRODUCED 或 PARTIAL
- FAILED 或 BLOCKED 状态不执行本阶段

## Input
- `01_plan/plan.md` — 论文信息和复现目标
- `06_validate/report.md` — 验证结论和评分
- 所有 phase 的输出目录和文件

## Output

| File | Purpose |
|------|---------|
| `README.md` | 项目总览、快速开始、目录结构 |
| `run.sh` | 顶层入口脚本，检查环境并引导执行 |

### README.md 必须包含

```markdown
# [Paper Title]

**DOI**: [doi]
**Reproduction Status**: REPRODUCED / PARTIAL (Score: XX/100)
**Date**: YYYY-MM-DD

## Paper Summary

[2-3 sentences from plan.md Paper Understanding]

## Reproduction Verdict

[Validation summary from report.md, including key scores and notable deviations]

## System Requirements

- OS: [from bootstrap.md]
- Container runtime: [Docker / Singularity / Apptainer]
- Nextflow: [version]
- Other: [disk space, memory, network]

## Quick Start

```bash
# 1. Clone and enter
git clone <repo> && cd repro-data

# 2. Check prerequisites
bash run.sh check

# 3. Run reproduction (all phases)
bash run.sh all

# Or step by step:
bash run.sh bootstrap   # Phase 2: install system dependencies
bash run.sh provision   # Phase 3: pull/build containers
bash run.sh data        # Phase 4: download data
bash run.sh run         # Phase 5: execute analysis
bash run.sh validate    # Phase 6: validate results
```

## Directory Structure

```
repro-data/
├── README.md
├── run.sh
├── 01_plan/plan.md
├── 02_bootstrap/bootstrap.md
├── 03_provision/provision.md
├── 04_data/data_manifest.md
├── 05_run/main.nf
├── 05_run/run_results.md
├── 05_run/results/
├── 06_validate/report.md
└── execution_log.md
```

## Notes

[Known issues, data access requirements, expected runtime, anything a
new user needs to know before starting.]
```

### run.sh 要求

- 纯 bash，不依赖 Python 或其他解释器
- 所有路径相对于 `repro-data/` 根目录
- 不接受硬编码路径；通过脚本所在目录推断 `repro-data/` 根
- 提供以下子命令：
  - `check` — 检查系统前提条件（nextflow、docker/singularity、磁盘空间等）
  - `all` — 串行运行所有可执行 phase（提示用户确认）
  - `bootstrap`, `provision`, `data`, `run`, `validate` — 分别运行各 phase
- 每个 phase 子命令应打印说明（该 phase 做什么、预计耗时）再执行
- Phase 1 不在 run.sh 中重跑；README 指向已有的 plan.md
- Phase 2-6 内部逻辑从各 phase 的产出中读取（如 main.nf、data_manifest.md），
  不做重复实现；run.sh 的角色是入口和引导，不是替代已有产出

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

check() {
    echo "=== Checking prerequisites ==="
    command -v nextflow >/dev/null 2>&1 || { echo "ERROR: nextflow not found"; exit 1; }
    command -v docker >/dev/null 2>&1 || command -v singularity >/dev/null 2>&1 || \
        { echo "ERROR: docker or singularity required"; exit 1; }
    echo "OK: prerequisites satisfied"
}

all() {
    echo "This will run all reproduction phases."
    echo "Expected time: [fill from bootstrap or experience]"
    read -p "Continue? [y/N] " yn
    case "$yn" in [Yy]*) ;; *) exit 0;; esac
    bootstrap
    provision
    data
    run
    validate
}

bootstrap() {
    echo "=== Phase 2: Bootstrap ==="
    echo "Installing system dependencies..."
    # Read and execute from 02_bootstrap/bootstrap.md
}

# ... provision, data, run, validate stubs ...

"${@:-check}"
```

## Workflow

1. 读取 `01_plan/plan.md` 的标题、DOI、Paper Understanding
2. 读取 `06_validate/report.md` 的 Verdict、Score、Deviations
3. 读取 `02_bootstrap/bootstrap.md` 提取系统要求
4. 从各 phase 产出推断目录结构
5. 编写 `README.md` 和 `run.sh`
6. Git commit

## Rules

- `run.sh` 中的路径全部为相对路径或从 `$ROOT` 推导，禁止硬编码绝对路径
- README 必须包含足够信息让未读论文的人也能理解复现了什么
- README 必须如实反映 Verdict；PARTIAL 时必须在 Verdict 和 Notes 中说明偏差
- 如 Phase 2-5 使用了 `async_submit.sh`，run.sh 应复用同样的 `nextflow -resume` 命令
- Phase 7 不重跑任何分析，只做打包和文档

## Completion
- 输出 `README.md` 和 `run.sh` 在 `repro-data/` 根目录
- 记录 `Phase 7 - COMPLETED: reproduction packaged`
- Git commit