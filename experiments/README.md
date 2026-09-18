# experiments/

Numbered instruments, in the order they were first run. Each answers one
question, pins its inputs, prints its conditions, and exits 0/1/2 (ran and
good / ran and the thing failed / could not run). `TEN_SLOPS_BUILD`
overrides the build checkout location (default `/workspace/ten-proofs-build`).

| # | script | question | verdict 2026-09-18 |
| --- | --- | --- | --- |
| 10 | `10-fetch-and-pin.sh` | is the kept corpus byte-identical to a fresh clone at the pinned commit? | PASS (`evidence/10-fetch-and-pin.txt`) |
| 20 | `20-verify-build.sh` | does `lake build All` exit 0 from clean at lean v4.32.0? | PASS, 1912 s sequential (`evidence/20-per-module-timing.txt`) |
| 30 | `30-axiom-audit.sh` | do the 12 named theorems exist with only the 3 claimed axioms? | PASS 12/12 (`evidence/30-axiom-audit.txt`) |
| 40 | `40-sorry-scan.sh` | any `sorry`/`admit`/`axiom`/`native_decide` in the ten sources? | PASS (`evidence/40-sorry-scan.txt`) |
| 50 | `50-mutation-control.sh` | do the guards above actually fire on broken input? | PASS both + byte-identical restore (`evidence/50-mutation-control.txt`) |
| 60 | `60-comparator-check.sh` | does upstream's own comparator route re-verify all 12 (builtin kernel + nanoda)? | PASS 12/12 (`evidence/60-comparator-summary.txt`) |
| 70 | `70-tarball-reconcile.sh` | does GitHub's own tarball of the commit match the corpus? | PASS (`evidence/70-tarball-reconcile.txt`) |

30 and 60 together are this unit's proof of concept: a runnable argument
that named theorems in a built Lean project can be independently re-judged
(statement match + axiom budget + independent kernel). They are not
imported by anything; they read the built environment from outside.

`tools/` holds the two local instrument patches of record:
`comparator-env-patch.diff` (upstream comparator, env-merge fix, verdict
code untouched) and `landrun-passthru` (sandbox pass-through; the Landlock
route is unavailable on this host - TCB discussion in FINDINGS.md F8).
`tools/mine-repo.sh` is the corpus fetcher, kept from Azathothas/TEMPLATE.

Scripts may be revised in place when the QUESTION does not change; the
revision reason goes in the header. Evidence files are append-or-overwrite
by their own experiment; superseded evidence is kept under a suffix (e.g.
`20-per-module-timing.v4-debris-tainted.txt`), never deleted.
Known loss of record: the first full mathlib-cache download log (6918
files, 52 s) was lost to a rename before its first commit; FINDINGS.md
flags the number as transcript-sourced on its cost table.
