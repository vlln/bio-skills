# Phase 6: Validate

## Goal
结构化、量化地对比复现结果与论文声称，生成可追溯的验证报告和综合评分。

## Input
- `reproduction_options.md` — locked global figure reproduction mode
- `01_plan/plan.md` — 论文声称的 Expected Results
- `05_run/run_results.md` — 实际运行结果和指标
- `05_run/results/` — 输出文件
- `05_run/figures/` — optional generated figures and plotting inputs
- `05_run/reports/` — Nextflow 执行报告

## Optional Figure Validation Gate

Figure-level validation is controlled by `reproduction_options.md`. Phase 6
must read the locked global mode before defining checks. It must not enable,
disable, or upgrade figure reproduction on its own.

Modes:

| Mode | Meaning | Allowed Claims |
|------|---------|----------------|
| `off` | Figure validation not requested or not useful for this reproduction. | Metrics and non-visual scientific checks only. |
| `generate-only` | Figure files were generated in Phase 5, but no visual comparison is performed. | File existence, plotting provenance, and underlying data checks only. |
| `visual-validate` | A visual multimodal model compares reproduced figures with paper figures. | Panel-level visual pattern and qualitative similarity claims with evidence. |

Hard rule: agents without visual multimodal capability must not claim visual
similarity, panel-level agreement, layout agreement, or visual pattern
agreement from images. They may report generated figure files and validate the
underlying numerical/source data. If a pattern agreement claim is derived from
computed data rather than image inspection, state the computation used.

If the global mode is `visual-validate` but the current Phase 6 agent/model
lacks visual multimodal capability, stop figure validation and record figure
validation status as `blocked`. Continue non-visual metric validation only if
the user allows a partial validation pass or the task instruction already
permits it.

Do not use the original paper image as a data source for tracing, digitizing, or
manual recreation unless the report labels it as a visual reference only and
excludes it from computational reproduction evidence.

## Validation Methodology

验证分三层，外加一个可选图级增强层：

1. **定义检查项** — 从 plan.md 的 Expected Results 和 Paper Claims 推导该论文的验证检查项，归入四个通用维度
2. **执行对比** — 尽可能自动化提取实际值并与期望值对比；无法自动化的由 agent 审查
3. **综合评分** — 加权汇总各检查项得分，输出 Reproducibility Score 和 Verdict
4. **可选 Figure-level validation** — 仅在全局 `visual-validate` 模式下由具备视觉多模态能力的 agent 对关键 figure/panel 做图级比较

## Defining Validation Checks

检查项必须从论文自身声称中推导，禁止使用预设指标。推导规则：

1. 阅读 plan.md 的 **Expected Results** 表，每一项期望值至少对应一个检查
2. 阅读 plan.md 的 **Paper Understanding → Key Findings**，每个关键发现至少对应一个检查
3. 阅读 plan.md 的 **Paper Understanding → Reproduction Target**，每个复现目标至少对应一个检查
4. 检查项归入四个维度之一（见下），每个维度至少 2 个检查
5. 标记每个检查为 Auto（可脚本提取对比）、Manual（需人工审查）或 Visual（需视觉多模态审查）

维度权重为默认值，当论文的复现重点明显偏向某维度时可调整（调整需在 report.md 中记录理由）。

## Four Validation Dimensions

### Dimension 1: Data Integrity（默认权重 25%）

验证输入数据和输出文件的完整性。

适用场景：所有论文。

常见检查类型（从 plan.md 推导，非穷举）：
- 样本/文件/记录数量是否与论文一致
- 预期输出文件是否全部生成且非空
- 关键中间文件的数量/大小是否合理
- 数据格式/结构是否符合论文描述

评分：每个检查 1.0（通过）/ 0.5（部分）/ 0.0（失败）。
维度得分 = mean(检查得分) × 权重。

### Dimension 2: Process Quality（默认权重 25%）

验证计算流程的运行质量和过程指标。

适用场景：论文对分析流程有过程性指标声称（如比对率、覆盖深度、QC 指标、收敛诊断、交叉验证结果等）。如论文无此类声称，该维度检查仍可包含任务成功率、资源使用合理性等通用过程指标，或降低权重。

常见检查类型（从 plan.md 推导，非穷举）：
- 论文明确报告的过程性指标（比对率、覆盖度、重复率等）
- Pipeline 任务成功率（多少 process 成功完成）
- 资源使用是否在合理范围（内存/CPU 未超限）
- 软件版本与论文指定版本是否一致

评分：
- 数值型：偏差在论文方法学合理范围内 → 1.0；轻度超出 → 0.7；显著超出 → 0.3；量级错误 → 0.0
- 布尔型（成功/失败）：通过 → 1.0；失败 → 0.0
维度得分 = mean(检查得分) × 权重。

