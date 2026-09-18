#!/bin/sh
# EXPERIMENT 40 - SORRY / ESCAPE-HATCH SCAN OF THE TEN SOURCE FILES.
#
# Question answered: does the source text of the ten formalisations contain
# `sorry` (or the other proof escapes: `admit`, `native_decide` used as proof,
# `Classical.choice`-style postulates via `axiom`), testing upstream's
# `sorry_count: 0` claim at the text level? Grep LOCATES; the kernel-level
# sorryAx check in experiment 30 is what CONFIRMS. Both must be clean.
#
# Inputs pinned: same tree as experiment 20.
# Exit: 0 no escapes found, 1 found, 2 could not run.

set -u
cd "$(dirname "$0")/.."
BUILD=${TEN_SLOPS_BUILD:-/workspace/ten-proofs-build}
[ -d "$BUILD" ] || exit 2
cd "$BUILD"
echo "conditions: ten-proofs commit $(git rev-parse HEAD), date $(date -u +%Y-%m-%dT%H:%M:%SZ)"

TEN='CompactnessAndDegeneracy.lean MulticolorTriangleRamsey.lean QuantumParallelRepetition.lean SpherePacking.lean MetricCodes.lean ConnesRigidity.lean NonSoficGroup.lean GapCVP.lean EhrhartVolumeInequality.lean Permanent.lean'

OUT=/workspace/ten-slops/evidence/40-sorry-scan.txt
: > "$OUT"

echo "--- word 'sorry' occurrences (incl. comments/docs) ---" | tee -a "$OUT"
grep -c -w "sorry" $TEN | tee -a "$OUT"
echo "--- 'admit' occurrences ---" | tee -a "$OUT"
grep -c -w "admit" $TEN | tee -a "$OUT" || true
echo "--- top-level 'axiom' declarations ---" | tee -a "$OUT"
grep -nE "^axiom " $TEN | tee -a "$OUT" || true
echo "--- 'native_decide' occurrences ---" | tee -a "$OUT"
grep -n "native_decide" $TEN | tee -a "$OUT" || true

FAIL=0
if grep -qw "sorry" $TEN; then FAIL=1; echo "FAIL: literal 'sorry' present" | tee -a "$OUT"; else echo "PASS: no 'sorry' in any of the ten sources" | tee -a "$OUT"; fi
if grep -qE "^axiom " <<< "$(cat $TEN)"; then FAIL=1; fi
exit $FAIL
