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
for c in 'cat ~/.claude/projects/-tmp-proj/abc.jsonl' 'ls ~/.claude/projects' 'cat /tmp/r/home/.claude/projects/x/s.jsonl' 'ls $CLAUDE_CONFIG_DIR/projects' 'cat ${CLAUDE_CONFIG_DIR}/projects/x/s.jsonl'; do check_leak true "$c"; done
for c in 'cat .codex/hooks.json' 'ls -a .codex' 'cat docs/agent-memory/session-notes.md' 'ls docs/session-3' 'grep -r rpe server/src' \
         'cat .claude/settings.json' 'cat ~/.claude/projects/-tmp-proj/memory/MEMORY.md' 'cat $CLAUDE_CONFIG_DIR/projects/x/memory/MEMORY.md' 'ls ~/projects' 'ls $HOME/projects'; do check_leak false "$c"; done
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

# --- Claude Code runtime (P122) -------------------------------------------------------
# Needs macOS sandbox-exec; elsewhere (Linux CI) these cases are skipped, not passed.
if ! command -v sandbox-exec >/dev/null; then
    printf 'SKIP: Claude runtime fixtures need sandbox-exec (macOS)\n'; exit 0
fi
mkdir -p "$WORK/cbin" "$WORK/tok"
printf 'fake-token-%s\n' "$$" > "$WORK/tok/claude-token"; chmod 600 "$WORK/tok/claude-token"
TOKEN=$(tr -d '[:space:]' < "$WORK/tok/claude-token")
cat > "$WORK/cbin/claude" <<'FAKE'
#!/usr/bin/env bash
# Fake Claude Code under the harness sandbox: records its arguments and environment in
# $TMPDIR (inside the sandboxed root), probes the sandbox, edits the project, and prints
# stream-json (or judge JSON). FAKE_MODE (set by a per-mode copy) switches failure modes.
set -uo pipefail
[ "${1:-}" = --version ] && { echo '2.0.0 (Claude Code fake)'; exit 0; }
n=$(find "$TMPDIR" -maxdepth 1 -name 'call-*.args' 2>/dev/null | wc -l | tr -d ' ')
c="$TMPDIR/call-$n"; printf '%s\0' "$@" > "$c.args"
{ echo "token=$([ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ] && echo set || echo unset)"
  echo "home=$HOME"; echo "config=${CLAUDE_CONFIG_DIR:-}"; echo "codexhome=${CODEX_HOME:-}"
  # Sandbox probes, relative to the run home: <work>/<out>/runs/<run>/home.
  if (echo x > "$HOME/../../../outside-probe") 2>/dev/null; then echo outside_write=allowed; else echo outside_write=denied; fi
  if cat "$HOME/../../../../tok/claude-token" >/dev/null 2>&1; then echo token_read=allowed; else echo token_read=denied; fi
  if cat "$HOME/../session-1/prompt.txt" >/dev/null 2>&1; then echo earlier_prompt_read=allowed; else echo earlier_prompt_read=denied; fi
  if (echo x > "$HOME/../baseline.json") 2>/dev/null; then echo harness_write=allowed; else echo harness_write=denied; fi
  if ls "/Users/$(id -un)" >/dev/null 2>&1; then echo operator_home_read=allowed; else echo operator_home_read=denied; fi
  if security list-keychains >/dev/null 2>&1; then echo keychain=reachable; else echo keychain=blocked; fi
  if node -e 'require("fs").realpathSync(".")' >/dev/null 2>&1; then echo node=ok; else echo node=broken; fi
} > "$c.env"
resume=''; schema=''; prev=''
for a in "$@"; do [ "$prev" = --resume ] && resume=$a; [ "$prev" = --json-schema ] && schema=$a; prev=$a; done
cat > /dev/null
if [ -n "$schema" ]; then
    printf '{"type":"result","subtype":"success","is_error":false,"result":"done","total_cost_usd":0.02,"structured_output":{"criteria":[%s]}}\n' \
        "$(for i in 1 2 3 4 5 6 7 8; do printf '{"number":%d,"met":1,"reason":"ok"}' "$i"; [ "$i" = 8 ] || printf ,; done)"
    exit 0
fi
mode() { [ "${FAKE_MODE:-}" = "$1" ]; }
sid=${resume:-sess-1}; mode newid && [ -n "$resume" ] && sid=other-session
case "$n" in 0) file=server/rpe.txt ;; *) file=client/rpe.txt ;; esac
[ -n "$resume" ] && file=notes.md
echo x > "$file"
printf '{"type":"system","subtype":"init","session_id":"%s","model":"claude-fake-1"}\n' "$sid"
text='Working.'; mode leak && text="token is $(printf '%s' "${CLAUDE_CODE_OAUTH_TOKEN}" | base64)"
printf '{"type":"assistant","message":{"content":[{"type":"text","text":"%s"},{"type":"tool_use","name":"Bash","input":{"command":"ls server"}},{"type":"tool_use","name":"Write","input":{"file_path":"%s/%s"}},"odd",{"type":"tool_use"}]}}\n' "$text" "$PWD" "$file"
mode noresult && exit 0
mode slow && sleep 2
mode limit && { printf '{"type":"result","subtype":"error_during_execution","is_error":true,"result":"usage limit","total_cost_usd":0}\n'; exit 0; }
printf '{"type":"result","subtype":"success","is_error":false,"result":"Done.","total_cost_usd":0.01,"usage":{"input_tokens":3,"cache_creation_input_tokens":2,"cache_read_input_tokens":5,"output_tokens":7}}\n'
FAKE
chmod +x "$WORK/cbin/claude"
# A copy of the fake per failure mode, with the mode baked in (the harness scrubs the env).
for m in limit noresult newid leak slow; do
    mkdir -p "$WORK/cbin-$m"
    sed "2i\\
