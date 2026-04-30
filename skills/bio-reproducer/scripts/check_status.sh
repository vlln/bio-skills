#!/usr/bin/env bash
# check_status.sh - 检查后台任务状态
set -euo pipefail

task="" dir="" act="status"

usage() { cat << EOF
用法: $0 <task> <dir> [status|stop|kill|clean|log|list]
EOF
exit 1; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h) usage ;;
        status|stop|kill|clean|log|list) act="$1"; shift ;;
        *) [[ -z "$task" ]] && task="$1" || dir="$1"; shift ;;
    esac
done

[[ -z "$task" || -z "$dir" ]] && usage

sd="${dir}/.task_status"
sf="${sd}/${task}.status" pf="${sd}/${task}.pid"
lf="${dir}/${task}.log" gf="${sd}/${task}.pgid"

# 状态图标
icon() { case "$1" in
    RUNNING) echo 🔵 ;; SUCCESS) echo ✅ ;; FAILED) echo ❌ ;;
    STOPPED) echo 🔴 ;; *) echo ⚪ ;;
esac; }

check() {
    [[ ! -f "$sf" ]] && { echo "⚪ NOT_FOUND"; return; }
    local st=$(cat "$sf") pid=$(cat "$pf" 2>/dev/null || echo N/A)
    local pg=$(cat "$gf" 2>/dev/null || echo "")
    local run=false
    [[ "$pid" != N/A ]] && ps -p "$pid" > /dev/null 2>&1 && run=true
    
    echo "$(icon "$st") $st | PID:$pid${pg:+ | PGID:$pg}"
    if $run; then
        local info=$(ps -p "$pid" -o %cpu,%mem,etime --no-headers 2>/dev/null)
        echo "运行中: $info"
        [[ -f "$lf" ]] && { echo "---日志末尾---"; tail -3 "$lf"; }
    fi
}

stop() {
    local pid=$(cat "$pf") pg=$(cat "$gf" 2>/dev/null || echo "")
    if ! ps -p "$pid" > /dev/null 2>&1; then
        echo STOPPED > "$sf"; echo "已停止"; return
    fi
    [[ -n "$pg" ]] && kill -TERM -- -"$pg" 2>/dev/null || kill -TERM "$pid"
    local c=0
    while ps -p "$pid" > /dev/null 2>&1 && [[ $c -lt 30 ]]; do
        sleep 1; c=$((c+1))
    done
    ps -p "$pid" > /dev/null 2>&1 && { echo "需强制终止: $0 $task $dir kill"; return 1; }
    echo STOPPED > "$sf"; echo "✅ 已停止"
}

kill_task() {
    local pid=$(cat "$pf") pg=$(cat "$gf" 2>/dev/null || echo "")
    [[ -n "$pg" ]] && kill -KILL -- -"$pg" 2>/dev/null || kill -KILL "$pid"
    sleep 1
    echo STOPPED > "$sf"; echo "✅ 已终止"
}

clean() {
    local pid=$(cat "$pf" 2>/dev/null || echo "")
    [[ -n "$pid" ]] && ps -p "$pid" > /dev/null 2>&1 && { echo "进程仍运行，先停止"; return 1; }
    rm -f "$sf" "$pf" "${sd}/${task}.start" "${sd}/${task}.end" "${sd}/${task}.sh" "$gf"
    echo "✅ 已清理"
}

log() {
    [[ -f "$lf" ]] && tail -20 "$lf" || echo "无日志"
}

list_tasks() {
    echo "任务列表:"
    for f in "${sd}"/*.status; do
        [[ -f "$f" ]] || continue
        local n s p
        n=$(basename "$f" .status)
        s=$(cat "$f")
        p=$(cat "${sd}/${n}.pid" 2>/dev/null || echo -)
        printf "%-12s %-8s %s\n" "$n" "$s" "$p"
    done
}

case "$act" in
    status) check ;;
    stop) stop ;;
    kill) kill_task ;;
    clean) clean ;;
    log) log ;;
    list) list_tasks ;;
esac
