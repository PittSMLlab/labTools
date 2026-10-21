# Pipeline Features

Behavior, usage, and test recipes for the optional and study-specific
features of the parameter pipeline. For the general regression
workflow, see [TESTING.md](TESTING.md).

1. [Instrumented Handrail](#instrumented-handrail)
2. [Stride-Quality Labeling](#stride-quality-labeling)
3. [H-Reflex Parameters](#h-reflex-parameters)
4. [SpinalAdapt Bout Splitting](#spinaladapt-bout-splitting)

---

## Instrumented Handrail

If the treadmill handrail has a force transducer wired into the C3D
analog channels, `processGRFData` labels it `HFx`/`HFy`/`HFz`
(+ moments `HMx`/`HMy`/`HMz`) inside `GRFData`. No GetInfoGUI setting
is involved; the C3D analog channel layout alone decides it.

### Parameters

`computeForceParameters` computes three stride-level parameters from
the vertical handrail channel (`HFz`):

- **`HandrailHolding`** — `1` if the mean absolute vertical handrail
  force over the stride exceeds 5% body weight (BW), `0` otherwise,
  `NaN` if the trial has no handrail channel.
- **`HandrailForceNorm`** — that mean absolute vertical force,
  normalized to BW (the value `HandrailHolding` thresholds).
- **`HandrailForceN`** — the same force in Newtons.

Unlike the belt-plate force parameters (`FyBS`/`FyPS`/etc.), which
are computed only for `'TM'` trials, the handrail parameters are
computed for any trial type: the handrail is an independent load
cell. They depend only on `HFz` being present and stride events being
valid; otherwise all three stay `NaN`. `abs()` counts both pushing
down (weight support) and pulling up (balance recovery) as holding.

**Threshold:** 5% BW is the "light touch" ceiling of the
instrumented-handrail literature (Buffum et al., *Treadmill
Handrail-use Increases the Anteroposterior Margin of Stability in
Individuals Post-stroke*, PMC10957321; light-touch forces there were
~1–2% BW), so `>5% BW` means "more than light touch." Change
`handrailHoldFractionBW` in `computeForceParameters.m` for a stricter
definition. Brown & Kesar (IEEE TNSRE, 2019; PMID 31425041) show why
handrail use matters for adaptation studies.

**Only `HFz` is used**, which assumes a handrail alongside the
treadmill (as in the cited literature). For a handrail in front of
the participant, or if holding shows up mainly in `HFy`, consider the
`HFy`+`HFz` magnitude (see the legacy `computeForceParameters_OGFP.m`).

**Channel numbering:** `processGRFData` maps analog force channel
**3** to the `H` prefix; some collections and legacy loaders assume
channel **4** (see the warning text and `fpPrefixMap` in
`processGRFData.m`). If all three parameters are `NaN` for a session
that had a handrail, check which channel the load cell was wired to.
Some older collections label the channel `X`; `computeForceParameters`
then falls back to `XFz` with a warning.

### Censoring Held Strides

`HandrailHolding` is informational; strides are not excluded
automatically:

```matlab
% Remove held strides (ORed with the existing 'bad' column):
adaptData = adaptData.removeHandrailStrides();

% Or NaN them instead of removing rows:
adaptData = adaptData.removeHandrailStrides(true);
```

If `HandrailHolding` is absent or all `NaN`, the object is returned
unchanged with a warning.

### Testing

`example/data/LI16_Trial9_expData.mat` is a `processedTrialData` with
real `HFx`/`HFy`/`HFz` channels in its `GRFData`. Its type is `'IN'`,
so the handrail parameters are computed while the `'TM'`-only
belt-plate parameters read `NaN` (expected).

- **Threshold:** in a copy of `GRFData`, set a 1–2 s window of `HFz`
  to a known fraction of BW and the rest to zero; recompute and check
  that `HandrailHolding` flips for the overlapping strides,
  `HandrailForceNorm` equals the fraction, and `HandrailForceN` equals
  the fraction times BW in N.
- **NaN guard:** with the `H*` channels stripped, all three
  parameters must be `NaN`, not `0` (`NaN > threshold` is `false`, so
  an unguarded comparison would read "no data" as "not holding").
- **`removeHandrailStrides`:** capture the return value and confirm
  the stride count changes on a real `adaptationData`; on an object
  without `HandrailHolding` (e.g., `example/data/C0000_Params.mat`) it
  must warn and return the object unchanged.

---

## Stride-Quality Labeling

`calcParameters` labels each stride through `adjudicateStrideQuality`,
using the thresholds and reason schema in `getStrideQualityConfig`.
That config is the single source of truth for marker-based and
marker-less pipelines alike (same reasons, thresholds, and
aggregation). Change a threshold there (e.g., a shorter
`maxStrideDur` for a pediatric population), not in a local override.

### Reason Schema

| Reason column        | Meaning                                                        | Folded into `bad`? |
|-----------------------|-----------------------------------------------------------------|:---:|
| `badMissingEvent`     | Any gait event time (SHS/FTO/FHS/STO/SHS2/FTO2) is `NaN`        | Yes |
| `badDisordered`       | Consecutive event times are out of order (negative diff)        | Yes |
| `badDurationOutlier`  | Stride duration > `durationMedianFactor` (1.5) × trial median   | Yes |
| `badDurationShort`    | Stride duration < `minStrideDur` (0.4 s)                        | Yes |
| `badDurationLong`     | Stride duration > `maxStrideDur` (2.5 s)                        | Yes |
| `badStartStop`        | Both legs' single-stance speed < `startStopSpeedMmS` (50 mm/s); treadmill trials only | Yes |
| `HandrailHolding`     | Handrail held (see [above](#instrumented-handrail)); computed by `computeForceParameters` | No (opt-in) |
| `badTurning`          | STUB — always `false`. Intended for substantial within-stride heading change. | No |
| `badWalkwayBounds`    | STUB — always `false`. Intended for strides ending outside the walkway extent (OG). | No |
| `badMarkerDropout`    | STUB — always `false`. Intended for marker dropout affecting a stride. | No |
| `triageOutlier`       | Non-destructive: 3-stride moving-median residual flagged at a robust (MAD-based) threshold, for **review only** | No, never |

The stubs keep the reason set identical across datasets before their
detectors exist; the `TODO` comments in `adjudicateStrideQuality.m`
name the intended sources (`direction` for turning,
`validateMarkerModel`'s `outOfBoundsOutlier` for walkway bounds,
`markerData.assessMissing`/`findOutliers` for dropout).

The aggregate `bad` is the OR of `cfg.defaultBadReasons`
(`badMissingEvent`, `badDisordered`, `badDurationOutlier`,
`badDurationShort`, `badDurationLong`, `badStartStop`); `good` is its
complement.

### Censoring by Reason Subset

```matlab
% Remove strides flagged for missing or disordered events only:
adaptData = adaptData.removeStridesByReason( ...
    {'badMissingEvent', 'badDisordered'});

% Or NaN them instead of removing rows:
adaptData = adaptData.removeStridesByReason( ...
    {'badMissingEvent', 'badDisordered'}, true);
```

`removeBadStrides()` and `removeHandrailStrides()` wrap
`removeStridesByReason` with `{'bad'}` and `{'bad', 'HandrailHolding'}`.

- After a subset call, the returned `bad`/`good` reflect only that
  subset: a stride kept by `{'badMissingEvent'}` reads `good` even if
  it is a `badDurationOutlier`. Pass the full list (or use
  `removeBadStrides()`) when chaining calls.
- `ReviewEventsGUI` **Label Bad**/**Label Good** edits only the
  aggregate `bad`/`good` columns. To honor them in a subset censor,
  include `'bad'` in the reason list.

### Outlier Triage

`triageOutlier` flags candidate outliers for human review and never
censors: it is not ORed into `bad` and not used by
`removeBadStrides`/`removeHandrailStrides`. Per stride, it takes the
residual from a 3-stride moving median and flags it when it exceeds
`triageMadFactor` (3.5) times a MAD-based scale, for each parameter
in `cfg.triageParams` (`stepLengthSlow`, `stepLengthFast`,
`alphaSlow`, `alphaFast`, `alphaTemp`, `betaSlow`, `betaFast`). It
stays `false` when spatial parameters were not computed.

### Testing

`adjudicateStrideQuality` and `flagTriageOutliers` are pure functions
(numeric/struct in and out), so test them with synthetic arrays:
build `extendedEventTimes`/`strideDuration` by hand to hit each
branch — missing event, disordered events, duration
outlier/short/long, TM start/stop with and without
`singleStanceSpeed` (empty is what the provisional first call in
`calcParameters` passes), OG (no start/stop), and a triage residual of
known size. Assert `bad` equals a hand-computed OR of
`cfg.defaultBadReasons`.

End-to-end smoke test on the LI16 fixture (212 strides; two "Could
not compute OG force parameters" warnings are expected):

```matlab
load('example/data/LI16_Trial9_expData.mat')
load('example/data/C0000_Params.mat')  % same subject; reuse its subData
out = calcParameters(LI16_Trial9_expData, adaptData.subData, ...
    '', '', {'basic', 'temporal', 'force'});
```

Fixture gaps:
- LI16 is one `'IN'` trial, so `badStartStop` needs a synthetic TM
  case.
- Requesting `'spatial'` on LI16 throws in
  `extractKinematicDataAtEvents` (via `computeSpatialParameters` →
  `getKinematicData`). Test `triageOutlier`, which needs spatial
  parameters, through `flagTriageOutliers` with synthetic
  `paramValues`.
- `C0000_Params.mat` has only `bad`/`good` (no reason columns, no
  `HandrailHolding`). Use it for `removeBadStrides`, the
  `removeHandrailStrides` no-op path, and the `removeBias*`
  protected-label list; for real reason columns, recompute a session
  first.

To check `removeStridesByReason`, wrap a small synthetic
`parameterSeries` with hand-set reason columns in a real object's
`metaData`/`subData` (`adaptationData(metaData, subData, paramData)`)
and confirm:
1. `removeBadStrides()` equals `removeStridesByReason({'bad'})`.
2. `removeHandrailStrides()` equals
   `removeStridesByReason({'bad', 'HandrailHolding'})`.
3. A narrow subset removes fewer strides than `removeBadStrides()`
   when some strides are `bad` only for non-selected reasons.
4. An unknown reason warns (`adaptationData:noStrideQualityReason`)
   and no-ops.
5. `markAsNaNflag = true` NaNs only strides in the requested subset.

After changing `getStrideQualityConfig`, check that `removeBias`,
`removeBiasV2`, `removeBiasV3`, and `removeBiasV4` leave the
`bad`/`good`/reason/`triageOutlier`/`HandrailHolding` columns
byte-identical; a column missing from the protected list gets a
baseline mean subtracted.

---

## H-Reflex Parameters

`computeHreflexParameters` always returns the same 66 labels, so
labels match across trials and participants:

- A missing SOL/MG/LG channel (e.g., no MG in SpinalAdapt) is
  NaN-filled with a `Hreflex:missingMuscleChannel` warning, never
  dropped.
- The stim artifact is located per leg in the first recorded of TAP,
  TA, TAD. Channels are looked up with `isaLabel`, because
  `getDataAsVector`'s regex fallback makes `'RTA'` also match
  `RTAP`/`RTAD`.
- `Hreflex.hasStimTrigger` is `false` when no sample of any
  `HreflexPin` column exceeds 2.5 V (sessions that record the trigger
  channels without stimulating); the full NaN set is returned.

`calcParameters` wraps the call in `try`/`catch`, so a failure (e.g.,
no TA channel on either leg) warns per trial instead of aborting
import. Check every trial's warnings, not just that import finished.

### Testing

`testing/TestHreflexStimTriggerGuard.m` tests the trigger guard and
both `computeHreflexParameters` paths on synthetic data;
`testing/ValidateHreflexGuardOnServer.m` checks a real session (it
saves a timestamped baseline, see
[DATA_OUTPUTS.md](DATA_OUTPUTS.md#5-plotting-examples-tools)).

---

## SpinalAdapt Bout Splitting

For `ExpDescription` `'SpinalAdapt'` (exact match), `loadSubject`
splits each bout trial into one condition per segment
(`'<Condition> Ramp01'`, `'<Condition> SS01'`, ...) from its datlog
cues (Vicon time = cue time + `dataLogTimeOffsetBest`); trials
without ramp cues stay whole.

| Segment | Opens at | Closes at |
|---|---|---|
| Ramp | ramp cue (`AccRamp##`/`DccRamp2Split##`); bout 1: pre-loop `Mid01` | the `Mid##`/`Split##` row after it |
| SS | that `Mid##`/`Split##` row | `Rest##_CountForward` (fallbacks: `Rest##`, trial end) |

Standing intervals belong to no condition, and the spoken "stop" has
no datlog row. Strides keep their whole-trial parameters and go to the
segment containing their `initTime`: 2–3 ramp and 9–13 SS strides per
bout (the extras are `bad` stopping strides). A flipped-leg check
exists only as an unmerged stash; until it is merged, nothing checks
the leg assignment before the split.

**Never recompute the split `<ID>.mat`** (recomputing the short pieces
loses the stride at each cut). Recompute the unsplit copy
`<ID>OriginalCondName.mat`, then split again:

```matlab
load('SAYA91OriginalCondName.mat', 'expData');
expData = expData.flushAndRecomputeParameters();  % + EMG-norm args
expData = splitSpinalAdaptBoutConds(expData);
save('SAYA91.mat', 'expData', '-v7.3');
adaptData = expData.makeDataObj('SAYA91');        % SAYA91params.mat
```

### Testing

`testing/TestSpinalAdaptBoutSegments.m` tests the cue parser on
synthetic datlogs. `testing/ValidateSpinalAdaptBoutSplitOnServer.m`
checks real data, read-only and headless: datlogs alone (Part A,
before import), `params.mat` (Part B), and optionally the real
splitter on `expData.mat` (Part C). Expect `0 flag(s)`: no
zero/one-stride segment and no good stride outside every segment.
