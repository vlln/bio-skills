# Phase 1: Reader

## Goal
完备、全面、可追溯地收集论文复现信息，形成唯一的
`01_plan/plan.md`。P1 可以获取轻量研究资源并反复回填发现的信息，
但不估算、不部署、不下载分析规模数据。

论文声明、已获取资源和外部标识符记录必须分区记录，不能混为同一来源。
`plan.md` 还必须包含一段足够详细的论文解读，使未读原文的后续 agent
或人类能够清楚理解论文研究了什么、用了什么数据和方法、声称得到什么结果。

## Information Sources (优先级)
1. **主论文** - 所有明确陈述
2. **补充材料** - 方法细节
3. **数据可用性页面** - 样本元数据（如有 accession）
4. **论文明确给出的资源链接** - 代码仓库、补充文件、协议、项目页面等
5. **外部标识符 API** - 仅解析论文明确给出的 DOI/accession

## Mandatory Source Discovery

P1 不能只读本地 PDF。即使用户只提供 `./paper/*.pdf`, 也必须把论文页面本身
当作资源目录来检查，避免遗漏 PDF 文本中不显示的附件。

对每篇论文必须检查并记录:

1. **本地 PDF / HTML 正文**: 标题、DOI、版本、Data availability、
   Code availability、所有 Supplementary Note/Table/Figure/Data 引用。
2. **预印本或 DOI landing page**: 例如 medRxiv/bioRxiv 的 article page。
3. **Supplementary material 页面或标签页**: 对 medRxiv/bioRxiv 必查
   `*.supplementary-material` 或页面中的 `Supplementary material` tab。
4. **出版商正式版页面**: 如果 DOI、预印本页或搜索结果显示 version of record,
   必须记录正式版 DOI、资源页和补充文件清单；不要把正式版声明混入本地
   preprint 的 `Paper Claims`。
5. **代码/数据仓库版本页**: 对 Zenodo/Figshare/OSF/GitHub releases 等,
   必须记录 cited version、latest/current version、文件清单、文件大小和
   是否下载。
6. **数据可用性页面**: 仅登记受控数据、原始测序数据、大型参考库或容器的
   位置和访问要求；不要在 P1 下载。

### Web Resource Enumeration

打开论文页面后, 用页面文本或 HTML 搜索这些模式并把命中结果纳入
`Supplementary Materials Inventory` 或 `Resource Locations`:

```text
Supplementary|supplement|supplemental|Extended Data|Source Data
Data availability|Code availability|Availability
media-|DC1|DC2|MOESM|ESM|supplements/
docx|xlsx|xls|csv|tsv|zip|tar|gz|pdf
Zenodo|Figshare|OSF|GitHub|GitLab|Dryad|GEO|SRA|ENA|dbGaP|EGA
version|latest|version of record|published|update
```

For medRxiv/bioRxiv specifically, check both:

```text
https://www.medrxiv.org/content/{doi-version}.supplementary-material?versioned=true
https://www.biorxiv.org/content/{doi-version}.supplementary-material?versioned=true
```

where `{doi-version}` is a DOI-like article id such as
`10.1101/2025.03.31.25324952v1`.

Do not conclude "no supplementary URL" from the PDF text alone. Only mark a
supplementary item as not found after checking the article landing page and its
supplementary-material page/tab.

### Version Handling

Preprints and published articles are separate sources. If the workspace contains
a v1 PDF but public pages show v2 or a version of record:

- Keep `Paper Claims` scoped to the user-provided paper/version and any cited
  resources for that version.
- Record v2/formal-publication resources in `External Identifier Records` and
  `Source Conflicts And Gaps`.
- If v2/formal resources are lightweight (supplementary docs, tables, code
  manifests, README files), download or inventory them only when they are needed
  to resolve the reproduction target; otherwise record URL, size, version and
  reason deferred.
- Never silently replace v1 claims with v2/formal claims.

### Supplement Completeness Check

