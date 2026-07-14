# TESTING.md — labTools Regression Testing Guide

## Overview

labTools has no automated test suite. This guide describes a
regression-testing workflow based on comparing the final pipeline
output — the `*params.mat` file (an `adaptationData` object with
stride-by-stride parameters) — before and after a code change.

**Core idea:** process a reference dataset once with known-good code
and save the output as the reference `params.mat`. After any code
change, reprocess the same dataset and compare the two files with
`compareAdaptationData`. Parameters that changed beyond floating-point
noise are flagged explicitly.

---

## Prerequisites

### 1. Reference data files
Keep one short reference session (ideally < 5 trials, < 500 strides)
on a shared drive or local path. You need two files:
- `*expData.mat` — the processed `experimentData` object
- `*params.mat` — the reference `adaptationData` output

To create the reference `params.mat` from scratch:
```matlab
% Process the session using current (known-good) code:
c3d2mat           % OR: loadSubject (if *info.mat already exists)

% The *params.mat file is saved automatically by loadSubject.
% Record its path — this is your reference.
```

### 2. labTools on path
```matlab
addpath(genpath('path/to/labTools'))
```

---

## Test Matrix

Choose the test based on what code was changed:

| What changed | Command to run | Notes |
|---|---|---|
| Parameter calculation (`fun/parameterCalculation/`) | `expData.recomputeParameters()` | Fastest; recalculates from existing processed data. **eventClass must match the original run.** |
| One parameter class only (e.g., force) | `expData.recomputeParameters('force')` | Scope-limited recompute |
| Gait event detection (`fun/eventExtraction/`) | `expData.recomputeEvents()` then `expData.recomputeParameters()` | Events change → parameters change downstream |
| Raw processing, or changing eventClass | `expData.flushAndRecomputeParameters(eventClass)` | Full reprocessing; `eventClass`: `''` default, `'kin'`, or `'force'` |
| Class definitions or full pipeline logic | Re-run `loadSubject` (or `c3d2mat` if `*info.mat` is absent) | Most complete test |
| Multiple areas | Run the most comprehensive command for the deepest change | When in doubt, use `flushAndRecomputeParameters` |
| Raw data loading / channel layout | `compareExperimentData` on saved `*expData.mat` or `*RAW.mat` | Checks field presence, sizes, and label ordering without re-running the pipeline |

---

## Step-by-Step Workflow

### Step 1: Load the reference `experimentData`
```matlab
load('path/to/Sub01expData.mat', 'expData')
```

### Step 2: Run the appropriate recompute command

> **Important:** `recomputeParameters` requires that `eventClass`
> matches the original processing run. If the original run used `'kin'`
> and you call `recomputeParameters()` (default `''`), the stride count
> may differ and the function will error. Use
> `flushAndRecomputeParameters` whenever you want to change the gait
> event detection method.

```matlab
% NOTE: experimentData is a value class — you must capture the return
% value, or the recomputed parameters are silently discarded.

% Option A — parameter calculation only:
expData = expData.recomputeParameters();

% Option B — one parameter class only:
expData = expData.recomputeParameters('force');

% Option C — events + parameters:
expData = expData.recomputeEvents();
expData = expData.recomputeParameters();

% Option D — full flush:
expData = expData.flushAndRecomputeParameters(eventClass);
```

### Step 3: Build the new `adaptationData`
```matlab
newAdaptData = expData.makeDataObj()
% Capture the return value — pass it directly to compareAdaptationData.
% No filename argument means the object is not saved to disk; that is
% intentional for regression testing. Pass a filename string to save:
%   expData.makeDataObj('Sub01')  % saves Sub01params.mat
```

### Step 4: Compare against the reference
```matlab
compareAdaptationData( ...
    'path/to/reference/Sub01params.mat', ...
    newAdaptData, ...
    RefName='reference', NewName='after change')
```

### Step 5: Interpret the output (see section below)

---

## Interpreting `compareAdaptationData` Output

```
TRIALS
  Reference : [1 2 3 4 5]
  New       : [1 2 3 4 5]
  Common: 5  |  Ref-only: 0  |  New-only: 0
```
- Ref-only or New-only trials indicate a processing scope difference,
  not a parameter change. Only common trials are compared.

