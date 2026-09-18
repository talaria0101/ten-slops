#!/bin/sh
# EXPERIMENT 60 - INDEPENDENT-KERNEL RE-CHECK VIA COMPARATOR (upstream's own route).
#
# Question answered: do the twelve main-result theorems also survive a check
# by Comparator (leanprover/comparator at tag v4.32.0), which re-verifies the
# proof terms through lean4export outside the elaborating toolchain, with
# nanoda (an independent kernel implementation) as the external checker where
# available? This is upstream's own published route for independent checking
# (ComparatorChallenges/README.md in their tree).
#
# Inputs pinned:
#   comparator   leanprover/comparator tag v4.32.0 (commit 07bc4ea40f22 -
#                the SAME commit ten-proofs' lake-manifest.json pins as its
#                Comparator dependency)
#   lean4export  leanprover/lean4export tag v4.32.0
#   landrun      Zouuup/landrun v0.1.17 release binary
#   nanoda       ammkrn/nanoda_lib master (OPTIONAL; skipped if cargo build
#                not present - recorded, not hidden)
#   challenge    the 12 ComparatorChallenges/*.json from the corpus tree
#
# TCB caveats, stated because the methodology demands them and comparator's
# README states them too: comparator's landrun sandbox DOES NOT RUN here -
# this kernel exposes Landlock ABI v7 while landrun v0.1.17 requires v9, and
# its argv handling strips the `--` separator lean4export's CLI needs (both
# diagnosed 2026-09-18, see evidence/60-landrun-argv.txt). So
# COMPARATOR_LANDRUN is a pass-through wrapper: the export and the kernel
# re-checks run with FULL verdict semantics but WITHOUT process sandboxing.
# The sandbox protects against a malicious Solution file; the Solution here
# is the pinned upstream tree at 94bc0feb6a9f, not an adversary. The kernel
# verdicts (builtin Lean replay + nanoda) do not depend on the sandbox.
# This session also runs as uid 0 in a container, which comparator's README
# itself flags as out of its assumed threat model.
#
# Exit: 0 all attempted challenges passed, 1 at least one failed,
#       2 could not run (tools missing).

set -u
cd "$(dirname "$0")/.."
BUILD=${TEN_SLOPS_BUILD:-/workspace/ten-proofs-build}
CORPUS=references/openai__ten-proofs/tree/ComparatorChallenges
export ELAN_HOME=${ELAN_HOME:-/workspace/.elan}
# PATH ORDER MATTERS: /workspace/bin holds DIRECT symlinks to the toolchain's
# lean/lake. Inside landrun only PATH/HOME/LEAN_PATH/LEAN_ABORT_ON_PANIC
# survive (comparator's envPass is hardcoded), so the elan shim dies - it
# demands ELAN_HOME, which is not passed. The symlinks skip the shim.
export PATH="/workspace/bin:$ELAN_HOME/bin:$PATH"
export COMPARATOR_LANDRUN=${COMPARATOR_LANDRUN:-/workspace/bin/landrun-passthru}
export COMPARATOR_LEAN4EXPORT=${COMPARATOR_LEAN4EXPORT:-/workspace/lean4export-build/.lake/build/bin/lean4export}
export COMPARATOR_NANODA=${COMPARATOR_NANODA:-/workspace/nanoda_lib/target/release/nanoda_bin}

[ -d "$BUILD" ] || exit 2
[ -x "$COMPARATOR_LANDRUN" ] || { echo "landrun missing"; exit 2; }
[ -x "$COMPARATOR_LEAN4EXPORT" ] || { echo "lean4export missing"; exit 2; }

COMP_BIN=$(find /workspace/comparator-build/.lake -type f -name comparator -perm -u+x 2>/dev/null | head -1)
[ -n "$COMP_BIN" ] || { echo "comparator binary missing"; exit 2; }

echo "conditions: host $(uname -srm), date $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "conditions: comparator $(git -C /workspace/comparator-build rev-parse --short=12 HEAD)"
echo "conditions: lean4export $(git -C /workspace/lean4export-build rev-parse --short=12 HEAD)"
echo "conditions: landrun $("$COMPARATOR_LANDRUN" --version 2>&1 | head -1)"
if [ -x "$COMPARATOR_NANODA" ]; then echo "conditions: nanoda present"; HAVE_NANODA=1; else echo "conditions: nanoda NOT present - challenges will run with the builtin kernel only"; HAVE_NANODA=0; fi
echo "conditions: ten-proofs build at $(git -C "$BUILD" rev-parse --short=12 HEAD)"

cd "$BUILD"

FAIL=0
: > /workspace/ten-slops/evidence/60-comparator-summary.txt
for J in "$OLDPWD"/$CORPUS/*.json; do
  NAME=$(basename "$J" .json)
  if [ "$HAVE_NANODA" = "0" ]; then
    # strip enable_nanoda rather than let the tool error on a missing binary
    T=$(mktemp /workspace/tmp/chal-XXXXXX.json)
    grep -v enable_nanoda "$J" > "$T"
    J="$T"
  fi
  echo "--- challenge $NAME"
  lake env "$COMP_BIN" "$J" > "/workspace/ten-slops/evidence/60-$NAME.log" 2>&1
  RC=$?
  echo "$NAME rc=$RC" >> /workspace/ten-slops/evidence/60-comparator-summary.txt
  if [ $RC -eq 0 ]; then
    echo "PASS  $NAME"
  else
    echo "FAIL  $NAME rc=$RC (log: evidence/60-$NAME.log)"
    tail -5 "/workspace/ten-slops/evidence/60-$NAME.log"
    FAIL=1
  fi
done

grep -c PASS /workspace/ten-slops/evidence/60-comparator-summary.txt
exit $FAIL
