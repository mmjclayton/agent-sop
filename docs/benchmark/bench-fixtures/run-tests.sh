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
mode=new; dir=$PWD; out=''; thread=thread-1; args="$*"
if [ "${1:-}" = resume ]; then mode=resume; thread=$2; shift 2; fi
while [ $# -gt 0 ]; do
    case "$1" in
        -C) dir=$2; shift ;;
        -o|--output-last-message) out=$2; shift ;;
        -c|-m|-s|--add-dir) shift ;;
    esac
    shift
done
prompt=$(cat)
n=$(find "$FAKE_TRACE" -name 'call-*' | wc -l | tr -d ' ')
auth=no; [ -f "$CODEX_HOME/auth.json" ] && auth=yes
printf '%s\t%s\t%s\n' "$mode" "$dir" "$prompt" > "$FAKE_TRACE/call-$n"
printf '%s\n%s\n' "$args" "$auth" > "$FAKE_TRACE/args-$n"
[ -f "$FAKE_TRACE/wrong-thread" ] && [ "$mode" = resume ] && thread=thread-other
printf '{"type":"thread.started","thread_id":"%s"}\n' "$thread"
case "$prompt" in
    *"Continue where we left off"*) echo client > "$dir/client/rpe.txt"; msg='Picking up the client side of RPE.'
        if [ -f "$FAKE_TRACE/no-peek" ]; then
            printf '{"type":"item.completed","item":{"type":"command_execution","command":"cat .codex/hooks.json docs/agent-memory/session-notes.md"}}\n'
        else
            printf '{"type":"item.completed","item":{"type":"command_execution","command":"ls ~/.codex"}}\n'
        fi ;;
    *"stopping here"*) echo 'decisions: last set only' > "$dir/notes.md"; msg='Notes written.' ;;
    *) echo server > "$dir/server/rpe.txt"; msg='Server side done.' ;;
esac
[ "$FAKE_FAIL_RESUME" = 1 ] && [ "$mode" = resume ] && exit 3
[ -f "$FAKE_TRACE/no-usage" ] && [ "$mode" = resume ] && { printf '{"type":"item.completed","item":{"type":"agent_message","text":"x"}}\n'; exit 0; }
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
# The end turn resumes session 1 by its thread id, with session 1's sandbox, model and a login present.
head -n1 "$WORK/trace/args-1" | grep -q '^resume thread-1 '
head -n1 "$WORK/trace/args-1" | grep -q 'sandbox_mode="workspace-write"'
head -n1 "$WORK/trace/args-1" | grep -q "writable_roots=\[\"$run/proj/.git\"\]\|writable_roots=\[\"$(cd "$run/proj" && pwd -P)/.git\"\]"
head -n1 "$WORK/trace/args-1" | grep -q -- '-m gpt-6-luna'
for i in 0 1 2; do sed -n 2p "$WORK/trace/args-$i" | grep -qx yes; done
jq -e '.earlier_sessions[0].end.thread == "thread-1"' "$run/result.json" >/dev/null
# Session-1 scope and the leak check are recorded.
jq -e '.earlier_sessions[0].changed_server == true and .earlier_sessions[0].changed_client == false' "$run/result.json" >/dev/null
jq -e '.read_session_records == true' "$run/result.json" >/dev/null
test ! -e "$run/home/.codex/auth.json"
printf 'PASS: ask mode resumes session 1 with the end prompt before session 2, and records it\n'

# closed: no end prompt; session 2 still sees what session 1 left.
mkdir -p "$WORK/out-closed"; reset_trace; touch "$WORK/trace/no-peek"
BENCH_END_MODE=closed bench "$WORK/out-closed" 10+11 native 1 2> "$WORK/closed.log" || { tail -20 "$WORK/closed.log"; exit 1; }
run="$WORK/out-closed/runs/t10+11-native-r1"
[ "$(find "$WORK/trace" -name 'call-*' | wc -l | tr -d ' ')" = 2 ]
if grep -q resume "$WORK/trace/call-1"; then echo 'FAIL: closed mode resumed session 1'; exit 1; fi
jq -e '.end_mode == "closed" and .earlier_sessions[0].end.sent == false and .valid == true' "$run/result.json" >/dev/null
jq -e '.read_session_records == false and .earlier_sessions[0].changed_client == false' "$run/result.json" >/dev/null
bash "$BENCH" report "$WORK/out-closed" > /dev/null 2> "$WORK/report-closed.log" || { cat "$WORK/report-closed.log"; exit 1; }
awk -F'\t' 'NR == 1 { for (i = 1; i <= NF; i++) col[$i] = i }
    NR == 2 { ok = ($col["read_session_records"] == "false" && $col["s1_changed_client"] == "false" && $col["s1_changed_server"] == "true") }
    END { exit !ok }' "$WORK/out-closed/scores.tsv"
test -f "$run/proj/server/rpe.txt"
rm "$WORK/trace/no-peek"
printf 'PASS: closed mode sends no end prompt and carries session 1 work forward; false flags report as false\n'

