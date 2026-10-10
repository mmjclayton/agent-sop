#!/usr/bin/env bash
# Codex A/B harness for P116: native Codex vs current Agent SOP, per
# docs/benchmark/evaluation-protocol.md. Each run is a fresh `codex exec`
# process with its own HOME and CODEX_HOME, so neither arm sees the operator's
# global instructions, memories, skills or hooks. Sandbox network access is on so
# the server suite can reach the local test database (server/src/__tests__/setup.js);
# runs are sequential because that database is shared.
#
# Usage:
#   codex-bench.sh template <dir>                     build the pinned target with dependencies
#   codex-bench.sh run <out> [-k N] [--tasks "5 7 8"] run every task x arm x repetition, order shuffled
#   codex-bench.sh judge <out>                        blind rubric scoring of every finished run
#   codex-bench.sh report <out>                       scores.tsv and a per-arm summary
#
# Environment:
#   HST_REPO (~/Projects/hst-tracker)  BENCH_BASE_COMMIT (814b3b5)  BENCH_TEMPLATE (required for run)
#   BENCH_MODEL (gpt-6-luna)  BENCH_EFFORT (medium)  BENCH_JUDGE_EFFORT (high)  BENCH_TIMEOUT (1800 s)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd -P)"
SOP_ROOT="${AGENT_SOP_ROOT:-$(cd "$HERE/../.." && pwd -P)}"
TASK_DIR="$SOP_ROOT/docs/benchmark/tasks"
HST_REPO="${HST_REPO:-$HOME/Projects/hst-tracker}"
# 814b3b5 files B1, P57 and P62 (tasks 05, 07, 08) before any is built; 76b3b77, the
# run-multi-round.sh pin, already ships all three.
BASE_COMMIT="${BENCH_BASE_COMMIT:-814b3b5}"
MODEL="${BENCH_MODEL:-gpt-6-luna}"
EFFORT="${BENCH_EFFORT:-medium}"
JUDGE_EFFORT="${BENCH_JUDGE_EFFORT:-high}"
TIMEOUT="${BENCH_TIMEOUT:-1800}"
AUTH="${CODEX_HOME:-$HOME/.codex}/auth.json"
ARMS=(native sop)

die() { echo "codex-bench: $*" >&2; exit 1; }
log() { echo "[codex-bench $(date +%H:%M:%S)] $*" >&2; }
task_file() { ls "$TASK_DIR"/task-0"$1"-*.md 2>/dev/null | head -1; }
# The verbatim prompt is the quoted block under "## Prompt".
task_prompt() { awk '/^## Prompt/{p=1;next} /^## /{p=0} p && /^>/{sub(/^> ?/,""); print}' "$(task_file "$1")"; }
task_criteria() { awk '/^## Acceptance Criteria/{p=1;next} /^## /{p=0} p' "$(task_file "$1")"; }
with_timeout() { local t=$1; shift; perl -e 'alarm shift; exec @ARGV or die "exec: $!"' "$t" "$@"; }

isolated_home() {
    local home=$1
    mkdir -p "$home/.codex"
    cp "$AUTH" "$home/.codex/auth.json"; chmod 600 "$home/.codex/auth.json"
    printf '[user]\n\tname = bench\n\temail = bench@example.invalid\n' > "$home/.gitconfig"
    # Codex runs a login shell; without this the isolated HOME falls back to /etc/paths
    # and finds an older node first. Both arms get the harness PATH.
    printf 'export PATH=%q\n' "$PATH" > "$home/.zprofile"
}

