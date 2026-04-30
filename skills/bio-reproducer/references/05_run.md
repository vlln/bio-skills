# Phase 5: Run

## Goal
使用 Nextflow 作为编排层运行分析 pipeline。Nextflow 负责输入/输出、
容器、资源、resume、日志和并行调度; 具体分析逻辑应由论文指定的
脚本、工具、notebook、命令或已有 workflow 承担。

## Input
- `01_plan/plan.md` - Steps and parameters
- `02_bootstrap/bootstrap.md` - 系统环境参考
- `03_provision/provision.md` - Available containers
- `04_data/data_manifest.md` - Data locations

## Workflow
1. 从 `plan.md` 提取步骤、参数和预期输出。
2. 从 `provision.md` 选择已验证的工具/容器; 不猜测未部署环境。
3. 从 `data_manifest.md` 读取实际数据路径; 不使用未记录数据。
4. 编写 `main.nf` 和必要的阶段配置, 将论文指定的实际执行单元封装为 process。
5. 通过 `async_submit.sh` 运行 `nextflow run main.nf -resume`。
6. 监控 `.task_status/`, Nextflow run ID, workdir 和日志; 不凭耗时长短猜测状态。
7. 写入 `run_results.md`。

## Output Files

| File | Purpose |
|------|---------|
| `main.nf` | Orchestration workflow for paper-specified execution units |
| `nextflow.config` | 可选, 仅在需要 Phase 5 覆盖配置时创建; 可 include `../02_bootstrap/nextflow.base.config` |
| `run_results.md` | 结果摘要 |
| `results/` | 输出文件 |
| `work/` | Nextflow work directory |
| `reports/` | Nextflow reports, timeline, trace, and logs |

## run_results.md Key Sections

```markdown
# Run Results

## Execution Summary
| Item | Value |
|------|-------|
| Status | SUCCESS/FAILED |
| Duration | X hours |

## Pipeline Metrics
| Step | Samples | Avg Time | Status |

## Quality Metrics
| Metric | Value | Expected | Match |

## Issues Encountered
[None / List]

## Nextflow Resume Info
Run ID: xxx
Work directory: work/
Command: nextflow run main.nf -resume ...
Trace/report files: reports/...
```

## Rules

- Phase 5 输出只能依赖 `plan.md`, `provision.md`, `data_manifest.md` 和用户批准的修正。
- 不要把论文分析逻辑无根据地重写为 Nextflow DSL; 优先调用论文指定脚本、命令、notebook 或已有 workflow。
- 如果论文已有 Nextflow pipeline, 优先复用或包裹它; 如果论文使用 Snakemake/R/Python/shell, 将其作为具体执行单元编排。
- 记录每个主要 pipeline step 的输入、输出、容器/环境、状态和关键指标。
- 失败时先定位失败 process、workdir 和 `.command.log`, 再决定 retry 或 rollback。
