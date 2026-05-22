# Phase 6: Validate

## Goal
结构化、量化地对比复现结果与论文声称，生成可追溯的验证报告和综合评分。

## Input
- `01_plan/plan.md` — 论文声称的 Expected Results
- `05_run/run_results.md` — 实际运行结果和指标
- `05_run/results/` — 输出文件
- `05_run/reports/` — Nextflow 执行报告

## Validation Methodology

验证分三层：

1. **定义检查项** — 从 plan.md 的 Expected Results 和 Paper Claims 推导该论文的验证检查项，归入四个通用维度
2. **执行对比** — 尽可能自动化提取实际值并与期望值对比；无法自动化的由 agent 审查
3. **综合评分** — 加权汇总各检查项得分，输出 Reproducibility Score 和 Verdict

## Defining Validation Checks

检查项必须从论文自身声称中推导，禁止使用预设指标。推导规则：

1. 阅读 plan.md 的 **Expected Results** 表，每一项期望值至少对应一个检查
2. 阅读 plan.md 的 **Paper Understanding → Key Findings**，每个关键发现至少对应一个检查
3. 阅读 plan.md 的 **Paper Understanding → Reproduction Target**，每个复现目标至少对应一个检查
4. 检查项归入四个维度之一（见下），每个维度至少 2 个检查
5. 标记每个检查为 Auto（可脚本提取对比）或 Manual（需人工审查）

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

### Dimension 4: Finding Reproduction（默认权重 20%）

验证论文的核心生物学/科学结论是否被复现结果支持。

适用场景：所有论文。

常见检查类型（从 plan.md 推导，非穷举）：
- 关键图表是否能用复现数据重新生成且模式一致
- 论文的核心生物学论断是否被复现结果支持
- 已知阳性/阴性对照是否表现符合预期
- 复现结果能否独立得出与论文一致的定性结论

评分：confirmed → 1.0；partially consistent → 0.5；inconsistent → 0.0。
维度得分 = mean(检查得分) × 权重。

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
    "Finding Reproduction": 16.0
  },
  "total_score": 87.5,
  "verdict": "REPRODUCED",
  "checks_total": 12,
  "checks_scored": 11,
  "checks_na": 1,
  "weight_adjustments": {}
}
```

Manual 检查由 agent 审查后填入同一结构。

## Output: 06_validate/report.md

```markdown
# Validation Report

## Verdict

| Field | Value |
|-------|-------|
| Status | REPRODUCED / PARTIAL / BLOCKED / FAILED |
| Reproducibility Score | XX / 100 |
| Checks Scored | X / Y（Z N/A） |
| Date | YYYY-MM-DD |

## Score Breakdown

| Dimension | Score | Max | Checks | Notes |
|-----------|-------|-----|--------|-------|
| Data Integrity | XX | XX | D1–Dn | 如调整权重，注明理由 |
| Process Quality | XX | XX | Q1–Qn | |
| Quantitative Concordance | XX | XX | R1–Rn | |
| Key Findings | XX | XX | K1–Kn | |
| **Total** | **XX** | **100** | | |

## Evidence Compared

| Check ID | Metric | Expected | Actual | Score | A/M | Notes |
|----------|--------|----------|--------|-------|-----|-------|
| D1 | ... | ... | ... | X.X | Auto | |
| Q1 | ... | ... | ... | X.X | Auto | |
| R1 | ... | ... | ... | X.X | Manual | See analysis below |

（每个检查一行，按维度分组。Manual 检查需在 Notes 列指明详细分析位置。）

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
- 维度权重为默认值；如有调整，在 Score Breakdown 的 Notes 列记录理由。
- 验证失败时在 report.md 记录问题分析，然后遵循 SKILL.md 的 Rollback Protocol。
- Rollback 时指出最早可能出错的 phase 和对应 check ID。
- Interpretation Guide 必须包含在 report.md 中，使读者无需参考本文件即可理解判定。
- `metrics.json` 保留原始评分数据，供后续 audit 或 re-scoring。
