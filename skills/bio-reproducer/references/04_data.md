# Phase 4: Data

## Goal
获取分析所需数据。

## Input
- `01_plan/plan.md` - Data Requirements and External Identifier Records
- `02_bootstrap/bootstrap.md` - 系统环境参考
- `03_provision/provision.md` - 已部署工具和容器

## Workflow

1. **Analyze Data Sources**
   - 识别 plan.md 中的数据来源和已解析外部标识符记录
   - 评估可获取性（公开/需申请/受限）

2. **Attempt Acquisition**
   - 尝试下载公开数据; 大文件下载必须通过 `async_submit.sh`
   - 尝试获取示例数据
   - 检查是否有预下载的数据

3. **Handle Access Barriers**
   - 若原始数据受限、缺失、需申请、需登录或成本较高, 暂停并询问用户决策
   - 不擅自替换数据; 如用户批准替代/示例/技术验证数据, 在 manifest 中记录

4. **Document in data_manifest.md**
   - 实际获取的数据
   - 无法获取的数据及原因
   - 用户决策

## Output Files

| File | Purpose |
|------|---------|
| `data.nf` | 数据获取 workflow |
| `nextflow.config` | 可选, 仅在需要 Phase 4 覆盖配置时创建; 可 include `../02_bootstrap/nextflow.base.config` |
| `data_manifest.md` | 数据清单 |
| `raw_data/` | 样本文件 |
| `reference/` | 参考文件 |

## data_manifest.md Template

```markdown
# Data Manifest

## Acquisition Summary
| Property | Value |
|----------|-------|
| Status | COMPLETED/PARTIAL/BLOCKED |
| Strategy | Original/Supplementary/Technical-Only |

## Data Sources
| Source | Required | Obtained | Location | Notes |

## Samples
| Sample ID | Source | Files | Size | Status |

## Reference Data
| File | Source | Size | Status |

## Blocked Data
| Source | Reason | User Decision |

## Verification
- [ ] All files present
- [ ] Checksums verified
```

## Data Source Types

| Type | Approach |
|------|----------|
| Public (SRA/ENA/GEO) | 直接下载 |
| Restricted (dbGaP/UKB) | 询问用户：申请/替代/跳过 |
| Author-provided | 检查 Zenodo/Supplementary |
| Pre-downloaded | 检查本地路径 |

## Rules

- `data_manifest.md` 是 Phase 5 的数据来源依据, 必须记录路径、来源、状态和校验信息。
- Phase 4 可以使用 Phase 1 已记录的 External Identifier Records, 但必须重新记录实际获取结果。
- 下载到 `04_data/raw_data/`, `04_data/reference/`, 或用户批准的外部数据目录。
- 如果使用外部目录, 在 `data_manifest.md` 中记录绝对路径和用户批准原因。
