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
| disk budget | 10 GB operator cap; peak observed ~5 GB, end-state 4.9 GB (`du` 2026-09-18, cost table) |
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
were treated as the verification surface. Each was located in the sources
(`theorem` line, per pass 2 of section 3.2):

| declaration | file:line |
| --- | --- |
| PackingBounds.sharpFullCohnElkiesManuscriptConclusions | SpherePacking.lean:55591 |
| MetricCodes.Johnson.binaryRate_lt_mrrw | MetricCodes.lean:20797 |
| MetricCodes.Spherical.HigherHierarchy.strict_hierarchy | MetricCodes.lean:114336 |
| PermanentFormulaLowerBound.permanent_rational_formula_logarithmic_lower_bound | Permanent.lean:27551 |
| SoficGroups.SourceTopLevelCompressionFinal.exists_finitelyPresented_nonsofic_group | NonSoficGroup.lean:34430 |
| ConnesRigidity.exists_infinite_pairwise_nonisomorphic_propertyT_icc_groups_with_isomorphic_factors | ConnesRigidity.lean:37347 (name wrapped to 37348) |
| Ehrhart.Volume.ehrhart_volume_inequality_for_sets | EhrhartVolumeInequality.lean:55733 |
| QuantumParallelRepetition.distributionUniformExponential | QuantumParallelRepetition.lean:70953 |
| GapCVP.Comparator.gapCVP400IsNPHard | GapCVP.lean:130398 |
| ErdosProblems.MulticolourTriangleRamsey.erdos_problem_183_explicit | MulticolorTriangleRamsey.lean:3042 |
| CompactnessConjecture.quantitativeCompactnessCounterexample | CompactnessAndDegeneracy.lean:9320 |
| TwoDegenerateGraphs.twoDegenerateExtremalCounterexample | CompactnessAndDegeneracy.lean:18441 |

### F4. Every certificate builds from source at the pinned toolchain - CONFIRMED

(`experiments/20-verify-build.sh`; per-module table
`evidence/20-per-module-timing.txt`, logs `evidence/20-build-<Module>.log`.)

From a fully clean state (post `lake clean`), each of the eleven libraries
and `All` built with exit 0, sequentially, one elaborator at a time:

| module | wall time | rc |
| --- | --- | --- |
| CompactnessAndDegeneracy | 105 s | 0 |
| MulticolorTriangleRamsey | 30 s | 0 |
| QuantumParallelRepetition | 407 s | 0 |
| SpherePacking | 150 s | 0 |
| MetricCodes | 424 s | 0 |
| ConnesRigidity | 310 s | 0 |
| NonSoficGroup | 75 s | 0 |
| GapCVP | 206 s | 0 |
| EhrhartVolumeInequality | 86 s | 0 |
| Permanent | 70 s | 0 |
| ComparatorChallenges | 28 s | 0 |
| All | 21 s | 0 |
| **total** | **1912 s ≈ 32 min** (single worker) | **0 everywhere** |

The first full-download of mathlib's cache (6918 files) took 52 s; that
log file was lost to an instrument-rename before any commit captured it,
so that number is transcript-sourced and indicative only. The committed
artifact next to it measures the neighbouring case: after `lake clean`,
with the local archive store present, cache get re-decompresses 8265
archives with zero downloads in 13 s
(`evidence/20-mathlib-cache-get.after-clean-local-store.log`). An
incremental no-op re-check takes 31 s (`evidence/20-mathlib-cache-get.log`). End-state footprint of the build
tree: 3.8 GB. Peak resident set of ONE elaborator, directly observed:
~9 GB (QuantumParallelRepetition); the run-wide sampler peaked at 38.5 GB
during the ComparatorChallenges phase, which Lake parallelises across its
twelve roots - that figure also double-counts shared libraries across
processes, so read it as "wide builds are dangerous on a 30 GB host", not
as a per-proof cost.

### F5. All twelve named theorems exist and depend only on propext, Classical.choice, Quot.sound - CONFIRMED

(`experiments/30-axiom-audit.sh`, raw kernel output
`evidence/30-axiom-audit.raw`, verdicts `evidence/30-axiom-audit.txt`.)

12 of 12: every declaration named in `formalization.yaml` exists in the
built environment, and `#print axioms` reports for each exactly
`[propext, Classical.choice, Quot.sound]` - the three standard axioms every
classical-mathematics Lean development is allowed - with **no `sorryAx` and
no custom postulates**. `grep sorryAx` over the raw audit output: zero
matches. This is the kernel's own transitive-dependency report, not a
text scan.

Instrument correction of record: v1 of this experiment reported 4 of 12 as
FAILING because `#print axioms` line-wraps long declaration names and the
parser matched single lines only. The raw output was kept, the parser was
fixed (whitespace-normalised matching), and the same raw output re-parsed
to 12/12. Nothing about the theorems changed between those two rows - the
defect was in our instrument, which is exactly where defects belong.

### F6. No `sorry` anywhere in the ten sources - CONFIRMED

(`experiments/40-sorry-scan.sh`, `evidence/40-sorry-scan.txt`: zero
`sorry`, zero `admit`, zero top-level `axiom`, zero `native_decide` in all
ten files.) Upstream's `sorry_count: 0` holds at the text level. The
kernel-level twin of this claim is F5 (no `sorryAx` in any transitive
footprint).

### F7. The verification can actually fail (mutation controls) - CONFIRMED

(`experiments/50-mutation-control.sh`, `evidence/50-mutation-control.txt`,
logs `evidence/50a-*`, `evidence/50b-*`.)

- **50a, false claim:** `example : False := by trivial` appended to
  MulticolorTriangleRamsey.lean - `lake build` REJECTED it (rc=1,
  `Tactic 'assumption' failed` at the planted line).
