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
# Costs recorded: wall time, peak RSS (all lake/lean children), disk used.
#
# Exit: 0 build clean, 1 build ran and failed, 2 could not run.

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
echo "conditions: cores $(nproc), date $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Dependencies come from the committed lake-manifest.json (mathlib v4.32.0,
# comparator v4.32.0). lake update is deliberately NOT run: it re-resolves and
# can drift the pins. Assert the pin we are claiming instead.
grep -q '"type": "git"' lake-manifest.json || { echo "manifest shape unexpected"; exit 2; }
grep -q 'v4.32.0' lake-manifest.json || { echo "mathlib pin v4.32.0 not in manifest"; exit 2; }

echo "conditions: fetching deps + mathlib cache (log: evidence/20-mathlib-cache-get.log)"
lake exe cache get > /workspace/ten-slops/evidence/20-mathlib-cache-get.log 2>&1
RC=$?
[ $RC -eq 0 ] || { echo "result: mathlib cache get FAILED (rc=$RC), log kept"; exit 1; }
tail -2 /workspace/ten-slops/evidence/20-mathlib-cache-get.log

# The build, measured from outside by /usr/bin/time.
/usr/bin/time -v lake build All > /workspace/ten-slops/evidence/20-build-All.log 2> /workspace/ten-slops/evidence/20-build-All.time
RC=$?

echo "--- peak resources (from /usr/bin/time -v) ---"
grep -E "Elapsed \(wall|Maximum resident" /workspace/ten-slops/evidence/20-build-All.time || true
echo "--- lean/lake stderr lines: $(wc -l < /workspace/ten-slops/evidence/20-build-All.time) ---"

if [ $RC -ne 0 ]; then
  echo "result: lake build All FAILED (rc=$RC); log kept at evidence/20-build-All.log"
  tail -20 /workspace/ten-slops/evidence/20-build-All.log
  exit 1
fi
echo "result: lake build All exited 0"
du -sh "$BUILD/.lake" 2>/dev/null || true
exit 0