FAKE_MODE=$m" "$WORK/cbin/claude" > "$WORK/cbin-$m/claude"; chmod +x "$WORK/cbin-$m/claude"
done
CBIN="$WORK/cbin"
cbench() {
    PATH="$CBIN:$PATH" BENCH_RUNTIME=claude BENCH_CLAUDE_TOKEN_FILE="$WORK/tok/claude-token" CODEX_HOME="$WORK/codex-home" \
        BENCH_TEMPLATE="$WORK/template" BENCH_ARMS="native context" bash "$BENCH" "$@"
}
has_pair() { # args-file flag value: flag immediately followed by value
    tr '\0' '\n' < "$1" | awk -v f="$2" -v v="$3" 'prev == f && $0 == v { ok = 1 } { prev = $0 } END { exit !ok }'
}
has_flag() { tr '\0' '\n' < "$1" | grep -qx -- "$2"; }

# Positive controls: outside the sandbox each probe below succeeds, so "denied" inside it
# means the sandbox refused it.
ls "/Users/$(id -un)" >/dev/null 2>&1 || { echo 'FAIL: control: operator home not listable outside the sandbox'; exit 1; }
security list-keychains >/dev/null 2>&1 || { echo 'FAIL: control: keychain unreachable outside the sandbox'; exit 1; }
cat "$WORK/tok/claude-token" >/dev/null || { echo 'FAIL: control: token unreadable outside the sandbox'; exit 1; }
mkdir -p "$WORK/out-claude"
BENCH_END_MODE=ask cbench one "$WORK/out-claude" 10+11 native 1 2> "$WORK/claude.log" || { tail -20 "$WORK/claude.log"; exit 1; }
run="$WORK/out-claude/runs/t10+11-native-r1"
test -f "$run/proj/CLAUDE.md"; test ! -e "$run/proj/AGENTS.md"; grep -q 'Tests: npm test' "$run/proj/CLAUDE.md"
[ "$(find "$run/tmp" -maxdepth 1 -name 'call-*.args' | wc -l | tr -d ' ')" = 3 ]
for i in 0 1 2; do
    a="$run/tmp/call-$i.args"; e="$run/tmp/call-$i.env"
    has_flag "$a" -p; has_flag "$a" --verbose; has_flag "$a" --dangerously-skip-permissions
    has_pair "$a" --output-format stream-json; has_pair "$a" --setting-sources user,project; has_pair "$a" --effort medium
    grep -qx token=set "$e"; grep -qx "home=$(cd "$run" && pwd -P)/home" "$e"; grep -qx "config=$(cd "$run" && pwd -P)/home/.claude" "$e"
    grep -qx outside_write=denied "$e"; grep -qx token_read=denied "$e"; grep -qx earlier_prompt_read=denied "$e"
    grep -qx harness_write=denied "$e"; grep -qx operator_home_read=denied "$e"; grep -qx keychain=blocked "$e"
    grep -qx node=ok "$e"   # node starts and resolves its cwd under the profile
done
test -f "$run/session-1/prompt.txt"   # the earlier-prompt probe had a real file to refuse
has_pair "$run/tmp/call-1.args" --resume sess-1
if has_flag "$run/tmp/call-0.args" --resume || has_flag "$run/tmp/call-2.args" --resume; then echo 'FAIL: wrong session resumed'; exit 1; fi
test ! -e "$WORK/out-claude/outside-probe"
jq -e '.runtime == "claude" and .model_resolved == "claude-fake-1" and .valid == true and .earlier_sessions[0].end.thread == "sess-1"
       and .earlier_sessions[0].changed_server == true and .earlier_sessions[0].changed_client == false
       and .earlier_sessions[0].native_memory_files == 0 and .first_message == "Working." and (.locate_steps | type) == "number"' "$run/result.json" >/dev/null
jq -e 'select(.type == "turn.completed") | .usage == {input_tokens:10, cached_input_tokens:5, output_tokens:7, cost_usd:0.01}' "$run/events.jsonl" >/dev/null
if grep -rqF -- "$TOKEN" "$WORK/out-claude"; then echo 'FAIL: token written under the run'; exit 1; fi
printf 'PASS: Claude turns run sandboxed (writes only to their own folders, no reads of the operator home, token or earlier prompts, no keychain), with exact flags, resume by session id and converted events\n'