build_template() {
    local dir=$1
    [ ! -e "$dir" ] || die "$dir exists"
    mkdir -p "$dir"
    git -C "$HST_REPO" archive "$BASE_COMMIT" | tar -x -C "$dir"
    (cd "$dir/server" && npm ci --no-audit --no-fund --loglevel=error && npx prisma generate >/dev/null)
    (cd "$dir/client" && npm ci --no-audit --no-fund --loglevel=error)
    # Baseline pass counts on the untouched target, quoted to the judge.
    local s c
    s=$(cd "$dir/server" && npm test 2>&1 | perl -ne 'print $1 if /^\s*Tests:\s+(\d+) passed/') || true
    c=$(cd "$dir/client" && npm test 2>&1 | perl -ne 'print $1 if /^\s*Tests\s+(\d+) passed/') || true
    [ -n "$s" ] && [ -n "$c" ] || die "baseline tests did not pass on $BASE_COMMIT"
    jq -n --arg base "$BASE_COMMIT" --argjson server "$s" --argjson client "$c" '{base:$base,server:$server,client:$client}' > "$dir/.bench-baseline.json"
    log "template ready at $dir (base $BASE_COMMIT, baseline $s server / $c client)"
}

prepare_arm() {
    local run=$1 arm=$2 proj=$1/proj
    cp -c -R "$BENCH_TEMPLATE" "$proj" 2>/dev/null || cp -R "$BENCH_TEMPLATE" "$proj"
    git -C "$proj" init -q
    HOME="$run/home" git -C "$proj" add -A
    HOME="$run/home" git -C "$proj" commit -qm "base $BASE_COMMIT"
    if [ "$arm" = native ]; then
        # Historical baseline stub, as AGENTS.md; SOP knowledge removed.
        rm -rf "$proj/CLAUDE.md" "$proj/docs/agent-memory.md" "$proj/docs/sop" "$proj/.claude"
        cat > "$proj/AGENTS.md" <<'STUB'
# LOADOUT

- Frontend: React 19, Vite — client/
- Backend: Express 5, Prisma ORM, PostgreSQL 17 — server/
- Tests: npm test (Jest server, Vitest client)
- Schema: server/prisma/schema.prisma
STUB
    else
        AGENT_SOP_USER_HOME="$run/home" bash "$SOP_ROOT/setup.sh" "$proj" --runtime codex --code --force > "$run/setup.log" 2>&1 \
            || die "setup.sh failed for $run (see setup.log)"
    fi
    HOME="$run/home" git -C "$proj" add -A
    HOME="$run/home" git -C "$proj" commit -qm "arm $arm" --allow-empty
    git -C "$proj" rev-parse HEAD > "$run/arm-commit"
}

count_tests() { # prints "passed failed" from a jest or vitest log
    perl -ne 'if(/^\s*Tests:?\s+(\d.*)/){$l=$1; ($p)=$l=~/(\d+) passed/; ($f)=$l=~/(\d+) failed/; print (($p//0)." ".($f//0)."\n"); exit}' "$1"
}

run_tests() {
    local run=$1 proj=$1/proj side
    for side in server client; do
        (cd "$proj/$side" && HOME="$run/home" with_timeout 600 npm test) > "$run/test-$side.log" 2>&1 && echo 0 > "$run/test-$side.exit" || echo $? > "$run/test-$side.exit"
    done
}

one_run() {
    local out=$1 task=$2 arm=$3 rep=$4 run prompt start status
    run="$out/runs/t$task-$arm-r$rep"
    [ ! -f "$run/result.json" ] || { log "done already: $run"; return 0; }
    rm -rf "$run"; mkdir -p "$run"
    isolated_home "$run/home"
    prepare_arm "$run" "$arm"
    prompt=$(task_prompt "$task"); [ -n "$prompt" ] || die "no prompt for task $task"
    cp "$BENCH_TEMPLATE/.bench-baseline.json" "$run/baseline.json" || die "template has no .bench-baseline.json"
    printf '%s\n' "$prompt" > "$run/prompt.txt"
    local extra=(); [ "$arm" = sop ] && extra=(--dangerously-bypass-hook-trust)
    log "start t$task $arm r$rep"
    start=$(date +%s); status=0
    HOME="$run/home" CODEX_HOME="$run/home/.codex" with_timeout "$TIMEOUT" \
        codex exec -C "$run/proj" -s workspace-write --add-dir "$run/proj/.git" -m "$MODEL" \
        -c model_reasoning_effort="\"$EFFORT\"" -c approval_policy='"never"' \
        -c sandbox_workspace_write.network_access=true \
        ${extra[@]+"${extra[@]}"} --json -o "$run/last-message.md" - \
        < "$run/prompt.txt" > "$run/events.jsonl" 2> "$run/stderr.log" || status=$?
    local wall=$(( $(date +%s) - start ))
    HOME="$run/home" git -C "$run/proj" add -A
    HOME="$run/home" git -C "$run/proj" diff --cached --stat "$(cat "$run/arm-commit")" > "$run/diffstat.txt" || true
    run_tests "$run"
    finish_run "$run" "$task" "$arm" "$rep" "$status" "$wall"
    log "end   t$task $arm r$rep exit=$status wall=${wall}s"
}

