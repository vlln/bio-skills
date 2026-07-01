---
name: bio-reproducer
description: 引导 agent 通过分阶段报告、数据清单、异步长时间任务、Nextflow 编排和验证，在项目工作区内完成可复现的生物信息学论文复现。
compatibility: 需要 Bash 和 Python 3 运行辅助脚本；Nextflow、容器运行时和网络访问仅在需要它们的阶段使用。
metadata:
  skit:
    version: 0.4.2
    requires:
      bins:
        - bash
        - python3
        - paperutils
    keywords:
      - bioinformatics
      - reproducibility
      - nextflow
      - paper-reproduction
---

# Bio-Reproducer

## 何时使用

在项目工作区内使用本 skill 复现生物信息学论文，提供分阶段报告、数据清单、异步长时间命令和最终验证报告。不要用于快速工具查找或通用生物信息学建议。

## 核心协议

文件系统即状态机。`repro-data/execution_log.md` 是状态日志。通过读取文件恢复状态，而非依赖聊天记忆。

1. 确保 `repro-data/` 存在，所有复现状态均在其中操作。
2. 仅在 `repro-data/` 内初始化 Git（当 `.git/` 不存在时）。
3. 确保 `reproduction_options.md` 在 Phase 1 之前存在。此文件锁定全局选项，后续 agent 必须读取且不得擅自更改。
4. 读取 `execution_log.md`，然后检查 `.task_status/` 中的已提交异步任务，再开始新工作。
5. 加载当前阶段的参考文件。
6. 读取当前阶段所需的所有已完成前置阶段的输出。

小型临时文件可使用 `/tmp/`。复现数据、下载、Nextflow 工作目录和结果必须存放在 `repro-data/` 下，或用户明确批准的数据/临时目录中。

## 阶段映射

| Phase | 输出 | 参考文件 | 执行方式 |
|-------|--------|-----------|-----------|
| 1 Reader | `01_plan/plan.md` | `references/01_reader.md` | 资源收集和提取 |
| 2 Bootstrap | `02_bootstrap/bootstrap.md` | `references/02_bootstrap.md` | 混合；长时间安装异步执行 |
| 3 Provision | `03_provision/provision.md` | `references/03_provision.md` | 混合；容器/Nextflow 操作异步执行 |
| 4 Data | `04_data/data_manifest.md` | `references/04_data.md` | 混合；下载/Nextflow 操作异步执行 |
| 5 Run | `05_run/run_results.md` | `references/05_run.md` | 混合；Nextflow 编排运行异步执行；可选图表生成 |
| 6 Validate | `06_validate/report.md` | `references/06_validate.md` | 手动/自动对比；可选图表验证 |
| 7 Package | `README.md`、`run.sh`、`.gitignore` | `references/07_package.md` | 编写 README、入口脚本和 gitignore |

状态规则：

- 无 `reproduction_options.md`：在开始 Phase 1 前创建，然后记录 `Phase 1 - INFO: reproduction options initialized`。
- 无 `execution_log.md`：开始 Phase 1。
- 最后一条日志为 `Phase N - SUBMITTED: ...`：检查 `.task_status/` 和任务日志。
- 最后一条日志为 `Phase N - COMPLETED: ...` 且输出存在：开始 Phase N+1。
- 最后一条日志为 `Phase N - FAILED: ...`：诊断、重试或回滚。
- `06_validate/report.md` 存在且 verdict 为 REPRODUCED/PARTIAL：开始 Phase 7。
- `README.md`、`run.sh` 和 `.gitignore` 存在：复现完成。

## 阶段交接

阶段之间通过显式报告和清单交接，而非通过链式 Nextflow 配置继承。

- 新 agent 必须读取 `execution_log.md` 和已完成前置阶段的必要输出。
- `nextflow.config` 文件仅为可选的运行时配置；永远不要将其视为前置阶段成果的权威来源。
- 如需共享 Nextflow 设置，应创建 `02_bootstrap/nextflow.base.config`。后续阶段的 config 可以 include 该基础文件，但不得整体继承另一个阶段的 config。

关键状态文件：

- `reproduction_options.md`
- `execution_log.md`
- `.task_status/{task}.status`、`.pid`、`.pgid`、`.log`
- `01_plan/plan.md`
- `02_bootstrap/bootstrap.md`
- `03_provision/provision.md`
- `04_data/data_manifest.md`
- `05_run/run_results.md`
- `06_validate/report.md`
- `README.md`
- `run.sh`
- `.gitignore`

## 日志

使用以下格式记录有意义操作：

`Phase N - STATUS: message`

状态值：

| 状态 | 用途 |
|--------|-----|
| `START` | 有意义操作开始。 |
| `END` | 有意义操作以 `SUCCESS` 或 `FAILED` 结束。 |
| `SUBMITTED` | 异步任务已提交。 |
| `COMPLETED` | 阶段已完成且其必要输出存在。 |
| `FAILED` | 阶段或任务失败。 |
| `ROLLBACK` | 验证或诊断要求返回更早阶段。 |
| `INFO` | 影响后续 agent 的重要上下文。 |

记录阶段开始/完成、异步提交、任务状态变更、失败和回滚。不记录纯读取、目录创建或简单环境查询，除非其结果影响后续工作。SUBMITTED 条目必须记录任务日志文件路径，以便后续 agent 检查（使用 `async_submit.sh -L` 或 `append_log.sh -o`）。

## 全局选项

