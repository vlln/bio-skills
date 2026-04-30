# Phase 6: Validate

## Goal
对比复现结果与论文，判定成功与否。

## Input
- `01_plan/plan.md` - Expected results
- `05_run/run_results.md` - Actual results

## Workflow
1. 提取 plan.md 中的 Expected Results
2. 提取 run_results.md 中的实际结果
3. 按维度对比，记录偏差
4. 根据 Decision Matrix 判定状态

## Output: report.md

关键对比维度：

| Dimension | What to Compare |
|-----------|-----------------|
| Data | Sample count, read count |
| Quality | Alignment rate, duplication |
| Quantities | DEG count, peak count |
| Key findings | Specific genes/regions |

## Decision Matrix

| Status | Meaning |
|--------|---------|
| `REPRODUCED` | 关键数据、流程和主要结果与论文一致或偏差可解释。 |
| `PARTIAL` | 技术流程可运行, 但数据、规模或部分指标与论文不同。 |
| `BLOCKED` | 受限数据、缺失代码、权限、资源或外部服务阻止验证。 |
| `FAILED` | 使用记录的数据和环境运行后, 结果与论文核心结论不一致。 |

## report.md Required Sections

```markdown
# Validation Report

## Verdict
Status: REPRODUCED/PARTIAL/BLOCKED/FAILED

## Evidence Compared
| Item | Expected | Actual | Match | Notes |

## Deviations
| Deviation | Likely Cause | Fault Phase |

## Reproduction Limits
| Limit | Impact |

## Next Action
Rollback / Retry / Stop / Report final result
```

## Notes
- 验证失败时：在 report.md 中记录问题分析，然后遵循 SKILL.md 的 Rollback Protocol
- 如果需要 rollback, 指出最早可能出错的 phase, 不只描述表面现象。
