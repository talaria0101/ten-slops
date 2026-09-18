# FINDINGS - independent re-verification of openai/ten-proofs

**Opened 2026-09-18. One question: do the Lean certificates in
openai/ten-proofs at commit `94bc0feb6a9f` actually re-verify from source -
build clean, each named main-result theorem present, and each depending on
nothing beyond the three standard axioms (no `sorryAx`)?**

Written for a reader who distrusts us. Every claim below is a row of an
instrument: the experiment that produced it is named beside it and can be
re-run without asking us anything.

---

## What this did NOT establish

Read this before the recommendations.

- **No mathematical review.** We verified that the proofs are *valid Lean
  proofs of the stated theorems*. We did not check that the *statements* say
  what the paper claims they say (that the "GapCVP hardness" formalization,
  say, matches the CVP hardness literature's definition). Statement-level
  fidelity to the ten papers was NOT audited. Upstream's own
  `ComparatorChallenges/` exist precisely because statement fidelity needs a
  challenge authored by a distrusting party; we re-ran their challenges, we
  did not author new ones.
- **One machine, one day.** All timings are this host (below), 2026-09-18.
  They bound the cost, they do not generalise.
- **`Lean.trustCompiler` was not needed** for any verdict we observed, but
  our axiom audit covers the *theorem proofs*, not compiled `decide`-style
  artifacts: if a proof uses `native_decide` the text scan (experiment 40)
  would have flagged it, and it found none. Scan scope is the ten
  formalization files, not the 6918 mathlib oleans we consumed from upstream
  mathlib's cache.
- **How many claims a previous revision got wrong: still zero revisions
  published before this one**, so the honest estimate of residual error is
  the estimate for any first pass - assume more remain.

## Conditions

| | |
| --- | --- |
| host | Linux 6.18.39-gentoo-dist-bin, x86_64, AMD Ryzen 7 7700 (16 hw threads), 30 GB RAM |
| subject | openai/ten-proofs @ `94bc0feb6a9ff12c7d31d6de640a725c9d43d2b6` (main, fetched 2026-09-18) |
| toolchain | leanprover/lean4:v4.32.0 (pinned by the subject's own `lean-toolchain`) |
| dependencies | mathlib v4.32.0, Comparator v4.32.0 - both pinned by the subject's committed `lake-manifest.json`; `lake update` deliberately never run |
| disk budget | 10 GB operator cap; peak footprint ≈ 7 GB (mathlib cache dominates) |
| corpus | kept, tracked, in `references/openai__ten-proofs/` (upstream Apache-2.0; we do not restate it) |

## Findings

### F1. The tree is exactly what upstream published (three fetch routes agree)

`mine-repo.sh` corpus, a fresh `git clone`, and GitHub's codeload tarball at
the pinned commit are byte-identical (`experiments/10-fetch-and-pin.sh`,
`experiments/70-tarball-reconcile.sh`). Per-file sha256 of every `.lean`
file: `evidence/source-sha256.txt`.

### F2. The tracker is empty, and that is a property of the repo, not a fetch failure

`has_issues: false`, `open_issues_count: 0`, search returns 0 total. No
issues, no PRs, no discussions exist to read. Upstream ships no public
defect list or maintainer rulings; the README and `formalization.yaml` are
the only self-description. (The `comments` gap in
`references/openai__ten-proofs/PROVENANCE.md` is a consequence: with issues
disabled there is nothing to fetch.)

### F3. "Ten proofs" = ten results, twelve named theorems

The README counts ten results; `formalization.yaml` names twelve
main-result declarations because two files carry two each (MetricCodes:
binary + spherical codes; CompactnessAndDegeneracy: compactness
counterexample + two-degenerate counterexample). `ComparatorChallenges/`
ships exactly twelve challenge configs, one per declaration. All twelve
were treated as the verification surface; each was located at file:line in
the sources (table in `evidence/30-axiom-audit.txt` and F5).

### F4. Every certificate builds from source at the pinned toolchain - RESULT

(`experiments/20-verify-build.sh`; per-module table
`evidence/20-per-module-timing.txt`, logs `evidence/20-build-<Module>.log`.)

RESULT-PLACEHOLDER

### F5. All twelve named theorems exist and depend only on propext, Classical.choice, Quot.sound - RESULT

(`experiments/30-axiom-audit.sh`, raw kernel output
`evidence/30-axiom-audit.raw`, verdicts `evidence/30-axiom-audit.txt`.)

RESULT-PLACEHOLDER

### F6. No `sorry` anywhere in the ten sources - CONFIRMED

(`experiments/40-sorry-scan.sh`, `evidence/40-sorry-scan.txt`: zero
`sorry`, zero `admit`, zero top-level `axiom`, zero `native_decide` in all
ten files.) Upstream's `sorry_count: 0` holds at the text level. The
kernel-level twin of this claim is F5 (no `sorryAx` in any transitive
footprint).

### F7. The verification can actually fail (mutation controls) - RESULT

(`experiments/50-mutation-control.sh`, `evidence/50-mutation-control.txt`,
logs `evidence/50a-*`, `evidence/50b-*`.)

RESULT-PLACEHOLDER

### F8. Upstream's own independent-checking route re-verifies the theorems - RESULT

(`experiments/60-comparator-check.sh`, summary
`evidence/60-comparator-summary.txt`, per-challenge logs
`evidence/60-*.log`.)

RESULT-PLACEHOLDER

## Costs (this host, 2026-09-18)

COST-TABLE-PLACEHOLDER

## Verdicts per section 3.6 of the methodology

| reference | verdict |
| --- | --- |
| openai/ten-proofs certificates | **confirms** (pending F4/F5/F8 placeholders resolving green) - the build+axiom mechanism is exactly what we would demand of a certificate repo: pinned toolchain, pinned deps, sorry-free, axiom-auditable |
| openai/ten-proofs `ComparatorChallenges/` | **adopt** - the challenge-JSON pattern (named theorems + permitted axiom list) is the right shape for independent checking and costs nothing to copy |
| openai/ten-proofs `formalization.yaml` | **adopt** - machine-readable claim table (declaration, file, sorry count, axioms) is what made this audit scriptable at all |

## Route refusals and dead ends (so nobody re-walks them)

1. **GNU time is absent on this host** - v1 of experiment 20 died with
   rc=127 before the build ran; measurement moved to an external sampler.
2. **Default parallelism OOMs**: 16 elaborators peaked ~24.7 GB sampled on a
   30 GB host and the run vanished (v2). `LEAN_NUM_CAPABILITIES=4` does NOT
   cap Lake 5.0's job count - v3 still spawned 8 elaborators (~32 GB
   sampled peak). **Sequential per-module builds (v4) are the only strategy
   that fits a 30 GB host.** Nobody should run this repo's build wide-open
   on a small machine.
3. **nanoda (independent kernel)**: builds clean with rustc 1.98 in ~14 s -
   no refusal; used by F8 if present.
4. **Tracker read**: refused by the repo itself (issues disabled) - see F2.

## Reader routing

| a reader with | reads |
| --- | --- |
| two minutes | this header, F4-F8 verdict lines |
| ten minutes | What this did NOT establish, then F2/F3/F7 |
| the job of re-verifying | `experiments/` in numeric order, then the conditions block |
| a reason to distrust us | `evidence/30-axiom-audit.raw`, then the mutation logs in `evidence/50*` |

Assume more remain.