```
PARAMETER LABELS
  Common: 43  |  Ref-only: 0  |  New-only: 2
  New-only labels: harmonicRatio_AP, harmonicRatio_ML
```
- New-only labels are new parameters added in this change — expected
  when adding a feature.
- Ref-only labels indicate parameters that were removed or renamed.

```
STRIDE ALIGNMENT
  Matched pairs   : 2431
  Unmatched (ref) : 0  |  Unmatched (new): 0
```
- Unmatched strides arise when gait event detection changed, producing
  different stride boundaries. A small number is often acceptable;
  a large number warrants investigation.

```
PARAMETER DIFFERENCES  (RelTol=1e-9, AbsTol=1e-12)
  Unchanged  : 41
  Roundoff   :  0
  Changed    :  2
  ---
  stepLengthAsym     relDiff=3.41e-04  absDiff=1.20e-03  NaN=0
  strideTime         relDiff=2.10e-05  absDiff=4.01e-05  NaN=0
```

**Classification:**
- **Unchanged** — values are identical (within floating-point noise).
- **Roundoff only** — non-zero differences but below `RelTol=1e-9`.
  Expected when harmless refactoring touches intermediate
  floating-point operations.
- **Changed** — differences exceed tolerance. Investigate whether
  this is intentional (new feature or bug fix) or a regression.
- **NaN > 0** — strides where one object has NaN and the other does
  not. Indicates a change in bad-stride detection logic.

### Adjusting tolerance
For loose comparisons (e.g., after platform migration):
```matlab
compareAdaptationData(ref, new, RelTol=1e-6)
```
For tighter checks:
```matlab
compareAdaptationData(ref, new, RelTol=1e-12, AbsTol=1e-15)
```

---

## Structural Comparison with `compareExperimentData`

Use `compareExperimentData` when a code change may have altered the
channel layout, field presence, or data dimensions of `rawTrialData`
or `processedTrialData` objects — for example after refactoring raw
data loading (`loadTrials`, `processGRFData`, `syncEMGData`) or EMG
processing (`processEMG`).

Unlike `compareAdaptationData`, this function does **not** compare
numerical values. It checks structural properties only:
- Which data fields are present (e.g., `EMGData`, `GRFData`, `accData`)
- The size of each field's data matrix
- The channel label list (order-sensitive — reordered labels are flagged)
- Whether the trial data type changed (e.g., `rawLabData` →
  `processedLabData`)

### Reference file

The reference is a saved `*expData.mat` or `*RAW.mat` produced from
a known-good run. Load either directly from a file path or pass an
object already in the workspace.

### Step-by-Step

```matlab
% Step 1 — produce a new expData without saving it:
loadSubject('path/to/session/Sub01info.mat')
% OR: run c3d2mat, then intercept the expData object before it is saved

% Step 2 — compare against the reference file:
report = compareExperimentData( ...
    'path/to/reference/Sub01expData.mat', ...
    newExpData, ...
    RefName='reference', NewName='after change')
```

### Interpreting the output

```
TRIALS
  Reference : 5 trials
  New       : 5 trials
  Common: 5  |  Ref-only: 0  |  New-only: 0

FIELD STRUCTURE  (5 common trials)
  All trials: no structural differences.

SUMMARY: 0 of 5 common trials have structural differences.
```

If structural differences are found, the report lists them per trial:

```
FIELD STRUCTURE  (5 common trials)
  Trial 3:
    EMGData                labels differ  ref-only: LMGA  new-only: RMGA
    accData                absent in new
```

- **absent in reference / absent in new** — field was added or removed.
- **size:** — data matrix dimensions changed (e.g., different number of
  samples or channels).
- **labels differ** — channel names changed. `ref-only` and `new-only`
  show which labels are unique to each object; `(same set, different
  order)` means the channels are identical but reordered.

The `report` struct mirrors the printed output and can be inspected
programmatically (e.g., `report.trials(3).fields`).

---

## Skipping the GUI When `*info.mat` Exists

