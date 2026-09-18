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
# README states them too: landrun sandboxes the export; this session runs as
# uid 0 in a container (comparator's README assumes an unprivileged user);
# Linux landlock is the sandbox mechanism. A pass here is evidence about the
# PROOFS, weaker only in sandbox hygiene, which does not touch the kernel
# verdict.
#
# Exit: 0 all attempted challenges passed, 1 at least one failed,
#       2 could not run (tools missing).

set -u
cd "$(dirname "$0")/.."
BUILD=${TEN_SLOPS_BUILD:-/workspace/ten-proofs-build}
CORPUS=references/openai__ten-proofs/tree/ComparatorChallenges
export ELAN_HOME=${ELAN_HOME:-/workspace/.elan}
export PATH="$ELAN_HOME/bin:/workspace/bin:$PATH"
export COMPARATOR_LANDRUN=${COMPARATOR_LANDRUN:-/workspace/bin/landrun}
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