# A failed end turn invalidates the pair instead of scoring session 2 from a half-closed base.
mkdir -p "$WORK/out-fail"; reset_trace
touch "$WORK/trace/fail-resume"
if BENCH_END_MODE=ask bench "$WORK/out-fail" 10+11 native 1 2> "$WORK/fail.log"; then
    echo 'FAIL: a failed end turn was accepted'; exit 1
fi
grep -q 'end-of-session turn for session 1' "$WORK/fail.log"
rm "$WORK/trace/fail-resume"
# An end turn that answers in another thread, or reports no usage, also stops the pair.
for flag in wrong-thread no-usage; do
    mkdir -p "$WORK/out-$flag"; reset_trace; touch "$WORK/trace/$flag"
    if BENCH_END_MODE=ask bench "$WORK/out-$flag" 10+11 native 1 2> "$WORK/$flag.log"; then
        echo "FAIL: end turn with $flag accepted"; exit 1
    fi
    grep -q 'end-of-session turn for session 1' "$WORK/$flag.log"
    [ "$(find "$WORK/trace" -name 'call-*' | wc -l | tr -d ' ')" = 2 ]
    rm "$WORK/trace/$flag"
done
[ "$(find "$WORK/trace" -name 'call-*' | wc -l | tr -d ' ')" = 2 ]
printf 'PASS: a failed, wrong-thread or usage-less end turn stops the pair before session 2\n'

# The leak check: each kind of earlier-session record is seen; the SOP arm's own project
# .codex folder and ordinary repo paths are not.
detector=$(awk '/^read_session_records\(\) \{/{p=1} p{print} p&&/^\}/{exit}' "$BENCH")
[ -n "$detector" ] || { echo 'FAIL: read_session_records not found'; exit 1; }
check_leak() { # expected command
    jq -nc --arg c "$2" '{type:"item.completed",item:{type:"command_execution",command:$c}}' > "$WORK/leak.jsonl"
    [ "$(bash -c "$detector"$'\n''read_session_records "$1"' _ "$WORK/leak.jsonl")" = "$1" ] || { echo "FAIL: leak check on '$2' is not $1"; exit 1; }
}
for c in 'ls ~/.codex' 'cat $HOME/.codex/config.toml' 'cat ${HOME}/.codex/x' 'cat /tmp/r/home/.codex/sessions/2026/x' \
         'cat ../session-1/prompt.txt' 'ls ../session-2' 'cat /tmp/out/runs/r/session-1/events.jsonl' 'echo $CODEX_HOME'; do check_leak true "$c"; done
for c in 'cat .codex/hooks.json' 'ls -a .codex' 'cat docs/agent-memory/session-notes.md' 'ls docs/session-3' 'grep -r rpe server/src'; do check_leak false "$c"; done
printf 'PASS: leak check sees earlier-session records and ignores the project .codex and repo paths\n'

# Older output directories count as closed; quotes in the output path are refused.
mkdir -p "$WORK/out-old/runs/t5-native-r1"
if PATH="$WORK/bin:$PATH" CODEX_HOME="$WORK/codex-home" BENCH_TEMPLATE="$WORK/template" BENCH_END_MODE=ask \
    bash "$BENCH" run "$WORK/out-old" --tasks 10+11 2> "$WORK/old.log"; then echo 'FAIL: ask run into an older closed directory'; exit 1; fi
grep -q 'was run with end mode closed' "$WORK/old.log"
mkdir -p "$WORK/out\"quote"
if BENCH_END_MODE=ask bench "$WORK/out\"quote" 10+11 native 1 2> "$WORK/quote.log"; then echo 'FAIL: quoted output path accepted'; exit 1; fi
grep -q 'must not contain quotes' "$WORK/quote.log"
# Bad end mode and mixed end modes in one output directory are refused.
if BENCH_END_MODE=sometimes bash "$BENCH" report "$WORK/out-ask" 2> "$WORK/bad.log"; then echo 'FAIL: bad end mode accepted'; exit 1; fi
grep -q 'BENCH_END_MODE must be closed or ask' "$WORK/bad.log"
mkdir -p "$WORK/out-mixed/runs"; echo ask > "$WORK/out-mixed/end-mode"
if PATH="$WORK/bin:$PATH" CODEX_HOME="$WORK/codex-home" BENCH_TEMPLATE="$WORK/template" BENCH_END_MODE=closed \
    bash "$BENCH" run "$WORK/out-mixed" --tasks 10+11 2> "$WORK/mixed.log"; then echo 'FAIL: mixed end modes accepted'; exit 1; fi
grep -q 'was run with end mode ask' "$WORK/mixed.log"
printf 'PASS: invalid and mixed end modes are refused\n'

# The report carries the end mode and counts the end turn in session-1 time and tokens.
bash "$BENCH" report "$WORK/out-ask" > /dev/null 2> "$WORK/report.log" || { cat "$WORK/report.log"; exit 1; }
awk -F'\t' 'NR == 1 { for (i = 1; i <= NF; i++) col[$i] = i }
    NR == 2 { ok = ($col["end_mode"] == "ask" && $col["earlier_output_tokens"] == 10 && $col["read_session_records"] == "true") }
    END { exit !ok }' "$WORK/out-ask/scores.tsv"
printf 'PASS: report includes the end mode and the end turn in session-1 tokens\n'
