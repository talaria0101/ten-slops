#!/bin/sh
# EXPERIMENT 20 - BUILD ALL TEN FORMALISATIONS FROM SOURCE AT THE PINNED TOOLCHAIN.
#
# Question answered: does `lake build All` for openai/ten-proofs at commit
# 94bc0feb6a9f exit 0 with Lean v4.32.0 + mathlib v4.32.0, on a machine that
# never saw these .olean files before? This is the "does it work" row.
#
# Inputs pinned:
#   ten-proofs commit 94bc0feb6a9ff12c7d31d6de640a725c9d43d2b6
#   lean-toolchain     leanprover/lean4:v4.32.0 (from the tree itself)
#   mathlib            v4.32.0 (pinned by lakefile.toml/lake-manifest.json)
#
# Costs recorded: wall time per module (this also yields the per-proof cost
# table) plus the peak resident set of the builder tree, sampled every 2s by
# an OUTSIDE observer.
#
# Revisions (same question throughout, so NOT renumbered):
#   v1 died: no GNU time on this host (rc=127, build never ran).
#   v2 died: default parallelism (16 elaborators) peaked ~24.7 GB on a 30 GB
#     host and the run vanished; LEAN_NUM_CAPABILITIES=4 (v3) did NOT cap
#     Lake 5.0's job count (8 elaborators, ~32 GB sampled peak).
#   v4 (this): build the eleven libs SEQUENTIALLY, one `lake build <mod>` at
#     a time, which bounds concurrent elaborators to ~1 and doubles as the
#     per-module cost measurement. `lake build All` runs last, green only if
#     every module it imports is already built.
#   v5 (this): `lake exe cache get` is now UNCONDITIONAL. Dead end found the
#     hard way: `lake clean` also wipes the mathlib package's build dir, so
#     after a clean the "cache present" source-dir check passed and Lake
#     started rebuilding mathlib from source. cache get is a no-op check of
#     a couple of minutes when everything is cached, so paying it every run
#     is the robust shape.
#
# Exit: 0 every module built and `lake build All` exited 0,
#       1 at least one module failed (per-module rows still recorded),
#       2 could not run.

set -u
cd "$(dirname "$0")/.."
BUILD=${TEN_SLOPS_BUILD:-/workspace/ten-proofs-build}

export ELAN_HOME=${ELAN_HOME:-/workspace/.elan}
export PATH="$ELAN_HOME/bin:$PATH"

[ -d "$BUILD" ] || exit 2
cd "$BUILD"
COMMIT=$(git rev-parse HEAD)
TOOLCHAIN=$(cat lean-toolchain)

echo "conditions: host $(uname -srm)"
echo "conditions: ten-proofs commit $COMMIT"
echo "conditions: toolchain $TOOLCHAIN"
echo "conditions: lean $(lean --version 2>&1 | tail -1)"
echo "conditions: lake $(lake --version 2>&1 | head -1)"
echo "conditions: cores $(nproc), strategy sequential (v4), date $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Dependencies come from the committed lake-manifest.json (mathlib v4.32.0,
# comparator v4.32.0). lake update is deliberately NOT run: it re-resolves and
# can drift the pins. Assert the pin we are claiming instead.
grep -q '"type": "git"' lake-manifest.json || { echo "manifest shape unexpected"; exit 2; }
grep -q 'v4.32.0' lake-manifest.json || { echo "mathlib pin v4.32.0 not in manifest"; exit 2; }

echo "conditions: refreshing mathlib cache (unconditional, idempotent; log: evidence/20-mathlib-cache-get.log)"
lake exe cache get > /workspace/ten-slops/evidence/20-mathlib-cache-get.log 2>&1
RC=$?
[ $RC -eq 0 ] || { echo "result: mathlib cache get FAILED (rc=$RC), log kept"; exit 1; }
tr '\r' '\n' < /workspace/ten-slops/evidence/20-mathlib-cache-get.log | grep "Completed" | tail -1

# Outside observer: sample the resident set of the builder process tree.
( PEAK=0
  while true; do
    SUM=$(ps -eo rss=,comm=,stat= | awk '$1 !~ /^0$/ && $2 ~ /^(lean|lake|clang)$/ && $3 !~ /^Z/ {s+=$1} END {print s+0}')
    [ "$SUM" -gt "$PEAK" ] && PEAK=$SUM
    echo "$PEAK" > /workspace/ten-slops/evidence/20-peak-rss-kb
    sleep 2
  done ) &
SAMPLER=$!

MODULES='CompactnessAndDegeneracy MulticolorTriangleRamsey QuantumParallelRepetition SpherePacking MetricCodes ConnesRigidity NonSoficGroup GapCVP EhrhartVolumeInequality Permanent ComparatorChallenges All'

TIMING=/workspace/ten-slops/evidence/20-per-module-timing.txt
: > "$TIMING"
echo "# module  seconds  rc" >> "$TIMING"

FAIL=0
for M in $MODULES; do
  S=$(date +%s)
  lake build "$M" > "/workspace/ten-slops/evidence/20-build-$M.log" 2>&1
  RC=$?
  E=$(date +%s)
  echo "$M $((E-S)) $RC" >> "$TIMING"
  if [ $RC -ne 0 ]; then
    echo "FAIL  $M rc=$RC (log: evidence/20-build-$M.log)"
    tail -5 "/workspace/ten-slops/evidence/20-build-$M.log"
    FAIL=1
  else
    echo "PASS  $M in $((E-S))s"
  fi
done

kill $SAMPLER 2>/dev/null
echo "conditions: peak RSS of build tree (excluding zombies): $(cat /workspace/ten-slops/evidence/20-peak-rss-kb 2>/dev/null || echo 0) KB, sampled every 2s"
echo "conditions: .lake size $(du -sh "$BUILD/.lake" 2>/dev/null | cut -f1)"
echo "conditions: per-module timing in evidence/20-per-module-timing.txt"

[ $FAIL -eq 0 ] && echo "result: all eleven libs + All built clean, sequentially" \
               || echo "result: at least one module FAILED - see per-module rows above"
exit $FAIL