Before marking P1 complete, perform a reverse check:

- Every `Supplementary Note/Table/Figure/Data` mention in the paper must have a
  row in `Supplementary Materials Inventory`.
- Every cited code/data repository must have a row in `Resource Locations`.
- Every DOI/accession explicitly present in the paper or downloaded supplement
  must have a row in `External Identifier Records` or be listed in
  `Uncertainties` with the reason it was not resolved.
- Each row must state one of: `Downloaded and reviewed`,
  `Downloaded and inventoried`, `URL found; deferred`, `Controlled access`,
  `Large resource; deferred`, or `Not found after checking [specific pages]`.

If the check finds a missing cited lightweight resource, fetch it and re-read
enough to update `plan.md` before completion.

## Boundaries
- **只做**: 读论文、获取并阅读轻量 cited resources、记录 URL/本地路径、解析论文明确给出的 DOI/accession
- **可获取**: supplementary files (`pdf`, `docx`, `xlsx`, `csv`, `tsv`),
  source data tables, code repositories, README/docs, protocol pages, small
  config/example files, repository file manifests
- **不获取**: raw sequencing files, full reference genomes, large archives, container images, package environments, model checkpoints, paid/controlled-access data
- **不做**: 搜索未在论文中出现的资料、安装环境、运行 pipeline、估算规模、假设版本、决定数据策略
- 外部 API 结果只写入 `External Identifier Records`, 不得改写 `Paper Claims`
- 获取新资源后必须继续阅读并回填 `plan.md`; P1 可以多轮迭代直到 cited lightweight resources 已登记和处理

## What to Extract

**Critical**: "Code and Data Availability" 通常在论文**末尾**，不要遗漏。

| Category | Examples |
|----------|----------|
| Code Availability | GitHub URL, Docker/Singularity 镜像, 许可证 |
| System Requirements | OS, 内核, 包管理器 |
| Environment | 软件及版本 (STAR 2.7.10a, Python 3.8) |
| Data | 数据库, Accession IDs, 样本数 |
| Parameters | 工具参数, 阈值, cutoff |
| Steps | 流程顺序, 输入/输出 |
| Expected Results | 图表, 关键数字 |
| Paper Understanding | 研究问题, 背景, 数据设计, 方法逻辑, 主要发现, 复现目标 |
| Versioned Resources | preprint v1/v2、正式版、Zenodo/Figshare 版本和文件清单 |

## Output: 01_plan/plan.md

```markdown
# Paper: [Title]
DOI: [doi or URL]

## Paper Understanding

### Research Question
[用 1-3 段说明论文要回答的问题、背景和生物学/计算目标。]

### Study Design
[说明样本/队列/实验设计/比较组/数据类型, 只写论文明确给出的内容。]

### Method Overview
[用清晰 prose 解释主要分析流程和方法逻辑, 让后续 agent 理解每一步为什么存在。]

### Key Findings
[列出论文声称的主要发现、关键图表和关键数值。]

### Reproduction Target
[说明复现时最需要重现的 outputs、figures、tables、metrics 或 qualitative findings。]

## Paper Claims

### Analysis Steps
1. [Step]: [input] → [tool] → [output]

### Code and Data Availability
| Resource | URL/Identifier | Purpose | Location in Paper |

### System Requirements
| Component | Requirement | Notes | Location in Paper |

### Environment Requirements
| Software | Version | Purpose | Source in Paper |

### Data Requirements
| Database | Accession | Samples | Type | Location in Paper |

### Parameters
| Tool | Parameter | Value | From |

### Expected Results
| Output | Figure/Table | Expected Value |

## Source Files Reviewed
| File/URL | Type | Local Path | Status | Notes |

## Supplementary Materials Inventory
| Item | Type | URL/Path | Local Path | Mentioned In | Status | Notes |

## Resource Locations
| Resource | Type | URL/Identifier | Local Path | Purpose | Location in Paper | Access Notes |

## External Identifier Records
| Identifier | Database | Resolved Type | Title/Description | Linked IDs | Source API | Retrieved At |

## Source Conflicts And Gaps
| Item | Paper Statement | External Record | Issue |

## Uncertainties
| Item | Issue | Source |
```

