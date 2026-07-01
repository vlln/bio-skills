---
name: bio-reproducer
description: 当需要在项目工作区内复现生物信息学论文时使用此 skill。通过分阶段报告、数据清单、异步长时间任务和 Nextflow 编排，引导完成可复现的论文复现。
license: MIT
metadata:
  author: vlln
  version: "0.1.0"
requires:
  bins:
    - bash
    - python3
    - paperutils
---

# Bio-Reproducer

## Pipeline

复现生物信息学论文，按 7 个阶段顺序执行。不用于快速工具查找或通用生物信息学建议。

| Stage | Output | Reference | Execution |
|-------|--------|-----------|-----------|
| 1 Reader | `01_plan/plan.md` | `references/01_reader.md` | 资源收集和提取 |
| 2 Bootstrap | `02_bootstrap/bootstrap.md` | `references/02_bootstrap.md` | 环境安装，长时间任务异步执行 |
| 3 Provision | `03_provision/provision.md` | `references/03_provision.md` | 容器/Nextflow 操作异步执行 |
| 4 Data | `04_data/data_manifest.md` | `references/04_data.md` | 下载/Nextflow 操作异步执行 |
| 5 Run | `05_run/run_results.md` | `references/05_run.md` | Nextflow 运行异步执行；可选图表生成 |
| 6 Validate | `06_validate/report.md` | `references/06_validate.md` | 结果对比；可选图表验证 |
| 7 Package | `README.md`、`run.sh`、`.gitignore` | `references/07_package.md` | 编写 README、入口脚本和 gitignore |

每个阶段开始前加载对应的参考文件。绝不跳过检查点；修复失败后再继续。

### Stage Checkpoints

- **Stage 1**: `01_plan/plan.md` 存在且通过资源完整性检查。检查论文页面、补充材料标签页和版本化仓库记录；不得仅从 PDF 推断。
- **Stage 2**: `02_bootstrap/bootstrap.md` 存在，所有异步安装任务完成。
- **Stage 3**: `03_provision/provision.md` 存在。
- **Stage 4**: `04_data/data_manifest.md` 存在，所有异步下载任务完成。
- **Stage 5**: `05_run/run_results.md` 存在，所有 Nextflow 运行完成。
- **Stage 6**: `06_validate/report.md` 存在且 verdict 确定。
- **Stage 7**: `README.md`、`run.sh` 和 `.gitignore` 存在。

## State Recovery

`repro-data/execution_log.md` 是复现状态的唯一真实来源。通过读取文件恢复状态，不依赖聊天记忆。

恢复流程：
1. 确保 `repro-data/` 存在，所有复现状态均在其中操作。
2. 仅在 `repro-data/` 内初始化 Git（当 `.git/` 不存在时）。
3. 确保 `reproduction_options.md` 在 Phase 1 之前存在。此文件锁定全局选项，后续 agent 不得擅自更改。
4. 读取 `execution_log.md`，检查 `.task_status/` 中的异步任务。
5. 加载当前阶段的参考文件。
6. 读取已完成前置阶段的输出。

## State Rules

根据 `execution_log.md` 的最后条目判断当前阶段：

- 无 `reproduction_options.md`：创建后开始 Phase 1，记录 `INFO: reproduction options initialized`。
- 无 `execution_log.md`：开始 Phase 1。
- 最后日志为 `Phase N - SUBMITTED: ...`：检查 `.task_status/` 和任务日志。
- 最后日志为 `Phase N - COMPLETED: ...` 且输出存在：开始 Phase N+1。
- 最后日志为 `Phase N - FAILED: ...`：诊断、重试或回滚。
- `06_validate/report.md` 存在且 verdict 为 REPRODUCED/PARTIAL：开始 Phase 7。
- `README.md`、`run.sh` 和 `.gitignore` 存在：复现完成。

## Handoff

阶段之间通过显式报告和清单交接。新 agent 必须读取 `execution_log.md` 和已完成前置阶段的输出。

`nextflow.config` 仅作为可选运行时配置，不作为前置阶段成果的权威来源。共享 Nextflow 设置应创建 `02_bootstrap/nextflow.base.config`，后续阶段可 include 该基础文件，但不得整体继承另一个阶段的 config。

关键状态文件：
- `reproduction_options.md`
- `execution_log.md`
- `.task_status/{task}.status`、`.pid`、`.pgid`、`.log`
- 各阶段输出文件（`01_plan/plan.md`、`02_bootstrap/bootstrap.md` 等）
- `README.md`、`run.sh`、`.gitignore`

## Logging

格式：`Phase N - STATUS: message`

