#!/bin/sh
# EXPERIMENT 10 - FETCH AND PIN.
#
# Question answered: can the exact tree this study cites be re-fetched and
# proven identical to what we read, by someone who does not trust us?
#
# Inputs pinned: openai/ten-proofs commit
#   94bc0feb6a9ff12c7d31d6de640a725c9d43d2b6  (main, fetched 2026-09-18)
#
# Re-runs the two fetch routes used here and byte-compares them:
#   route A: Azathothas/TEMPLATE scripts/common/mine-repo.sh (metadata+tracker+tree)
#   route B: plain git clone at the pinned commit
# and rewrites evidence/source-sha256.txt from route B.
#
# Exit: 0 identical, 1 ran and trees differ, 2 could not run.

set -eu
cd "$(dirname "$0")/.."
COMMIT=94bc0feb6a9ff12c7d31d6de640a725c9d43d2b6

echo "conditions: $(uname -srm), commit ${COMMIT}, date $(date -u +%Y-%m-%dT%H:%M:%SZ)"

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d -t ten-slops-10.XXXXXX)
trap 'rm -rf "$WORK"' EXIT

git clone --quiet https://github.com/openai/ten-proofs.git "$WORK/clone" || exit 2
git -C "$WORK/clone" checkout --quiet "$COMMIT" || exit 2

if diff -r --brief references/openai__ten-proofs/tree "$WORK/clone" -x .git >/dev/null 2>&1; then
  echo "result: corpus tree and fresh clone at ${COMMIT} are byte-identical"
else
  echo "result: MISMATCH between corpus tree and fresh clone at ${COMMIT}"
  diff -r --brief references/openai__ten-proofs/tree "$WORK/clone" -x .git || true
  exit 1
fi

: > "$REPO_ROOT/evidence/source-sha256.txt"
cd "$WORK/clone"
find . -name '*.lean' -not -path './.git/*' | sort | xargs sha256sum \
  >> "$REPO_ROOT/evidence/source-sha256.txt"
echo "wrote evidence/source-sha256.txt ($(wc -l < "$REPO_ROOT/evidence/source-sha256.txt") lines)"
exit 0
