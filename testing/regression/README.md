# Regression Harness

Before/after checks for changes that must not alter results. They
compare the code on the path against baselines saved by a reference
tree (usually the commit before the change): parameters with
`compareAdaptationData` (0 Changed), plus per-trial printed output
(warnings), gait events, unmatched strides, NaN mismatches and label
sets. `compareAdaptationData` alone misses most of these. The simpler
recipe without this harness is in [TESTING.md](../../TESTING.md).

| Check | Function | Covers |
|---|---|---|
| flush | `regressionBaselineRun` / `regressionCompareRun` | `calcParameters` + compute* + `makeDataObj` on stored processed data |
| process | `regressionProcessRun` | RAW -> `labData.process` (processEMG, calcLimbAngles, getEvents, belt speeds, torques/COP) -> `calcParameters` -> `makeDataObj`, per-trial events and output |
| events | `regressionEventsCheck` | `getEvents` on the `example/data` LI16 fixture and on every session trial |
| direct | `regressionDirectRun` | synthetic-input cases (outputs, error and warning text, figure snapshots) for code no session reaches |

`regressionAll` runs flush, events and process; `regressionStrictCheck`
is called by the flush and process compares; `regressionLineCoverage`
lists the executed lines so you can see what a change's files have
that the checks never run.

None of this covers `loadSubject`, `loadTrials`, `processGRFData`,
`syncEMGData` or `SyncDatalog`: those need a C3D session. A treadmill
session alone also misses the OGFP functions, H-reflex parameters and
the SpinalAdapt bout split.

## Setup
A baseline folder outside the repo (it holds copies of session data):
```
<baseDir>/session/<ID>.mat      processed experimentData (a copy)
<baseDir>/session/<ID>RAW.mat   raw experimentData (a copy)
```
Never point these functions at the original session folder. Use a
session with few trials: the whole session is loaded into memory
(a two-trial session needs ~5 GB free; a 1 GB RAW file can take
5 GB in memory).

## Baseline (on the reference tree)
Check out the reference commit in a separate worktree, so the tree
under test stays untouched:
```
git worktree add ../labTools-ref <commit>
cd ../labTools-ref
matlab -batch "addpath(genpath(pwd)); addpath(genpath('<repo>/testing/regression')); b = '<baseDir>'; s = fullfile(b, 'session'); regressionBaselineRun(fullfile(s, '<ID>.mat'), '<eventClass>', b); regressionEventsCheck('baseline', b, fullfile(s, '<ID>.mat')); regressionProcessRun('baseline', fullfile(s, '<ID>RAW.mat'), '<eventClass>', b)"
```
Each baseline step repeats its run once and fails unless the repeat is
identical (determinism check). Remove the worktree afterwards with
`git worktree remove ../labTools-ref`.

## Compare (on the changed tree)
From the repo root, in the background (~10 min for two trials; output
appears when MATLAB exits):
```
matlab -batch "addpath(genpath(pwd)); regressionAll('<baseDir>', '<ID>', '<eventClass>')" > gate.log 2>&1
grep GATE gate.log
```
Passing ends with `GATE SUMMARY: all 3 checks passed`.

## Notes
- Warning backtraces are switched off during runs: their stack lines
  carry line numbers, which any edit shifts.
- `recomputeEvents` currently errors, so events are checked through
  `regressionProcessRun` and `regressionEventsCheck` instead.
- `addpath(genpath(pwd))` also adds this folder; every function here
  starts with `regression` so it cannot shadow a pipeline function.
- If your saved MATLAB path already contains another labTools checkout,
  call `restoredefaultpath` first, or functions can resolve to the
  wrong tree.
