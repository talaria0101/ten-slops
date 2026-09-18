#!/bin/sh
# EXPERIMENT 30 - AXIOM AUDIT OF THE TWELVE NAMED MAIN-RESULT DECLARATIONS.
#
# Question answered: does each main-result declaration named in upstream's
# formalization.yaml actually exist in the built environment, and does its
# transitive axiom footprint match what upstream claims (propext,
# Classical.choice, Quot.sound - and in particular NO sorryAx)?
# This is the second oracle on top of "the build exited 0": the kernel's own
# report, parsed by us, against the claim table, parsed by us.
#
# Inputs pinned: same build as experiment 20 (TEN_SLOPS_BUILD, default
# /workspace/ten-proofs-build); declaration list embedded below and copied
# verbatim from formalization.yaml at commit 94bc0feb6a9f.
#
# Exit: 0 all twelve exist with exactly the claimed axioms,
#       1 ran and at least one check failed, 2 could not run.

set -u
cd "$(dirname "$0")/.."
BUILD=${TEN_SLOPS_BUILD:-/workspace/ten-proofs-build}
export ELAN_HOME=${ELAN_HOME:-/workspace/.elan}
export PATH="$ELAN_HOME/bin:$PATH"

[ -d "$BUILD" ] || exit 2
cd "$BUILD"
echo "conditions: ten-proofs commit $(git rev-parse HEAD), lean $(lean --version 2>&1 | tail -1), date $(date -u +%Y-%m-%dT%H:%M:%SZ)"

DECLS='
PackingBounds.sharpFullCohnElkiesManuscriptConclusions
MetricCodes.Johnson.binaryRate_lt_mrrw
MetricCodes.Spherical.HigherHierarchy.strict_hierarchy
PermanentFormulaLowerBound.permanent_rational_formula_logarithmic_lower_bound
SoficGroups.SourceTopLevelCompressionFinal.exists_finitelyPresented_nonsofic_group
ConnesRigidity.exists_infinite_pairwise_nonisomorphic_propertyT_icc_groups_with_isomorphic_factors
Ehrhart.Volume.ehrhart_volume_inequality_for_sets
QuantumParallelRepetition.distributionUniformExponential
GapCVP.Comparator.gapCVP400IsNPHard
ErdosProblems.MulticolourTriangleRamsey.erdos_problem_183_explicit
CompactnessConjecture.quantitativeCompactnessCounterexample
TwoDegenerateGraphs.twoDegenerateExtremalCounterexample
'

AUDIT=$(mktemp /workspace/tmp/audit-XXXXXX.lean)
trap 'rm -f "$AUDIT"' EXIT
{ echo "import All"
  for d in $DECLS; do
    echo "#check @$d"
    echo "#print axioms $d"
  done
} > "$AUDIT"

echo "conditions: auditing $(echo $DECLS | wc -w) declarations"
lake env lean "$AUDIT" > /workspace/ten-slops/evidence/30-axiom-audit.raw 2>&1
LEAN_RC=$?
echo "conditions: lake env lean exit $LEAN_RC (0 expected; unknown identifiers would make it non-zero)"

FAIL=0
: > /workspace/ten-slops/evidence/30-axiom-audit.txt
# #print axioms output line-wraps for long names (v1 of this experiment
# mis-parsed 4 of 12 as empty footprints for exactly that reason; same
# question, same number). Normalize whitespace before matching.
FLAT=$(tr '\n' ' ' < /workspace/ten-slops/evidence/30-axiom-audit.raw | tr -s ' ')
for d in $DECLS; do
  if grep -q "error: unknown identifier '$d'" /workspace/ten-slops/evidence/30-axiom-audit.raw; then
    echo "FAIL  $d : declaration NOT FOUND in built environment" | tee -a /workspace/ten-slops/evidence/30-axiom-audit.txt
    FAIL=1
    continue
  fi
  if printf '%s' "$FLAT" | grep -q "'$d' depends on axioms: \\[propext, Classical.choice, Quot.sound\\]"; then
    echo "PASS  $d : depends on axioms [propext, Classical.choice, Quot.sound]" | tee -a /workspace/ten-slops/evidence/30-axiom-audit.txt
  elif printf '%s' "$FLAT" | grep -q "'$d' does not depend on any axioms"; then
    echo "PASS  $d : depends on no axioms (stronger than claimed)" | tee -a /workspace/ten-slops/evidence/30-axiom-audit.txt
  else
    AX=$(printf '%s' "$FLAT" | grep -oE "'$d' depends on axioms: \\[[^]]*\\]" | head -1)
    echo "FAIL  $d : axiom footprint '$AX' does not equal claimed [propext, Classical.choice, Quot.sound]" | tee -a /workspace/ten-slops/evidence/30-axiom-audit.txt
    FAIL=1
  fi
done

if grep -q "sorryAx" /workspace/ten-slops/evidence/30-axiom-audit.raw; then
  echo "FAIL  sorryAx appears somewhere in the audit output" | tee -a /workspace/ten-slops/evidence/30-axiom-audit.txt
  FAIL=1
fi

grep -c "^PASS" /workspace/ten-slops/evidence/30-axiom-audit.txt | xargs -I{} echo "summary: {} of 12 declarations PASS"
[ $LEAN_RC -ne 0 ] && FAIL=1
exit $FAIL