If the `GetInfoGUI` dialog has already been completed for the
reference session, the `*info.mat` file is saved in the session
folder. You can skip the GUI and run the loader directly:
```matlab
% Equivalent to the non-GUI portion of c3d2mat:
loadSubject('path/to/session/Sub01info.mat')
```
This saves substantial time during iterative testing.

---

## Test Data Recommendations

- **Size** — keep the reference session short (< 5 trials, < 500
  strides). The comparison runs in seconds; a full c3d2mat run on
  a minimal session takes 1–2 minutes.
- **Coverage** — choose a session that includes TM, OG, and
  adaptation trials so that all parameter classes (temporal, spatial,
  force, EMG if applicable) are exercised.
- **Storage** — store reference files outside the repo (they can be
  large). Note the path in a shared lab document.
- **Updating the reference** — after an intentional, validated change,
  regenerate the reference `params.mat` using the new code and record
  the regeneration date.

---

## Testing Handrail-Holding Parameters

`example/data/LI16_Trial9_expData.mat` is a `processedTrialData` object
with real instrumented-handrail channels (`HFx`/`HFy`/`HFz`) already
present in its `GRFData` — useful as a real-data fixture for testing
changes to `HandrailHolding`/`HandrailForceNorm`/`HandrailForceN`
(`computeForceParameters`) without needing your own handrail-collected
session. Note its `metaData.type` is `'IN'` (incline); handrail
computation runs regardless of trial type (see
`EXPERIMENT_SETUP.md`), so no override is needed to exercise it. The
other, belt-plate force parameters (`FyBS`/`FyPS`/etc.) will still
read `NaN` on this trial, since those remain gated to `'TM'`-type
trials — that is expected and unrelated to handrail testing.

To positively confirm the holding threshold logic (rather than relying
on whatever the reference trial's incidental handrail contact happens
to be), inject a known force segment directly into the `HFz` channel
of a copy of `GRFData` — e.g., set a 1–2 second window to a known
fraction of body weight and the rest to zero — then recompute and
verify `HandrailHolding` flips for the strides overlapping that
window, `HandrailForceNorm` matches the injected fraction, and
`HandrailForceN` matches the fraction times body weight in Newtons.
Also verify the NaN-guard: on a trial/copy with the `H*` channels
stripped, confirm `HandrailHolding`/`HandrailForceNorm`/
`HandrailForceN` are `NaN` for every stride, not `0` (`NaN > threshold`
evaluates to `false` in MATLAB, so an unguarded comparison would
silently mislabel "no data" as "not holding").