finish_run() {
    local run=$1 task=$2 arm=$3 rep=$4 status=$5 wall=$6 proj=$1/proj base
    base=$(cat "$run/arm-commit")
    read -r s_pass s_fail <<< "$(count_tests "$run/test-server.log")"
    read -r c_pass c_fail <<< "$(count_tests "$run/test-client.log")"
    local changed; changed=$(git -C "$proj" diff --cached --name-only "$base" | jq -R . | jq -s .)
    jq -n --arg task "$task" --arg arm "$arm" --argjson rep "$rep" --arg model "$MODEL" --arg effort "$EFFORT" \
        --argjson exit "$status" --argjson wall "$wall" --argjson changed "$changed" \
        --argjson s_exit "$(cat "$run/test-server.exit")" --argjson c_exit "$(cat "$run/test-client.exit")" \
        --argjson s_pass "${s_pass:-0}" --argjson s_fail "${s_fail:-0}" --argjson c_pass "${c_pass:-0}" --argjson c_fail "${c_fail:-0}" \
        --argjson usage "$(jq -s '[.[] | select(.type == "turn.completed") | .usage] | if length == 0 then null else . end' "$run/events.jsonl" 2>/dev/null || echo null)" \
        --arg codex "$(codex --version 2>/dev/null)" '
        {task:$task, arm:$arm, rep:$rep, model:$model, effort:$effort, codex:$codex, exit_code:$exit,
         timed_out:($exit == 142), wall_seconds:$wall, files_changed:$changed,
         tests:{server:{exit:$s_exit, passed:$s_pass, failed:$s_fail}, client:{exit:$c_exit, passed:$c_pass, failed:$c_fail}},
         usage:$usage}' > "$run/result.json"
}

# Paths that would reveal the arm to a judge (SOP records and installed assets).
JUDGE_EXCLUDES=(':!docs' ':!Backlog.md' ':!AGENTS.md' ':!CLAUDE.md' ':!scripts' ':!.claude' ':!.agents' ':!.codex')

