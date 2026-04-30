#!/usr/bin/env bash
# async_submit.sh - 后台异步任务提交
set -euo pipefail

task="" cmd="" wdir=""
logfile="" envfile=""
setsid_mode=true

usage() { cat << EOF
用法: $0 <task> <cmd> <dir> [-l log] [-e env] [-n]
EOF
exit 1; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        -l) logfile="$2"; shift 2 ;;
        -e) envfile="$2"; shift 2 ;;
        -n) setsid_mode=false; shift ;;
        -h) usage ;;
        *)
            if [[ -z "$task" ]]; then task="$1"
            elif [[ -z "$cmd" ]]; then cmd="$1"
            elif [[ -z "$wdir" ]]; then wdir="$1"
            fi
            shift
            ;;
    esac
done

[[ -z "$task" || -z "$cmd" || -z "$wdir" ]] && usage

sd="${wdir}/.task_status"
mkdir -p "$sd"
[[ -z "$logfile" ]] && logfile="${wdir}/${task}.log"

pf="${sd}/${task}.pid"
if [[ -f "$pf" ]]; then
    old=$(cat "$pf")
    ps -p "$old" > /dev/null 2>&1 && { echo "任务 ${task} 已运行"; exit 1; }
    rm -f "$pf" "${sd}/${task}.status"
fi

script="${sd}/${task}.sh"

# Write the script directly using printf to avoid escaping issues
{
    printf '#!/usr/bin/env bash\n'
    printf '# Note: Do NOT use set -e in this script - we need to capture exit codes\n'
    printf 'set -uo pipefail\n'
    printf 'cd %q\n' "$wdir"
    printf '[[ -f %q ]] && source %q\n' "$envfile" "$envfile"
    printf 'date "+START: %%F %%T" > %q\n' "${sd}/${task}.start"
    printf 'echo RUNNING > %q\n' "${sd}/${task}.status"
    printf '\n# Run the actual command and capture exit code\n'
    printf 'bash -c %q >> %q 2>&1\n' "$cmd" "$logfile"
    printf 'ec=$?\n'
    printf '\nif [[ $ec -eq 0 ]]; then\n'
    printf '    echo SUCCESS > %q\n' "${sd}/${task}.status"
    printf 'else\n'
    printf '    echo FAILED > %q\n' "${sd}/${task}.status"
    printf 'fi\n'
    printf 'date "+END: %%F %%T" > %q\n' "${sd}/${task}.end"
    printf 'exit $ec\n'
} > "$script"

chmod +x "$script"

if $setsid_mode; then
    setsid bash "$script" & disown
else
    nohup bash "$script" >/dev/null 2>&1 &
fi
pid=$!

sleep 0.3
if ! ps -p "$pid" > /dev/null 2>&1; then
    real=$(pgrep -f "${task}.sh" | head -1) || true
    [[ -n "$real" ]] && pid="$real"
fi

echo "$pid" > "$pf"
pgid=$(ps -o pgid= -p "$pid" 2>/dev/null | tr -d ' ') || true
[[ -n "$pgid" && "$pgid" != "$pid" ]] && echo "$pgid" > "${sd}/${task}.pgid"

echo "✅ ${task} | PID:$pid | ${logfile}"