cbench judge "$WORK/out-claude" 2> "$WORK/claude-judge.log" || { cat "$WORK/claude-judge.log"; exit 1; }
jq -e '.overall == 1' "$run/judge.json" >/dev/null
cbench report "$WORK/out-claude" > /dev/null 2> "$WORK/claude-report.log" || { cat "$WORK/claude-report.log"; exit 1; }
awk -F'\t' 'NR == 1 { for (i = 1; i <= NF; i++) col[$i] = i }
    NR == 2 { ok = ($col["cost_usd"] == 0.03 && $col["end_mode"] == "ask") }
    END { exit !ok }' "$WORK/out-claude/scores.tsv"
printf 'PASS: Claude judge returns structured output and the report sums cost over both sessions and the end turn\n'

# Failed turns: an error result with exit 0, no result event, a resumed turn in another
# session, and the token appearing in the output (redacted, run invalid).
for m in limit noresult newid leak; do
    mkdir -p "$WORK/out-c$m"; CBIN="$WORK/cbin-$m"
    if BENCH_END_MODE=ask cbench one "$WORK/out-c$m" 10+11 native 1 2> "$WORK/c$m.log"; then echo "FAIL: Claude turn with $m accepted"; exit 1; fi
done
CBIN="$WORK/cbin"
grep -q 'claude turn failed' "$WORK/climit.log"; grep -q 'claude turn failed' "$WORK/cnoresult.log"
grep -q 'end-of-session turn for session 1' "$WORK/cnewid.log"
grep -q 'the Claude token appeared' "$WORK/cleak.log"
if grep -rqF -- "$TOKEN" "$WORK/out-cleak"; then echo 'FAIL: leaked token not redacted'; exit 1; fi
grep -rqF '[REDACTED]' "$WORK/out-cleak"
printf 'PASS: error results, missing results, a changed session id and a leaked token each fail the pair; the token is redacted\n'

printf ' \n' > "$WORK/tok/blank"
if PATH="$WORK/cbin:$PATH" BENCH_RUNTIME=claude BENCH_CLAUDE_TOKEN_FILE="$WORK/tok/blank" BENCH_TEMPLATE="$WORK/template" \
    bash "$BENCH" run "$WORK/out-blank" --tasks 10+11 2> "$WORK/blank.log"; then echo 'FAIL: blank token accepted'; exit 1; fi
grep -q 'is empty' "$WORK/blank.log"
if PATH="$WORK/cbin:$PATH" BENCH_RUNTIME=claude BENCH_CLAUDE_TOKEN_FILE="$WORK/tok/missing" BENCH_TEMPLATE="$WORK/template" \
    bash "$BENCH" run "$WORK/out-notoken" --tasks 10+11 2> "$WORK/notoken.log"; then echo 'FAIL: run without a token'; exit 1; fi
grep -q 'no Claude Code token' "$WORK/notoken.log"
printf 'PASS: a blank or missing token file is refused\n'

# The token never appears in any process's arguments: sample ps from outside the sandbox
# while slow fake turns run. Positive control: the sampler must see sandbox-exec.
mkdir -p "$WORK/out-cps"; CBIN="$WORK/cbin-slow"
( for _ in $(seq 1 60); do ps -ax -ww -o args= >> "$WORK/ps-samples" 2>/dev/null; sleep 0.1; done ) &
sampler=$!
BENCH_END_MODE=closed cbench one "$WORK/out-cps" 10+11 native 1 2> "$WORK/cps.log" || { tail -5 "$WORK/cps.log"; exit 1; }
wait "$sampler"; CBIN="$WORK/cbin"
grep -q 'sandbox-exec -f' "$WORK/ps-samples"
if grep -qF -- "$TOKEN" "$WORK/ps-samples"; then echo 'FAIL: token seen in process arguments'; exit 1; fi
printf 'PASS: the token is never in process arguments (sampled outside the sandbox, with sandbox-exec seen)\n'

# Cost is NA unless every turn's cost is known.
na_case() { # name jq-edit
    mkdir -p "$WORK/out-na-$1/runs"; cp -R "$WORK/out-claude/runs/t10+11-native-r1" "$WORK/out-na-$1/runs/"
    jq "$2" "$WORK/out-claude/runs/t10+11-native-r1/result.json" > "$WORK/out-na-$1/runs/t10+11-native-r1/result.json"
    cbench report "$WORK/out-na-$1" > /dev/null 2>&1
    awk -F'\t' 'NR == 1 { for (i = 1; i <= NF; i++) col[$i] = i } NR == 2 { ok = ($col["cost_usd"] == "NA") } END { exit !ok }' "$WORK/out-na-$1/scores.tsv" \
        || { echo "FAIL: cost not NA for $1"; exit 1; }
}
na_case final-null '.usage = null'
na_case earlier-null '.earlier_sessions[0].usage = null'
na_case end-null '.earlier_sessions[0].end.usage = null'
na_case cost-missing '.usage[0].cost_usd = null'
printf 'PASS: cost is NA when any turn lacks usage or cost\n'