judge_run() {
    local run=$1 label=$2 task proj=$1/proj base jh
    task=$(jq -r .task "$run/result.json")
    [ ! -f "$run/judge.json" ] || return 0
    base=$(cat "$run/arm-commit")
    jh="$run/judge-home"; rm -rf "$jh"; isolated_home "$jh"
    local packet="$run/judge-packet.md"
    {
        echo "You are scoring one anonymous attempt ($label) at a coding task in a React/Express app."
        echo "Score only against the acceptance criteria. Do not reward or penalise process documents."
        echo; echo "## Task prompt given to the agent"; cat "$run/prompt.txt"
        echo; echo "## Acceptance criteria"; task_criteria "$task"
        echo; echo "## Test results (run by the harness after the attempt; before it, $(jq -r '"\(.server) server / \(.client) client"' "$run/baseline.json") tests passed)"
        jq -r '.tests | "server: exit \(.server.exit), \(.server.passed) passed, \(.server.failed) failed\nclient: exit \(.client.exit), \(.client.passed) passed, \(.client.failed) failed"' "$run/result.json"
        echo; echo "## Diff of the attempt (process and documentation files omitted)"
        echo '```diff'
        git -C "$proj" diff --cached "$base" -- . "${JUDGE_EXCLUDES[@]}" | head -c 150000
        echo '```'
        echo; echo "Return JSON: for each numbered criterion, met = 1, 0.5 or 0 with a one-line reason; then overall = mean of met values."
    } > "$packet"
    cat > "$run/judge-schema.json" <<'JSON'
{"type":"object","additionalProperties":false,"required":["criteria","overall"],
 "properties":{"criteria":{"type":"array","items":{"type":"object","additionalProperties":false,
   "required":["number","met","reason"],"properties":{"number":{"type":"integer"},"met":{"type":"number"},"reason":{"type":"string"}}}},
  "overall":{"type":"number"}}}
JSON
    local jdir; jdir=$(mktemp -d)
    HOME="$jh" CODEX_HOME="$jh/.codex" with_timeout 900 codex exec -C "$jdir" --skip-git-repo-check -s read-only \
        -m "$MODEL" -c model_reasoning_effort="\"$JUDGE_EFFORT\"" -c approval_policy='"never"' \
        --output-schema "$run/judge-schema.json" -o "$run/judge.json" - < "$packet" > "$run/judge-events.log" 2>&1 \
        || { rm -rf "$jdir"; rm -f "$run/judge.json"; log "judge failed for $run"; return 1; }
    rm -rf "$jdir" "$jh"
    jq -e '.overall | type == "number"' "$run/judge.json" >/dev/null || { rm -f "$run/judge.json"; log "judge output invalid for $run"; return 1; }
}

cmd="${1:-}"; shift || true
case "$cmd" in
    template) build_template "${1:?template dir}" ;;
    run)
        out="${1:?out dir}"; shift
        k=1; tasks="5 7 8"
        while [ $# -gt 0 ]; do case "$1" in -k) k=$2; shift 2 ;; --tasks) tasks=$2; shift 2 ;; *) die "unknown option $1" ;; esac; done
        [ -n "${BENCH_TEMPLATE:-}" ] && [ -d "$BENCH_TEMPLATE/client/node_modules" ] || die "set BENCH_TEMPLATE to a built template"
        [ -f "$AUTH" ] || die "no Codex login at $AUTH"
        mkdir -p "$out/runs"
        plan=$(for t in $tasks; do for r in $(seq 1 "$k"); do for a in "${ARMS[@]}"; do echo "$t $a $r"; done; done; done | perl -MList::Util=shuffle -e 'print shuffle <STDIN>')
        printf '%s\n' "$plan" > "$out/plan.txt"
        while read -r t a r; do one_run "$out" "$t" "$a" "$r" || log "run failed: t$t $a r$r"; done <<< "$plan"
        ;;
    judge)
        out="${1:?out dir}"; n=0
        for run in "$out"/runs/*/; do
            run=${run%/}; [ -f "$run/result.json" ] || continue
            n=$((n + 1)); judge_run "$run" "attempt-$(printf '%s' "$run" | shasum | cut -c1-8)" || true
        done
        ;;
    report)
        out="${1:?out dir}"
        { printf 'task\tarm\trep\tjudge\tserver_fail\tclient_fail\twall_s\tinput_tokens\tcached_input\toutput_tokens\treasoning\n'
          for r in "$out"/runs/*/result.json; do
              d=$(dirname "$r")
              jq -r --argjson j "$(jq '.overall' "$d/judge.json" 2>/dev/null || echo null)" '
                [.task, .arm, .rep, ($j // "NA"), .tests.server.failed, .tests.client.failed, .wall_seconds,
                 (.usage // [] | map(.input_tokens // 0) | add // "NA"), (.usage // [] | map(.cached_input_tokens // 0) | add // "NA"),
                 (.usage // [] | map(.output_tokens // 0) | add // "NA"), (.usage // [] | map(.reasoning_output_tokens // 0) | add // "NA")] | @tsv' "$r"
          done; } > "$out/scores.tsv"
        column -t -s $'\t' "$out/scores.tsv"
        ;;
    *) sed -n '2,16p' "$0"; exit 2 ;;
esac