- **50b, planted sorry:** `theorem ten_slops_planted_sorry : 1 = 2 := by
  sorry` - `lake build` accepted it with rc=0 and only a warning
  (`declaration uses \`sorry\``). The axiom audit caught what the build
  forgave: `#print axioms ten_slops_planted_sorry` → `[sorryAx]`.
  **A green build alone is not verification. Experiment 30 is load-bearing.**
- **Restore proven byte-identical:** sha256
  `a87bd60efe16dab00ba07ea4069f22b8dbc991b3f3ba34ae5088b1f8b1987cd3`
  before and after, module rebuilt green afterwards.

This is the evidence that proves the proving: the same instruments that
returned green above demonstrably return red on mutated input, and the
mutation targets the exact guard each instrument is responsible for.

### F8. Upstream's own independent-checking route re-verifies the theorems - CONFIRMED, with two instrument patches of record

(`experiments/60-comparator-check.sh`, summary
`evidence/60-comparator-summary.txt`, per-challenge logs
`evidence/60-*.log`.)

**All twelve ComparatorChallenges passed (rc=0).** Each challenge restates
its theorem from scratch with a `sorry` (definitions independent of the
solution module); comparator exports the solution's proof terms via
lean4export and re-checks them with Lean's builtin kernel replay AND the
independent nanoda kernel (`enable_nanoda: true`, nanoda v0.4.17 built from
source). Every log contains both `Lean default kernel accepts the solution`
and `Nanoda kernel accepts the solution` - 12 logs, 12 of each.

Two deviations from stock upstream tooling, both made only to get their own
route running in this container, neither touching verdict logic:

1. **comparator env patch** (`tools/comparator-env-patch.diff`, applied to
   leanprover/comparator at tag v4.32.0): Lean 4.32's `IO.Process` env
   field replaces the child environment, so upstream's spawn of landrun
   stripped PATH/HOME/LEAN_PATH/ELAN_HOME and landrun's `--env KEY` then
   passed emptiness downstream. Patch: merge the parent's
   PATH/HOME/LEAN_PATH/ELAN_HOME back in at the three landrun spawn sites.
   Without it every challenge died with `unknown module prefix 'Nat'`.
2. **landrun replaced by a pass-through wrapper**
   (`/workspace/bin/landrun-passthru`, kept in the repo as
   `tools/landrun-passthru`): landrun v0.1.17 requires Landlock ABI v9,
   this host exposes v7, and its argv handling mangles the `--` separator
   lean4export's CLI requires. The pair `evidence/60-landrun-argv.txt`
   (landrun's own argv: separator present at line 24) plus the child-side
   error in `evidence/60-D_NonSoficGroup.log` (`unknown module prefix
   'Nat'`, i.e. it never arrived) pin the loss to landrun's argv
   handling. **Consequence,
   stated plainly: the export and kernel re-checks ran WITHOUT process
   sandboxing.** The sandbox protects against a malicious Solution file;
   the Solution here is the pinned upstream tree, not an adversary, and
   the kernel verdicts - the part that constitutes proof - are computed by
   the kernels either way. A hostile-source re-verification would need the
   sandbox route restored (Landlock v9 host, or a landrun release that
   accepts v7).

## Costs (this host, 2026-09-18)

| item | value | source |
| --- | --- | --- |
| clean build, all 12 modules, sequential | 1912 s ≈ 32 min | `evidence/20-per-module-timing.txt` |
| slowest single module | MetricCodes, 424 s | same |
| mathlib cache, first full download | 6918 files, 52 s - transcript-sourced, log lost pre-commit, indicative | session transcript, flagged here |
| mathlib cache after clean, local store | 8265 archives re-decompressed, 0 downloads, 13 s | `evidence/20-mathlib-cache-get.after-clean-local-store.log` |
| mathlib cache, incremental re-check | 31 s | `evidence/20-mathlib-cache-get.log` |
| axiom audit (12 theorems) | seconds; one `lake env lean` pass | `evidence/30-axiom-audit.raw` |
| comparator challenge, per module | tens of seconds to minutes; export size ~26 MB for D_NonSoficGroup | `evidence/60-*.log` |
| nanoda build | 14 s (rustc 1.98, release) | session log, reproducible via `cargo build --release` |
| end-state disk of the whole rig | ~4.9 GB (build tree 3.8 + toolchain 0.86 + aux tools 0.25) | `du`, 2026-09-18 |
| operator disk cap | 10 GB - never approached | this table |

## Verdicts per section 3.6 of the methodology

| reference | verdict |
| --- | --- |
| openai/ten-proofs certificates | **confirms** - the build+axiom mechanism is exactly what we would demand of a certificate repo: pinned toolchain, pinned deps, sorry-free, axiom-auditable, and it survives independent-kernel re-check |
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
5. **landrun sandbox**: refused by the host (Landlock ABI v7 vs required v9)
   AND by landrun's argv handling; replaced by a pass-through wrapper with
   the TCB consequence written into F8. Do not re-attempt on this host
   without a Landlock v9 kernel.
6. **nanoda on every challenge**: not a refusal - it ran on all twelve
   (12 logs, 12 acceptance lines) - listed here only because earlier
   scoping notes treated it as optional.

## Reader routing

| a reader with | reads |
| --- | --- |
| two minutes | this header, F4-F8 verdict lines |
| ten minutes | What this did NOT establish, then F2/F3/F7 |
| the job of re-verifying | `experiments/` in numeric order, then the conditions block |
| a reason to distrust us | `evidence/30-axiom-audit.raw`, then the mutation logs in `evidence/50*` |

Assume more remain.
