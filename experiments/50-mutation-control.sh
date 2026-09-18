#!/bin/sh
# EXPERIMENT 50 - MUTATION CONTROL (the guard-mutation lens).
#
# Question answered: can our verification actually fail? A green build and a
# green axiom audit are only evidence if the instruments reject a broken
# input. Two defects are planted on purpose, each testing a different guard:
#
#   50a: a deliberately FALSE claim (`example : False := by trivial`)
#        appended to MulticolorTriangleRamsey.lean.
#        Expected: `lake build` REJECTS (kernel refuses the proof).
#
#   50b: a `sorry` substituted for a proof (the classic way a formalisation
#        cheats). Expected: `lake build` only WARNS - which is exactly why
#        experiment 30 exists - and the axiom audit flags sorryAx.
#
# After both mutations the tree is restored byte-identical (sha256 proven)
# and the module is rebuilt green, so the host tree is left exactly as found.
#
# Exit: 0 both guards fired and restore proven byte-identical,
#       1 a guard did NOT fire (verification is vacuous - serious finding),
#       2 could not run.

set -u
cd "$(dirname "$0")/.."
BUILD=${TEN_SLOPS_BUILD:-/workspace/ten-proofs-build}
export ELAN_HOME=${ELAN_HOME:-/workspace/.elan}
export PATH="$ELAN_HOME/bin:$PATH"
[ -d "$BUILD" ] || exit 2
cd "$BUILD"
COMMIT=$(git rev-parse HEAD)
TARGET=MulticolorTriangleRamsey.lean
SUMMARY=/workspace/ten-slops/evidence/50-mutation-control.txt
: > "$SUMMARY"
echo "conditions: ten-proofs commit $COMMIT, target $TARGET, date $(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$SUMMARY"

ORIG_HASH=$(sha256sum "$TARGET" | cut -d' ' -f1)
echo "conditions: pristine sha256 $ORIG_HASH" | tee -a "$SUMMARY"

# ---- 50a: false claim ------------------------------------------------------
cp "$TARGET" "$TARGET.pristine"
printf '\n-- ten-slops mutation control 50a (%s): planted false claim\nexample : False := by trivial\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$TARGET"
lake build MulticolorTriangleRamsey > /workspace/ten-slops/evidence/50a-false-claim.log 2>&1
RC_A=$?
if [ $RC_A -ne 0 ]; then
  echo "PASS  50a: lake build REJECTED the false claim (rc=$RC_A)" | tee -a "$SUMMARY"
  grep -m2 -E "error" /workspace/ten-slops/evidence/50a-false-claim.log | tee -a "$SUMMARY"
else
  echo "FAIL  50a: lake build ACCEPTED a false claim - verification is vacuous" | tee -a "$SUMMARY"
fi

# ---- 50b: sorry substitution ----------------------------------------------
cp "$TARGET.pristine" "$TARGET"
printf '\n-- ten-slops mutation control 50b (%s): planted sorry\ntheorem ten_slops_planted_sorry : 1 = 2 := by sorry\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$TARGET"
lake build MulticolorTriangleRamsey > /workspace/ten-slops/evidence/50b-sorry-build.log 2>&1
RC_B=$?
WARN=$(grep -c "declaration uses .sorry" /workspace/ten-slops/evidence/50b-sorry-build.log || true)
if [ $RC_B -eq 0 ] && [ "${WARN:-0}" -ge 1 ]; then
  echo "NOTE  50b: lake build ACCEPTED the sorry (rc=0, $WARN warning). Build alone is not the whole check." | tee -a "$SUMMARY"
else
  echo "NOTE  50b: unexpected: rc=$RC_B warnings=$WARN (see evidence/50b-sorry-build.log)" | tee -a "$SUMMARY"
fi
printf "#print axioms ten_slops_planted_sorry\n" > /workspace/tmp/50b-audit.lean
printf "import MulticolorTriangleRamsey\n" > /workspace/tmp/50b-audit.lean
printf "import MulticolorTriangleRamsey\n#print axioms ten_slops_planted_sorry\n" > /workspace/tmp/50b-audit.lean
lake env lean /workspace/tmp/50b-audit.lean > /workspace/ten-slops/evidence/50b-sorry-audit.log 2>&1
if grep -q "sorryAx" /workspace/ten-slops/evidence/50b-sorry-audit.log; then
  echo "PASS  50b: axiom audit FLAGGED sorryAx for the planted sorry" | tee -a "$SUMMARY"
  grep "depends on axioms" /workspace/ten-slops/evidence/50b-sorry-audit.log | tee -a "$SUMMARY"
else
  echo "FAIL  50b: axiom audit did NOT catch the planted sorry" | tee -a "$SUMMARY"
fi

# ---- restore, proven byte-identical ---------------------------------------
cp "$TARGET.pristine" "$TARGET" && rm -f "$TARGET.pristine"
NEW_HASH=$(sha256sum "$TARGET" | cut -d' ' -f1)
if [ "$ORIG_HASH" = "$NEW_HASH" ]; then
  echo "PASS  restore: $TARGET restored byte-identical (sha256 $NEW_HASH)" | tee -a "$SUMMARY"
else
  echo "FAIL  restore: sha256 changed $ORIG_HASH -> $NEW_HASH" | tee -a "$SUMMARY"
  exit 1
fi

echo "conditions: rebuilding restored module to confirm green again" | tee -a "$SUMMARY"
lake build MulticolorTriangleRamsey > /workspace/ten-slops/evidence/50-restore-build.log 2>&1
RC_R=$?
[ $RC_R -eq 0 ] && echo "PASS  rebuild after restore: rc=0" | tee -a "$SUMMARY" || { echo "FAIL  rebuild after restore rc=$RC_R" | tee -a "$SUMMARY"; exit 1; }

# guards fired?
grep -q "PASS  50a" "$SUMMARY" && grep -q "PASS  50b" "$SUMMARY" || exit 1
exit 0
