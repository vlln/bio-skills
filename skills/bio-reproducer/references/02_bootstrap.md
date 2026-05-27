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

5. **Network Test** - 检测容器网络与宿主机网络是否冲突，避免后续
   阶段因网络问题失败：

   a. **宿主机网络拓扑** — 记录宿主机网络接口、子网、DNS 配置：
      - `ip addr show` 或 `ifconfig`（所有接口及 CIDR）
      - `ip route show` 或 `route -n`（路由表）
      - `cat /etc/resolv.conf`（DNS 配置）

   b. **容器 DNS 解析** — 验证容器内能解析外部域名：
      ```bash
      # Docker
      docker run --rm alpine nslookup google.com
      # Singularity/Apptainer
      singularity exec docker://alpine nslookup google.com
      ```

   c. **容器外网连通性** — 验证容器能访问外部网络：
      ```bash
      # Docker
      docker run --rm alpine ping -c 3 -W 5 8.8.8.8
      # Singularity/Apptainer
      singularity exec docker://alpine ping -c 3 -W 5 8.8.8.8
      ```

   d. **子网冲突检测** — 对比宿主机接口子网与容器运行时默认网桥子网：
      - Docker 默认网桥通常为 `172.17.0.0/16`
      - 检查宿主机路由表中是否有重叠子网
      - 若存在冲突，记录冲突子网并警告用户；后续阶段需配置
        `nextflow.config` 中的容器网络参数或调整 Docker daemon 配置

   e. **代理检测** — 若宿主机设置了 `HTTP_PROXY`/`HTTPS_PROXY`/`NO_PROXY`，
      记录代理配置并验证容器内能通过代理访问外网。
      容器运行时可能需要额外配置才能继承代理环境变量。

   网络测试结果写入 `bootstrap.md` 的独立章节。
   若检测到子网冲突或连通性失败，必须在报告中明确标记为 **WARNING**
   并说明对后续阶段的影响和推荐的解决方案。

6. **Test** - 验证安装：
   - `nextflow run hello`
   - 容器测试运行

## Output

- `02_bootstrap/bootstrap.md` - 环境状态报告（含网络测试结果）
- `02_bootstrap/nextflow.base.config` - 可选基础运行配置
  - 只有后续 Nextflow 阶段需要固定 executor、容器 runtime、profile 或资源默认值时才生成
  - 基础配置应该避免过度约束, 而且应该对关键选项询问用户
  - 阶段交接以 `bootstrap.md` 为准, 不以 config 为准

## Key Principles

- **先检查，后询问** - 不假设环境状态, 绝对禁止不经同意的安装
- **尊重用户选择** - 安装方式询问用户
- **记录实际状态** - 系统已有 vs 本次安装
- **交接靠报告** - 后续 agent 应读取 `bootstrap.md`, 不从 config 推断环境状态
