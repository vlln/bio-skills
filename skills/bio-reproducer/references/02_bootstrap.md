# Phase 2: Bootstrap

## Goal
确保运行环境就绪：Java 11+, Nextflow, 容器运行时。

## Input
`01_plan/plan.md` - "System Requirements" 和 "Environment Requirements"

## Workflow

先完成所有非破坏性检查并记录结果。需要安装、升级、下载大文件、
更改系统配置或使用大量资源时，先汇总计划并取得用户同意；耗时操作
通过 `async_submit.sh` 执行。

1. **Check Java** - 检查是否已安装且版本 ≥11
   - 若缺失或版本不足：询问用户是否安装

2. **Check Nextflow** - 检查是否已安装
   - 若缺失：询问用户是否安装

3. **Check Container Runtime** - 按优先级检查可用性：
   - 论文指定 > Singularity/Apptainer > Docker > Conda
   - 若都不可用：询问用户安装偏好

4. **Check Resources** - 磁盘(包括各个分区)/内存/CPU/GPU(如果需要)
   - 对比 plan.md 要求，不足时警告用户

5. **Test** - 验证安装：
   - `nextflow run hello`
   - 容器测试运行

## Output

- `02_bootstrap/bootstrap.md` - 环境状态报告
- `02_bootstrap/nextflow.base.config` - 可选基础运行配置
  - 只有后续 Nextflow 阶段需要固定 executor、容器 runtime、profile 或资源默认值时才生成
  - 基础配置应该避免过度约束, 而且应该对关键选项询问用户
  - 阶段交接以 `bootstrap.md` 为准, 不以 config 为准

## Key Principles

- **先检查，后询问** - 不假设环境状态, 绝对禁止不经同意的安装
- **尊重用户选择** - 安装方式询问用户
- **记录实际状态** - 系统已有 vs 本次安装
- **交接靠报告** - 后续 agent 应读取 `bootstrap.md`, 不从 config 推断环境状态
