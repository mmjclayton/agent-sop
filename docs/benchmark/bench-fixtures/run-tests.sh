#!/usr/bin/env bash
# Harness fixtures for codex-bench.sh session pairs (P121): a fake `codex` on PATH and a
# tiny template stand in for Codex and hst-tracker, so no model or quota is used.
set -euo pipefail
SOURCE="$(cd "$(dirname "$0")/../../.." && pwd -P)"
BENCH="$SOURCE/docs/benchmark/codex-bench.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/bin" "$WORK/codex-home" "$WORK/trace"
printf '{"fake":true}\n' > "$WORK/codex-home/auth.json"
cat > "$WORK/bin/codex" <<'FAKE'
#!/usr/bin/env bash
# Fake Codex: logs each call, edits the project and prints JSON events.
set -euo pipefail
[ "${1:-}" = --version ] && { echo 'codex-cli fake'; exit 0; }
# The harness scrubs the environment, so state lives beside this script.
FAKE_TRACE="$(cd "$(dirname "$0")/.." && pwd -P)/trace"
FAKE_FAIL_RESUME=0; [ -f "$FAKE_TRACE/fail-resume" ] && FAKE_FAIL_RESUME=1
[ "${1:-}" = exec ] || exit 64
shift
mode=new; dir=$PWD; out=''
[ "${1:-}" = resume ] && { mode=resume; shift; }
while [ $# -gt 0 ]; do
    case "$1" in
        -C) dir=$2; shift ;;
        -o|--output-last-message) out=$2; shift ;;
        --last) [ "$mode" = resume ] || exit 65 ;;
        -c|-m|-s|--add-dir) shift ;;
    esac
    shift
done
prompt=$(cat)
n=$(find "$FAKE_TRACE" -name 'call-*' | wc -l | tr -d ' ')
printf '%s\t%s\t%s\n' "$mode" "$dir" "$prompt" > "$FAKE_TRACE/call-$n"
case "$prompt" in
    *"Continue where we left off"*) echo client > "$dir/client/rpe.txt"; msg='Picking up the client side of RPE.' ;;
    *"stopping here"*) echo 'decisions: last set only' > "$dir/notes.md"; msg='Notes written.' ;;
    *) echo server > "$dir/server/rpe.txt"; msg='Server side done.' ;;
esac
[ "$FAKE_FAIL_RESUME" = 1 ] && [ "$mode" = resume ] && exit 3
printf '{"type":"item.completed","item":{"type":"agent_message","text":"%s"}}\n' "$msg"
printf '{"type":"turn.completed","usage":{"input_tokens":10,"cached_input_tokens":0,"output_tokens":5}}\n'
[ -z "$out" ] || echo "$msg" > "$out"
FAKE
chmod +x "$WORK/bin/codex"

template() {
    local t=$WORK/template
    mkdir -p "$t/server" "$t/client"
    for side in server client; do
        printf '{"scripts":{"test":"echo Tests: 1 passed"}}\n' > "$t/$side/package.json"
    done
    printf '# Project\n' > "$t/CLAUDE.md"
    printf '{"base":"fixture","server":1,"client":1}\n' > "$t/.bench-baseline.json"
}
template

bench() { # out task arm rep, with END_MODE from the caller
    PATH="$WORK/bin:$PATH" CODEX_HOME="$WORK/codex-home" \
        BENCH_TEMPLATE="$WORK/template" BENCH_ARMS="native context" bash "$BENCH" one "$@"
}
reset_trace() { rm -f "$WORK/trace"/call-*; }

