#!/bin/sh
# EXPERIMENT 70 - UPSTREAM TARBALL RECONCILE.
#
# Question answered: does the corpus we kept and the tree we built from match
# GitHub's own archive of the pinned commit, byte for byte? Guards against
# corruption introduced between fetch and build by comparing the contents of
# GitHub's codeload tarball for commit 94bc0feb6a9f against the corpus tree.
#
# Exit: 0 identical, 1 differences found, 2 could not run.

set -eu
cd "$(dirname "$0")/.."
COMMIT=94bc0feb6a9ff12c7d31d6de640a725c9d43d2b6

echo "conditions: commit $COMMIT, date $(date -u +%Y-%m-%dT%H:%M:%SZ)"

WORK=$(mktemp -d /workspace/tmp/tarball-XXXXXX)
trap 'rm -rf "$WORK"' EXIT

curl -sL "https://codeload.github.com/openai/ten-proofs/tar.gz/$COMMIT" -o "$WORK/t.tgz"
[ -s "$WORK/t.tgz" ] || exit 2
tar -xzf "$WORK/t.tgz" -C "$WORK"
SRC=$(find "$WORK" -maxdepth 1 -type d -name 'ten-proofs-*' | head -1)
[ -n "$SRC" ] || exit 2

if diff -r --brief references/openai__ten-proofs/tree "$SRC" >/dev/null 2>&1; then
  echo "result: corpus tree == upstream tarball for $COMMIT"
  exit 0
else
  echo "result: MISMATCH against upstream tarball"
  diff -r --brief references/openai__ten-proofs/tree "$SRC" | head -20
  exit 1
fi
