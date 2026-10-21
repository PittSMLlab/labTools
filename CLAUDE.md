# CLAUDE.md — labTools

<!-- Maintainers: keep this file to what every session needs (under
120 lines). Path-specific invariants go in .claude/rules/ (loaded only
when a matching file is read); details live in the topic docs below.
.claude/rules/matlab-style.md mirrors CONTRIBUTING.md: keep in sync. -->

## Pipeline
`rawTrialData → processedLabData → strideData → adaptationData →
groupAdaptationData → studyData`. Import starts at `c3d2mat` →
`loadSubject`; full call chain in
[README.md](README.md#full-call-chain).

**`experimentData` is a value class:** always capture the return
value: `expData = expData.recomputeParameters()`.

## Which Recompute
- `recomputeEvents` currently errors; use
  `flushAndRecomputeParameters` instead.
- `recomputeParameters` — `eventClass` must match the original run.
- `flushAndRecomputeParameters` — to change `eventClass`, or whenever
  the stride count may change.
- Never recompute a split SpinalAdapt `<ID>.mat`: recompute
  `<ID>OriginalCondName.mat`, then split again.

Details: [README.md](README.md#recompute-workflows).

## Where New Code Goes
- Computes or transforms → `fun/` (subfolders:
  [README.md](README.md#repository-layout))
- Stores or queries data → `classes/dataStructs/`; signals →
  `classes/labTS/`
- User input/output and interactive plots → `gui/`
- Example and validation scripts → `example/`, `testing/`

All code must run on MATLAB R2021a through the current release.
Style: `.claude/rules/matlab-style.md` (loads for `.m` files).

## Hard Rules
- Do not rename or delete existing files, functions, or commented-out
  code without the user's approval (lab sign-off pending).
- Never edit `fun/ext/BTK/`: it is unmodified third-party code.

## How to Verify
There is no automated suite: follow [TESTING.md](TESTING.md) (test
matrix, before/after `compareAdaptationData`). `calcParameters` turns
a failing parameter class into one warning per trial, so check every
trial's warnings and label presence, not only that the run finished.

## Topic Docs
[README](README.md) (layout, classes, call chain, recompute) ·
[CONTRIBUTING](CONTRIBUTING.md) (style, human reference) ·
[TESTING](TESTING.md) (regression) ·
[FEATURES](FEATURES.md) (handrail, stride quality, H-reflex,
SpinalAdapt) · [EXPERIMENT_SETUP](EXPERIMENT_SETUP.md) (new
experiments) · [DATA_OUTPUTS](DATA_OUTPUTS.md) (what writes where)
