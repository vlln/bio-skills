#!/usr/bin/env bash
# append_log.sh - 追加执行日志
set -euo pipefail

msg="" wdir="" phase="" st="" act="" in="" out="" note="" lf=""

usage() { cat << EOF
用法: $0 <msg> [dir] [-p N] [-s STATUS] [-a ACTION] [-i INPUT] [-o OUTPUT]
EOF
exit 1; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        -p) phase="$2"; shift 2 ;;
        -s) st="$2"; shift 2 ;;
        -a) act="$2"; shift 2 ;;
        -i) in="$2"; shift 2 ;;
        -o) out="$2"; shift 2 ;;
        -n) note="$2"; shift 2 ;;
        -f) lf="$2"; shift 2 ;;
        -h) usage ;;
        *) [[ -z "$msg" ]] && msg="$1" || wdir="$1"; shift ;;
    esac
done

[[ -z "$msg" ]] && usage
[[ -z "$wdir" ]] && wdir="$(pwd)"
[[ -z "$lf" ]] && lf="${wdir}/execution_log.md"

# 自动解析 "Phase N - STATUS: desc" 格式
if [[ "$msg" =~ Phase\ ([0-9]+)\ -\ ([A-Z]+): ]]; then
    [[ -z "$phase" ]] && phase="${BASH_REMATCH[1]}"
    [[ -z "$st" ]] && st="${BASH_REMATCH[2]}"
fi

# 创建日志文件
[[ ! -f "$lf" ]] && cat > "$lf" << 'EOF'
# Execution Log

---
EOF

# 状态图标 (不使用emoji，使用纯文本)
icon() { case "$1" in
    RUNNING) echo "[RUN]" ;;
    COMPLETED) echo "[OK]" ;;
    FAILED) echo "[ERR]" ;;
    SUBMITTED) echo "[SUB]" ;;
    STOPPED) echo "[STP]" ;;
    ROLLBACK) echo "[RBK]" ;;
    START) echo "[>>]" ;;
    END) echo "[<<]" ;;
    *) echo "[LOG]" ;;
esac; }

# 阶段名
pname() { case "$1" in
    1) echo Reader ;;
    2) echo Bootstrap ;;
    3) echo Provision ;;
    4) echo Data ;;
    5) echo Run ;;
    6) echo Validate ;;
esac; }

# 生成条目
ts=$(date '+%F %T')
entry="## [$ts] $(icon "$st") $msg\n"
[[ -n "$phase" ]] && entry+="Phase $phase: $(pname "$phase")\n"
[[ -n "$act" ]] && entry+="动作: $act\n"
[[ -n "$in" ]] && entry+="输入: $in\n"
[[ -n "$out" ]] && entry+="输出: $out\n"
[[ -n "$st" ]] && entry+="状态: $st\n"
[[ -n "$note" ]] && entry+="备注: $note\n"
entry+="---\n"

printf "%b" "$entry" >> "$lf"

echo "✅ $ts | $msg"