| 状态 | 用途 |
|------|------|
| `START` | 有意义操作开始。 |
| `END` | 有意义操作以 `SUCCESS` 或 `FAILED` 结束。 |
| `SUBMITTED` | 异步任务已提交。必须记录任务日志路径。 |
| `COMPLETED` | 阶段已完成且其必要输出存在。 |
| `FAILED` | 阶段或任务失败。 |
| `ROLLBACK` | 验证或诊断要求返回更早阶段。 |
| `INFO` | 影响后续 agent 的重要上下文。 |

记录阶段开始/完成、异步提交、任务状态变更、失败和回滚。不记录纯读取、目录创建或简单环境查询（除非其结果影响后续工作）。

## Global Options

`reproduction_options.md` 在 Phase 1 之前创建，每个阶段必须读取。后续 agent 仅在用户明确批准后方可更改，且必须记录更改原因。

### 图表模式

- `generate`（默认）：尝试运行绘图代码并保存图表，不做视觉相似性判断。不需要视觉多模态能力。
- `visual-validate`：仅当 agent 具备可靠的视觉多模态能力且用户批准时使用。Phase 1 和 6 必须由视觉多模态 agent 执行。Phase 6 对原图与复现图做 panel 级视觉比较。
- 图表生成失败记 `blocked`，不影响其他验证。

### 产出语言

所有阶段产出的 Markdown 文件的标题、章节名、描述文字和表格内容使用配置的语言。`zh` 为中文，`en` 为英文。代码块、命令、路径、URL、状态值、模板字段名和日志条目格式不受语言限制。语言在 Phase 1 锁定，后续阶段不得更改。

### 选项模板

```markdown
# Reproduction Options

## Figure Reproduction
| Field | Value |
|-------|-------|
| Mode | generate / visual-validate |
| Locked | yes |
| Initialized By | agent/user |
| Initialized At | YYYY-MM-DD |
| Reason | ... |

## Decision Record
| Field | Value |
|-------|-------|
| Decision Source | user / agent-default |
| User Prompt | exact prompt or N/A |
| User Choice | generate / visual-validate / N/A |
| Agent Default | generate / visual-validate / N/A |
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

## Language
| Field | Value |
|-------|-------|
| Output Language | zh / en |
| Locked | yes |
| Initialized By | agent/user |
| Initialized At | YYYY-MM-DD |
| Reason | ... |
```

## Capabilities

- **异步任务提交**：提交长时间运行的任务（安装、下载、容器拉取/构建、Nextflow 运行），自动追加 SUBMITTED 日志条目。任务名称格式：`{phase}_{action}_{instance}`。
- **日志追加**：向 execution_log.md 追加状态条目。
- **任务状态检查**：检查异步任务的状态、PID、进程组和日志输出。
- **论文元数据查询**：通过 DOI 或 accession 标识符提取论文元数据。

## Gotchas

- **Nextflow `-resume` 不检测 config 变更**：仅当进程的输入/脚本变化时才会重新运行。如果只修改了 `nextflow.config` 中的参数（如内存、CPU），缓存结果不会自动失效。需要手动删除相关进程的工作目录或确认变更范围。
- **容器镜像标签可变**：Docker 标签如 `latest` 或 `v1.0` 可被覆盖。应通过 digest（`image@sha256:...`）固定镜像，或记录拉取时的确切 digest。
- **补充数据链接失效**：论文补充材料 URL 经常失效。必须检查论文的期刊页面、补充材料标签页和版本化仓库（Zenodo、Figshare、GitHub releases），不得仅从 PDF 文本推断。
- **GEO/SRA/ENA 标识符不互通**：GEO accession（GSEXXXXX）、SRA accession（SRXXXXXX）和 ENA accession（PRJEBXXXXX）映射到不同的下载端点。确认数据实际存储位置后再选择下载方式。
- **参考基因组版本未标注**：许多论文未明确说明使用的参考基因组版本（如 GRCh37 vs GRCh38、TAIR10 vs Araport11）。Phase 1 中应从方法描述和代码仓库中推断并记录确切版本。
- **预印本与正式版本差异**：始终以 DOI 指向的最终出版版本为准。Methods 部分在 peer review 中可能被修改。
- **Nextflow 默认资源可能不足**：内存不足会导致静默 OOM 终止。Phase 3 中应为每个进程显式配置资源。
- **认证数据访问**：部分数据仓库（dbGaP、EGA）需要认证令牌。如果数据需要受控访问，在 Phase 1 的 data_manifest 中标记为 `requires-auth`，不要自动尝试下载。

## Rollback

当验证或执行发现更早阶段存在问题时：

1. 确定最早出错的阶段。
2. 记录 `Phase N - ROLLBACK: returning to Phase M because...`。
3. 记录 `Phase M - START: retry after rollback`。
4. 修复该阶段输出并重新运行受影响的后续阶段。