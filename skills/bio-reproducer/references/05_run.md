# Phase 5: Run

## Goal
使用 Nextflow 作为编排层运行分析 pipeline。Nextflow 负责输入/输出、
容器、资源、resume、日志和并行调度; 具体分析逻辑应由论文指定的
脚本、工具、notebook、命令或已有 workflow 承担。

## Input
- `reproduction_options.md` - Global figure reproduction mode
- `01_plan/plan.md` - Steps and parameters
- `02_bootstrap/bootstrap.md` - 系统环境参考
- `03_provision/provision.md` - Available containers
- `04_data/data_manifest.md` - Data locations

## Figure Generation Under Global Mode

Figure generation is controlled by `reproduction_options.md`, not by Phase 5.
Phase 5 reads the locked global mode and reports what it did. It must not
enable, disable, or upgrade figure reproduction on its own.

Global modes:

| Mode | Meaning |
|------|---------|
| `off` | Do not generate reproduction figures. |
| `generate-only` | Run author plotting code or write data-backed plotting code and save figures, but do not make visual similarity claims. |
| `visual-validate` | Generate figures for later multimodal visual validation in Phase 6; use only when a visual multimodal validator is available. |

If the global mode is `generate-only` or `visual-validate`, generate figures
only when `01_plan/plan.md` contains enough information in
`Figure Reproduction Inventory` to create data-backed figures from recorded
inputs or run outputs. If required data, code, environment, or permissions are
missing, record figure generation status as `blocked` in `run_results.md`.

Priority for plotting implementation:

1. Run author-provided plotting scripts or notebooks.
2. Wrap author analysis code that emits figure-ready files.
3. Write minimal R/Python plotting code from documented outputs, parameters,
   and source data.
4. If none is possible under an enabled global mode, record generation status
   as `blocked`; do not fabricate figure data.

## Workflow
1. 读取 `reproduction_options.md`，确定全局 figure mode。
2. 从 `plan.md` 提取步骤、参数和预期输出。
3. 从 `provision.md` 选择已验证的工具/容器; 不猜测未部署环境。
4. 从 `data_manifest.md` 读取实际数据路径; 不使用未记录数据。
5. 编写 `main.nf` 和必要的阶段配置, 将论文指定的实际执行单元封装为 process。
6. 容器网络检查 — 启动测试容器验证 DNS 和外网连通性，对比 Phase 2 记录的
   宿主机网络检测子网冲突；若不通或冲突则在 `run_results.md` 记录并警告用户。
7. 通过 `async_submit.sh` 运行 `nextflow run main.nf -resume`。
8. 监控 `.task_status/`, Nextflow run ID, workdir 和日志; 不凭耗时长短猜测状态。
9. 若全局 mode 为 `generate-only` 或 `visual-validate`, 运行或编写绘图执行单元并保存脚本、输入表和图像。
10. 写入 `run_results.md`。

## Output Files

| File | Purpose |
|------|---------|
| `main.nf` | Orchestration workflow for paper-specified execution units |
| `nextflow.config` | 可选, 仅在需要 Phase 5 覆盖配置时创建; 可 include `../02_bootstrap/nextflow.base.config` |
| `run_results.md` | 结果摘要 |
| `results/` | 输出文件 |
| `figures/` | Optional generated figure files, plotting scripts, and figure input tables |
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

## Figure Generation
| Field | Value |
|-------|-------|
| Global Mode | off/generate-only/visual-validate |
| Generation Status | not enabled/generated/partial/blocked |
| Figures Directory | figures/ or N/A |
| Plotting Source | author code / author notebook / handwritten / N/A |

| Figure/Panel | Script/Notebook | Input Data | Output Figure | Status | Notes |
|--------------|-----------------|------------|---------------|--------|-------|

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
- Figure generation 由全局配置控制；未启用时不影响 Phase 5 完成，但必须在
  `run_results.md` 写明 `Global Mode: off` 和原因。
- Phase 5 不需要视觉多模态能力；它可以执行绘图代码，但不能判断图像内容。
- 手写绘图代码必须只使用 `plan.md`、`data_manifest.md`、Phase 5 输出、
  作者 source data 或用户批准的修正；不得从原文图片描点或手工填造数据。
- 无视觉多模态能力的 agent 可以生成图像文件，但不得声称图像与原文视觉相似。
- 失败时先定位失败 process、workdir 和 `.command.log`, 再决定 retry 或 rollback。