To test `removeHandrailStrides`, confirm it actually changes the
stride count on a real `adaptationData` object (value-class objects
can silently no-op if a returned copy isn't captured) and that the
default no-`HandrailHolding`-column case returns the object unchanged
with a warning rather than erroring.

---

## Testing Stride-Quality Labeling

`adjudicateStrideQuality` and `flagTriageOutliers`
(`fun/parameterCalculation/`) are pure functions — numeric/struct in,
numeric/struct out, no `parameterSeries` dependency — so they can be
unit-tested directly with synthetic arrays, without any `.mat`
fixture. This is the primary way to test them; construct an
`extendedEventTimes`/`strideDuration` matrix by hand (or perturb a
clean synthetic trial) to exercise each branch independently:
missing event, disordered events, duration outlier/short/long, TM
start/stop with and without `singleStanceSpeed` (the empty-input case
matters — it is exactly what `calcParameters`'s first, provisional
call passes), OG (no start/stop), and a triage residual injected at a
known magnitude. Assert the aggregate `bad` equals a hand-computed OR
of `cfg.defaultBadReasons`.

For an end-to-end smoke test, `example/data/LI16_Trial9_expData.mat`
(see above) also exercises the refactored `calcParameters` path:

```matlab
load('example/data/LI16_Trial9_expData.mat')
load('example/data/C0000_Params.mat')  % same subject; reuse its subData
out = calcParameters(LI16_Trial9_expData, adaptData.subData, ...
    '', '', {'basic', 'temporal', 'force'});
```

**Fixture gaps to be aware of:**
- This fixture is a single `'IN'`-type trial, so it does not exercise
  the `badStartStop` (treadmill start/stop) branch — cover that with
  a synthetic TM case instead.
- Requesting `'spatial'` on this fixture currently throws inside
  `computeSpatialParameters` → `getKinematicData` →
  `extractKinematicDataAtEvents` (a pre-existing marker-data issue on
  this specific trial, unrelated to and untouched by the stride-
  quality-labeling change — confirm with `git log`/`git status` on
  those files before assuming otherwise). Since `triageOutlier` needs
  spatial parameters, test it with synthetic `paramValues` via
  `flagTriageOutliers` directly instead of through this fixture.
- `example/data/C0000_Params.mat` predates the reason-column schema
  (it was generated by the pre-refactor `calcParameters`), so its
  `adaptData.data` has only `bad`/`good`, not the per-reason columns.
  It is still useful for testing `removeBadStrides`,
  `removeHandrailStrides` (confirms the `noHandrailData` no-op path,
  since this subject has no handrail column), and `removeBias*`'s
  updated protected-label list. To test `removeStridesByReason`
  against real per-reason data, first `recomputeParameters()` a
  session, or build a minimal synthetic `parameterSeries` (see the
  next paragraph).

To validate `removeStridesByReason` mechanics precisely (which
strides get removed/NaN'd for a given reason subset), build a small
synthetic `parameterSeries` with hand-assigned reason columns —
reuse any real `adaptationData`'s `metaData`/`subData` to construct
the wrapping object (`adaptationData(metaData, subData, paramData)`),
since only the `data` needs to be synthetic. Confirm: (1)
`removeBadStrides()` matches `removeStridesByReason({'bad'})`
exactly; (2) `removeHandrailStrides()` matches
`removeStridesByReason({'bad', 'HandrailHolding'})` exactly; (3) a
narrow reason subset removes strictly fewer strides than
`removeBadStrides()` whenever some strides are `bad` for a
*different*, non-selected reason; (4) an unknown reason label warns
(`adaptationData:noStrideQualityReason`) and no-ops rather than
erroring; (5) the `markAsNaNflag=true` path NaN's only the strides
matching the requested subset, leaving strides that are `bad` for
other reasons untouched.

When changing anything in `getStrideQualityConfig` (thresholds or the
reason list), also re-run the `removeBias`/`removeBiasV2`/
`removeBiasV3`/`removeBiasV4` protected-label check: confirm the
`bad`/`good`/reason/`triageOutlier`/`HandrailHolding` columns come out
of `removeBias()` byte-identical to their pre-bias-removal values —
a column left off the protected list would otherwise have a baseline
mean silently subtracted from it.

**Stage A regression check (behavior preservation):** since
`adjudicateStrideQuality`'s aggregate `bad` is designed to reproduce
the pre-refactor five-criteria formula exactly, confirm this with a
real before/after comparison rather than code review alone: `git
stash push -- fun/parameterCalculation/calcParameters.m` to
temporarily restore the pre-refactor file (this does not affect the
new, untracked `adjudicateStrideQuality.m`/`getStrideQualityConfig.m`/
`flagTriageOutliers.m`, since the old `calcParameters.m` never calls
them), run `calcParameters` and save the `bad` column, `git stash
pop`, re-run, and diff the two `bad` vectors element-wise with
`isequal`.

---

## See Also

- `fun/misc/compareAdaptationData.m` — parameter value comparison
- `fun/misc/compareExperimentData.m` — structural comparison
- `example/TestPipelineRecompute.m` — template script
- `fun/parameterCalculation/getStrideQualityConfig.m` — stride-quality
  thresholds and reason schema (single source of truth)
- `fun/parameterCalculation/adjudicateStrideQuality.m` — per-reason and
  aggregate stride-quality adjudication (pure function)
- `fun/parameterCalculation/flagTriageOutliers.m` — non-destructive
  outlier triage flag (pure function)
- `classes/dataStructs/@adaptationData/removeStridesByReason.m` —
  reason-subset stride censoring
- `CLAUDE.md` — repository architecture overview