# ask: session 1, the end prompt resumed in the same session from the project, then session 2.
mkdir -p "$WORK/out-ask"; reset_trace
BENCH_END_MODE=ask bench "$WORK/out-ask" 10+11 native 1 2> "$WORK/ask.log" || { tail -20 "$WORK/ask.log"; exit 1; }
run="$WORK/out-ask/runs/t10+11-native-r1"
[ "$(find "$WORK/trace" -name 'call-*' | wc -l | tr -d ' ')" = 3 ]
cut -f1 "$WORK/trace/call-0" | grep -qx new
cut -f1 "$WORK/trace/call-1" | grep -qx resume
[ "$(cut -f2 "$WORK/trace/call-1")" = "$run/proj" ] || [ "$(cut -f2 "$WORK/trace/call-1")" = "$(cd "$run/proj" && pwd -P)" ]
cut -f3 "$WORK/trace/call-1" | grep -q "stopping here"
cut -f3 "$WORK/trace/call-2" | grep -qx "Continue where we left off."
jq -e '.end_mode == "ask" and .earlier_sessions[0].end.sent == true and .earlier_sessions[0].end.exit_code == 0
       and .earlier_sessions[0].end.usage != null and .valid == true' "$run/result.json" >/dev/null
jq -e '.earlier_sessions[0].files_changed | index("server/rpe.txt") != null and index("notes.md") != null and index("client/rpe.txt") == null' "$run/result.json" >/dev/null
jq -e '.first_message == "Picking up the client side of RPE."' "$run/result.json" >/dev/null
test ! -e "$run/home/.codex/auth.json"
printf 'PASS: ask mode resumes session 1 with the end prompt before session 2, and records it\n'

# closed: no end prompt; session 2 still sees what session 1 left.
mkdir -p "$WORK/out-closed"; reset_trace
BENCH_END_MODE=closed bench "$WORK/out-closed" 10+11 native 1 2> "$WORK/closed.log" || { tail -20 "$WORK/closed.log"; exit 1; }
run="$WORK/out-closed/runs/t10+11-native-r1"
[ "$(find "$WORK/trace" -name 'call-*' | wc -l | tr -d ' ')" = 2 ]
if grep -q resume "$WORK/trace/call-1"; then echo 'FAIL: closed mode resumed session 1'; exit 1; fi
jq -e '.end_mode == "closed" and .earlier_sessions[0].end.sent == false and .valid == true' "$run/result.json" >/dev/null
test -f "$run/proj/server/rpe.txt"
printf 'PASS: closed mode sends no end prompt and carries session 1 work forward\n'

# A failed end turn invalidates the pair instead of scoring session 2 from a half-closed base.
mkdir -p "$WORK/out-fail"; reset_trace
touch "$WORK/trace/fail-resume"
if BENCH_END_MODE=ask bench "$WORK/out-fail" 10+11 native 1 2> "$WORK/fail.log"; then
    echo 'FAIL: a failed end turn was accepted'; exit 1
fi
grep -q 'end-of-session turn for session 1' "$WORK/fail.log"
rm "$WORK/trace/fail-resume"
[ "$(find "$WORK/trace" -name 'call-*' | wc -l | tr -d ' ')" = 2 ]
printf 'PASS: a failed end turn stops the pair before session 2\n'

# Bad end mode and mixed end modes in one output directory are refused.
if BENCH_END_MODE=sometimes bash "$BENCH" report "$WORK/out-ask" 2> "$WORK/bad.log"; then echo 'FAIL: bad end mode accepted'; exit 1; fi
grep -q 'BENCH_END_MODE must be closed or ask' "$WORK/bad.log"
mkdir -p "$WORK/out-mixed/runs"; echo ask > "$WORK/out-mixed/end-mode"
if PATH="$WORK/bin:$PATH" CODEX_HOME="$WORK/codex-home" BENCH_TEMPLATE="$WORK/template" BENCH_END_MODE=closed \
    bash "$BENCH" run "$WORK/out-mixed" --tasks 10+11 2> "$WORK/mixed.log"; then echo 'FAIL: mixed end modes accepted'; exit 1; fi
grep -q 'was run with end mode ask' "$WORK/mixed.log"
printf 'PASS: invalid and mixed end modes are refused\n'

# The report carries the end mode and counts the end turn in session-1 time and tokens.
bash "$BENCH" report "$WORK/out-ask" > /dev/null 2>&1
awk -F'\t' 'NR == 2 { exit !($NF == "ask" && $(NF - 1) == 10) }' "$WORK/out-ask/scores.tsv"
printf 'PASS: report includes the end mode and the end turn in session-1 tokens\n'
