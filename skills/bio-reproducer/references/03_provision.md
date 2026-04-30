# Phase 3: Provision

## Goal
用 Nextflow 并行部署所有工具环境。

## Input
- `01_plan/plan.md` - Environment Requirements
- `02_bootstrap/bootstrap.md` - 系统环境参考 
- `02_bootstrap/nextflow.base.config` - 可选, 仅作为 Nextflow 运行配置

## Workflow

**IMPORTANT**:
- 禁止随意猜测镜像/环境版本, 必须确认目标环境存在或可构建。
- 开始拉取/构建/安装前必须经过用户同意; 耗时操作通过 `async_submit.sh` 执行。

1. 根据 Environment Requirements 检查
  - 如果不存在, 则考虑下载: 优先使用单体工具, 而非工具集中的工具(除非论文指定了使用某工具集)
  - 如果缺失工具, 则考虑优先使用论文提供的环境(镜像), 如果没有则搜索镜像. 如果没有镜像则搜索bioconda, 如果也没有则考虑源码安装/编译. 
  - 注意! 安装工具前应该尝试检查是否冲突. 如果安装遇到冲突问题则应该修复后继续尝试
2. 编写 `provision.nf` 和必要的阶段配置
3. 询问用户
4. 拉取/构建容器
5. 验证每个工具可用

## Output Files

| File | Purpose |
|------|---------|
| `provision.nf` | 拉取/构建环境的 workflow |
| `nextflow.config` | 可选, 仅在需要 Phase 3 覆盖配置时创建; 可 include `../02_bootstrap/nextflow.base.config` |
| `provision.md` | 部署报告 |

## provision.md Template

```markdown
# Provision Report

## Environment
| Property | Value |
|----------|-------|
| Container Engine | Docker/Singularity |

## Tools Provisioned
| Tool | Version | Image | Status |

## Verification
- [x] All containers pulled
- [x] Test execution passed
```

## Notes
- 失败时检查：容器仓库访问、磁盘空间、网络代理
- `provision.md` 是后续阶段判断可用工具/镜像的依据; 不从 `nextflow.config` 推断部署结果。