`reproduction_options.md` 在 Phase 1 之前一次性创建，是复现状态的一部分。每个阶段必须读取它以获取全局配置（图表模式、产出语言等）。后续 agent 仅在获得用户明确批准后方可更改，且必须记录更改原因。如果 agent 询问用户启动选项，将确切决策记录在此文件中；如果未提问，则记录保守的 agent 默认值及其能力假设。

模板：

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

图表模式规则：

- 启动决策是状态，不是聊天上下文。在 Phase 1 提取开始前，将用户选择或 agent 默认选择记录在 `Decision Record` 中。
- `generate` 是默认模式。所有阶段应尝试运行可用的绘图代码并保存图表，但不做视觉相似性判断。此模式不需要视觉多模态能力。
- `visual-validate` 仅在初始化 agent/model 具备可靠的视觉多模态能力且用户批准时使用。Phase 1 和 Phase 6 必须由视觉多模态 agent 执行；否则停止并报告能力阻塞。此模式下，Phase 6 对原图与复现图做 panel 级视觉比较。
- 不管哪种模式，图表生不出来就记 `blocked`，不影响其他验证。

产出语言规则：

- 所有阶段产出的 Markdown 文件（plan.md、bootstrap.md、provision.md、data_manifest.md、run_results.md、report.md、README.md、figure_comparison.md 等）的标题、章节名、描述文字和表格内容必须使用 `reproduction_options.md` 中配置的 Output Language 编写。
- `zh`：所有产出文件使用中文撰写。
- `en`：所有产出文件使用英文撰写。
- 不受语言配置影响的内容：代码块、命令、文件路径、URL、状态值（`COMPLETED`、`FAILED` 等）、模板字段名（如 `Paper Claims`、`Expected Results` 等）、日志条目格式（`Phase N - STATUS: ...`）、脚本文件中的代码逻辑。
- 脚本文件（如 `run.sh`）中的注释和 echo 输出应跟随产出语言。
- 语言在 Phase 1 初始化时锁定，后续阶段不得更改。

## 辅助脚本

从本 skill 的 `scripts/` 目录解析脚本。

```bash
async_submit.sh p4_data_fetch_batch1 "nextflow run data.nf -resume" . -l p4_data_fetch_batch1.log -L execution_log.md
# -L 标志自动追加一条带日志文件路径的 SUBMITTED 条目。
# 对于非异步任务条目，使用普通 append_log.sh：
append_log.sh "Phase 3 - COMPLETED: provision ready" . -p 3 -s COMPLETED
check_status.sh p4_data_fetch_batch1 . status
check_status.sh ignored . list
check_status.sh p4_data_fetch_batch1 . log
paperutils get 10.1234/example --json
paperutils explain PRJEB12345 --json
```

异步任务名称应使用 `{phase}_{action}_{instance}` 格式，例如 `p4_data_fetch_batch1` 或 `p5_run_retry_001`。

## 规则

- 复现状态仅写入 `repro-data/` 内，用户批准的外部数据/临时路径除外。
- 所有阶段产物、中间文件和日志必须存放在该阶段自身的输出目录中（例如 Phase 3 的日志归入 `03_provision/`，不得放在工作区根目录）。只有 `execution_log.md`、`reproduction_options.md`、`.task_status/` 以及最终的 `README.md`/`run.sh`/`.gitignore` 存放在 `repro-data/` 根目录。
- 在 `repro-data/` 内提交有意义的状态变更；绝不提交该 Git 仓库外的文件。
- 写入阶段输出前检查是否已存在。
- 在 Phase 2-5 中，通过 `async_submit.sh` 运行安装、下载、容器拉取/构建、Nextflow 运行以及其他长时间或不可预测的操作。
- 同步命令允许用于状态读取、脚本生成、配置编辑和简短检查。
- Phase 1 从论文中收集信息，并获取轻量级的引用资源，如补充文件、代码仓库、协议页面和元数据页面。不安装环境或下载分析规模的数据。
- Phase 1 必须检查论文页面、补充材料标签页和版本化仓库记录；不得仅从 PDF 文本推断补充材料不存在。遵循 `references/01_reader.md` 中的资源完整性检查要求。
- Phase 1 可以通过外部元数据 API 解析论文中提供的 DOI/accession 标识符，但必须将这些结果与论文声明分别记录在 `01_plan/plan.md` 中；不得估算、广泛搜索或决定数据策略。
- 在 Phase 3-5 的 Nextflow 编排运行中使用 `nextflow ... -resume`。
- 脚本和代码不得使用硬编码或绝对路径/参数。所有路径、阈值和可配置值必须从 plan.md、数据清单、环境变量或工作区内的相对路径推导。目标是让其他人 clone 仓库后无需编辑任何脚本即可复现。
- 在判定长时间任务失败或成功之前，检查其任务状态、进程状态和日志。
- 所有产出文件的自然语言必须遵循 `reproduction_options.md` 中配置的 Output Language。`zh` 模式下所有标题、章节名、描述文字和表格内容使用中文；`en` 模式下使用英文。代码、命令、路径、状态值和模板字段名不受此限制。

## 回滚

当验证或执行显示更早阶段存在问题时：

1. 确定最早出错的阶段。
2. 记录 `Phase N - ROLLBACK: returning to Phase M because...`。
3. 记录 `Phase M - START: retry after rollback`。
4. 修复该阶段输出并重新运行受影响的后续阶段。