### Dimension 3: Quantitative Concordance（默认权重 30%）

验证论文报告的核心数值结果是否被复现。

适用场景：所有论文。这是权重最高的维度，反映复现的核心目标。

常见检查类型（从 plan.md 推导，非穷举）：
- 论文报告的具体数值（表格数据、统计量、效应大小等）
- 计数型结果（差异基因数、peak 数、OTU 数等）
- 集合重叠（Top-N 基因/区域/物种与论文报告列表的 Jaccard 或 overlap ratio）
- 统计推断方向（上调/下调、富集/耗尽、正相关/负相关的一致性）
- 排序一致性（Spearman/Kendall 相关系数）

评分：
- 数值/计数：在论文合理容差内 → 1.0；轻度偏离 → 0.7；显著偏离 → 0.3；方向相反 → 0.0
- 集合重叠：由 agent 根据领域惯例设定阈值（如 Jaccard ≥0.8 → 1.0）
- 方向/排序：方向一致 → 1.0；部分一致 → 0.5；方向相反 → 0.0
维度得分 = mean(检查得分) × 权重。

### Dimension 4: Figure and Finding Reproduction（默认权重 20%）

验证论文的关键图表承载的科学模式和核心生物学/科学结论是否被复现结果支持。

适用场景：所有论文。

常见检查类型（从 plan.md 推导，非穷举）：
- 关键图表是否能用复现数据重新生成
- 在 `visual-validate` 模式下，复现图与原文关键 panel 的模式、分组、
  排序、趋势或空间结构是否一致
- 论文的核心生物学论断是否被复现结果支持
- 已知阳性/阴性对照是否表现符合预期
- 复现结果能否独立得出与论文一致的定性结论

评分：confirmed → 1.0；partially consistent → 0.5；inconsistent → 0.0。
维度得分 = mean(检查得分) × 权重。

视觉相似度只评价科学信息承载层：趋势、分组、排序、富集/耗尽模式、
空间分布、聚类结构、显著性标记和 panel 结论。字体、边距、配色、图例位置、
Illustrator/PowerPoint 后处理和排版差异不得作为核心失败原因，除非它们改变
科学解读。

## Reproducibility Score

```
Total Score = sum(各维度得分)  (范围: 0–100)

Verdict 映射:
  ≥ 85  → REPRODUCED
  60–84 → PARTIAL
  40–59 → PARTIAL (substantial deviations)
  < 40  → FAILED
```

BLOCKED 在评分前判定：当数据受限、代码缺失、权限不足或外部服务不可用导致验证完全无法执行时，不计算分数，直接标记 BLOCKED。

当部分检查因论文未提供期望值而无法评分的，标记 N/A 并排除出该维度的 mean 计算。N/A 超过该维度检查项一半时，该维度标注覆盖率不足并在报告中讨论影响。

允许按论文复现重点调整维度权重，调整后总分仍为 100。调整理由必须写入 report.md 的 Score Breakdown 节。

## Automation

优先为标记 Auto 的检查编写提取/对比脚本。脚本可以是独立的 Python/R/shell 片段，从 `05_run/results/` 提取数值、计数、文件列表等。

自动化结果写入 `06_validate/metrics.json`：

```json
{
  "checks": [
    {
      "id": "D1",
      "dimension": "Data Integrity",
      "metric": "样本数",
      "expected": 12,
      "actual": 12,
      "score": 1.0,
      "auto": true,
      "notes": ""
    }
  ],
  "dimension_scores": {
    "Data Integrity": 25.0,
    "Process Quality": 22.5,
    "Quantitative Concordance": 24.0,
    "Figure and Finding Reproduction": 16.0
  },
  "total_score": 87.5,
  "verdict": "REPRODUCED",
  "checks_total": 12,
  "checks_scored": 11,
  "checks_na": 1,
  "figure_reproduction_mode": "generate-only",
  "figure_validation_status": "not enabled/generated/partial/blocked/validated",
  "weight_adjustments": {}
}
```

Manual 检查由 agent 审查后填入同一结构。

## Figure Comparison Output

If figure generation or validation is enabled, write
`06_validate/figure_comparison.md`.

```markdown
# Figure Comparison

## Mode
| Field | Value |
|-------|-------|
| Figure Reproduction Mode | off / generate-only / visual-validate |
| Figure Validation Status | not enabled / generated / partial / blocked / validated |
| Visual Multimodal Capability | yes / no |
| Paper Figure Source | PDF / HTML / supplement / source-data-only / N/A |
| Generated Figures Directory | ../05_run/figures or N/A |

## Figure Evidence
| Figure/Panel | Paper Claim | Generated Figure | Source Data | Comparison Type | Result | Notes |
|--------------|-------------|------------------|-------------|-----------------|--------|-------|

## Visual Assessment
[Only present in visual-validate mode. Describe panel-level pattern agreement,
major deviations, and what scientific conclusion is or is not supported.]

## Non-Visual Figure Checks
[Use this section in generate-only mode for plotting provenance, input data,
computed trend/rank/overlap checks, and file existence.]
```