## Rules
1. **唯一计划文件** - 所有 P1 发现都回填 `01_plan/plan.md`, 不创建并行 metadata/accession 计划文件
2. **论文声明优先** - `Paper Claims` 只写论文、补充材料、数据可用性页面和已获取 cited resources 的明确陈述
3. **标识符可解析** - DOI/SRA/ENA/GEO 等论文明确给出的标识符可用 `fetch_metadata.py` 查询并记录
4. **获取轻量资源** - 对论文明确链接的代码、补充材料、协议和小型表格, 应获取到 `01_plan/resources/` 或记录本地已有路径
5. **记录获取状态** - 每个资源必须记录 URL/identifier、本地路径、状态和访问备注; 不只列出“可获得”
6. **写清论文解读** - `Paper Understanding` 用 prose 写出论文内容, 但不得加入论文外判断或复现可行性评估
7. **最小重复** - 用更少字符表达完全相同的信息量; 允许同一事实在 `Paper Understanding` 中摘要出现、在 `Paper Claims` 中精确可核对出现, 但避免复制粘贴式重复
8. **章节职责清晰** - `Resource Locations` 记录资源用途和获取位置; `Environment Requirements` 只记录运行环境/软件版本要求
9. **不部署** - 不安装、不构建、不运行分析, 不写 HOW，只写 WHAT
10. **标记缺失** - 用 "Not specified" 或 "TBD"
11. **引用位置** - 注明章节/图表/URL/文件路径
12. **不估算** - 不估算下载规模、资源需求、复现可行性或替代策略
13. **大资源暂停** - 遇到大文件、原始数据、容器、环境或受限资源, 只登记位置和访问要求, 留给后续 phase
12. **页面附件必查** - 对预印本/出版商页面的 supplementary tab、`media-*`,
    `MOESM*`, `DC*`, `supplements/*` 附件必须检查；PDF 文本缺少直链不等于
    附件不存在
13. **版本不混写** - v1/v2/正式版资源必须分别登记；除非用户明确要求切换
    目标版本, 不要用新版资源覆盖旧版论文声明

## Completion Sanity Check

P1 完成前必须在工作区或网页内容中完成一次资源完整性检查。可用 `rg`
或等效方式检查本地文本、下载的补充材料文本提取结果和页面 HTML:

```bash
rg -n "Supplementary|supplement|Data availability|Code availability|Zenodo|Figshare|GitHub|version|latest|media-|MOESM|DC[0-9]|docx|xlsx|csv|tsv|zip|gz" 01_plan/resources
```

然后确认:

- `Supplementary Materials Inventory` 已覆盖所有 Supplementary Notes/Tables/
  Figures/Data 资源。
- `Source Files Reviewed` 包含 article landing page 和 supplementary material
  page, 或解释为什么无法访问。
- `Resource Locations` 包含所有论文声明的数据、代码、协议、仓库和小型表格。
- `External Identifier Records` 区分论文 DOI、代码/数据 DOI、版本 DOI 和
  version-of-record DOI。
- `Source Conflicts And Gaps` 记录 v1/v2/正式版差异、缺失补充材料、访问限制
  和下载延后原因。

## Helper

Use `scripts/fetch_metadata.py` only for identifiers already present in the
paper or supplement:

```bash
fetch_metadata.py doi 10.1234/example -f markdown
fetch_metadata.py ena PRJEB12345 -f markdown
fetch_metadata.py geo GSE12345 -f markdown
```

Copy relevant facts into `External Identifier Records`; do not create a
separate metadata file unless the user asks.

## Completion
- 输出 `01_plan/plan.md`
- 记录状态为 COMPLETED
- Git commit