## Output: 06_validate/report.md

```markdown
# Validation Report

## Verdict

| Field | Value |
|-------|-------|
| Status | REPRODUCED / PARTIAL / BLOCKED / FAILED |
| Reproducibility Score | XX / 100 |
| Checks Scored | X / Y（Z N/A） |
| Figure Reproduction Mode | off / generate-only / visual-validate |
| Figure Validation Status | not enabled / generated / partial / blocked / validated |
| Date | YYYY-MM-DD |

## Score Breakdown

| Dimension | Score | Max | Checks | Notes |
|-----------|-------|-----|--------|-------|
| Data Integrity | XX | XX | D1–Dn | 如调整权重，注明理由 |
| Process Quality | XX | XX | Q1–Qn | |
| Quantitative Concordance | XX | XX | R1–Rn | |
| Figure and Finding Reproduction | XX | XX | K1–Kn | |
| **Total** | **XX** | **100** | | |

## Evidence Compared

| Check ID | Metric | Expected | Actual | Score | Type | Notes |
|----------|--------|----------|--------|-------|------|-------|
| D1 | ... | ... | ... | X.X | Auto | |
| Q1 | ... | ... | ... | X.X | Auto | |
| R1 | ... | ... | ... | X.X | Manual | See analysis below |
| K1 | ... | ... | ... | X.X | Visual | See figure_comparison.md |

（每个检查一行，按维度分组。Manual/Visual 检查需在 Notes 列指明详细分析位置。）

## Figure Reproduction

| Field | Value |
|-------|-------|
| Global Mode | off / generate-only / visual-validate |
| Validation Status | not enabled / generated / partial / blocked / validated |
| Generated Figures | path or N/A |
| Figure Comparison Report | 06_validate/figure_comparison.md or N/A |
| Limitation | none / no visual multimodal capability / missing source data / missing original figure / other |

## Deviations

| Check ID | Deviation | Magnitude | Likely Cause | Fault Phase |
|----------|-----------|-----------|-------------|-------------|

## Reproduction Limits

| Limit | Affected Checks | Impact |
|-------|-----------------|--------|

## Interpretation Guide

- **Score ≥ 85 (REPRODUCED)**: 关键数据、流程和主要结果与论文一致，偏差在可接受范围内或有合理解释。
- **Score 60–84 (PARTIAL)**: 技术流程可运行，但数据规模、部分指标或次要发现与论文存在差异。
- **Score 40–59 (PARTIAL, substantial deviations)**: 流程可运行，但多项核心指标与论文显著偏离，复现仅部分成立。
- **Score < 40 (FAILED)**: 使用记录的数据和环境运行后，结果与论文核心结论不一致。
- **BLOCKED**: 受限数据、缺失代码、权限、资源或外部服务阻止验证执行，不适用评分。

## Next Action

- **REPRODUCED**: 归档报告，复现完成。
- **PARTIAL**: 记录偏差原因；如偏差可修正，考虑 rollback 到对应 phase。
- **BLOCKED**: 记录阻塞项；等待条件满足或标记为不可复现。
- **FAILED**: 记录失败分析；如根因明确且可修正，rollback 到最早出错 phase；否则标记为不可复现。
```

## Notes

- 检查项定义是 Phase 6 的第一步，必须在执行对比前完成。检查项列表写入 `06_validate/checks_plan.md` 或直接写入 report.md 的 Evidence Compared 表。
- Figure validation 是可选增强层，不是 Phase 6 完成的必要条件。
- Figure validation mode 必须来自 `reproduction_options.md`；Phase 6 不得自行开启、关闭或升级。
- 当全局模式为 `off` 或 `generate-only` 时，即使存在图片也不得执行视觉比较。
- 当全局模式为 `visual-validate` 且当前 agent/model 不具备视觉多模态能力时，
  将 figure validation status 记为 `blocked`，并报告能力不匹配；不得临时降级或编造视觉相似性结论。
- `visual-validate` 模式在具备视觉能力且原图/复现图可用时必须产生
  `06_validate/figure_comparison.md`；否则记录 blocked 或 partial。
- 维度权重为默认值；如有调整，在 Score Breakdown 的 Notes 列记录理由。
- 验证失败时在 report.md 记录问题分析，然后遵循 SKILL.md 的 Rollback Protocol。
- Rollback 时指出最早可能出错的 phase 和对应 check ID。
- Interpretation Guide 必须包含在 report.md 中，使读者无需参考本文件即可理解判定。
- `metrics.json` 保留原始评分数据，供后续 audit 或 re-scoring。
