# CLAUDE.md — labTools Repository Instructions

## Architecture

### Data Pipeline
`rawTrialData → processedLabData → strideData →
adaptationData → groupAdaptationData → studyData`

### Post-Processing
- `recomputeEvents` — redetects events only
- `recomputeParameters` — recomputes from existing processed data;
  `eventClass` must match the original run (use
  `flushAndRecomputeParameters` to change it)
- `flushAndRecomputeParameters` — discards and recomputes all
  parameters (`calcParameters` per trial) from existing processed data

**Important:** `experimentData` is a value class — always capture the
return value: `expData = expData.recomputeParameters()`

### Key Classes
- `experimentData` — session container (value class); `metaData`,
  `subData`, `data` (cell array of `labData`)
- `adaptationData` — stride-indexed params; key methods: `removeBias`,
  `getParamInCond`, `getEarlyLateData_v2`, `getEpochData`,
  `addNewParameter`, `removeBadStrides`, `removeHandrailStrides`,
  `removeStridesByReason`, `plotAvgTimeCourse`
- `groupAdaptationData` / `studyData` — group/study-level analysis
- `labTimeSeries` — time series with string-label channel access;
  extended by `orientedLabTimeSeries`, `parameterSeries`,
  `processedEMGTimeSeries`

### Handrail-Holding Parameters
`computeForceParameters` computes `HandrailHolding` (1/0; `NaN` with
no handrail), `HandrailForceNorm` (mean |vertical force| per stride,
body-weight normalized), and `HandrailForceN` (same, in N) from the
`GRFData` `HFz` channel (analog force-plate channel 3). Unlike the
belt-plate force parameters, they are **not** limited to `'TM'` trials
(the handrail is an independent load cell). `HandrailHolding` is
informational, never folded into `bad`/`good`; censor held strides
with the opt-in `adaptData.removeHandrailStrides()`. Threshold
rationale and channel-numbering caveat: `EXPERIMENT_SETUP.md`.

### Stride-Quality Labeling
`calcParameters` labels stride quality with `adjudicateStrideQuality`
(twice: provisionally on event/duration criteria, then again once
force parameters exist, to add `badStartStop`), using the thresholds
and reason schema of `getStrideQualityConfig` — the single source of
truth that keeps marker-based and marker-less pipelines identical.
Besides the unchanged aggregate `bad`/`good`, each stride carries one
binary column per reason, three always-false stubs (`badTurning`,
`badWalkwayBounds`, `badMarkerDropout`), and a non-destructive
`triageOutlier` flag that is never folded into `bad` (schema table in
`EXPERIMENT_SETUP.md`). Censor a reason subset with
`adaptData.removeStridesByReason({...})`; `removeBadStrides` and
`removeHandrailStrides` wrap it. Manual `ReviewEventsGUI` Label
Bad/Good edits live only in the aggregate `bad`/`good` columns —
include `'bad'` in the reason list to honor them.

**Important:** every reason column plus `triageOutlier` (and
`HandrailHolding`) must stay on the protected-label list inside
`removeBias`/`removeBiasV2`/`removeBiasV3`/`removeBiasV4` (built from
`getStrideQualityConfig().reasonLabels`), or bias removal silently
subtracts a baseline mean from these binary flags.


`loadSubject` runs `detectFlippedLegs` right after building
`adaptData` (before saving `expData.mat`/`params.mat`) and, if a flip
is detected, prompts the user to auto-correct (`info.promptFlip`,
default `true`, disables the prompt for batch/headless imports). The
entire check is wrapped defensively — a QC check must never abort
import. Accepting the correction calls
`experimentData.correctLegAssignment`, which flips
`subData.fastLeg` (via `subjectData.flipFastLeg`) and every trial's
`metaData.refLeg`, then calls `flushAndRecomputeParameters` (not
`recomputeParameters` — swapping `refLeg` changes which heel strike
starts each stride, which can shift the stride count by ±1 and would
trip `recomputeParameters`'s stride-count check). For stroke
subjects, `affectedSide` (the clinical paretic side) is **never**
auto-flipped — only the fast/slow belt label is corrected.

### H-Reflex Parameters
`computeHreflexParameters` always returns the same fixed 66-label
set, so labels match across trials and participants
(`parameterSeries.addStrides` otherwise NaN-pads with a warning):
- An unrecorded SOL/MG/LG channel (e.g., no MG in SpinalAdapt) is
  NaN-filled with a `Hreflex:missingMuscleChannel` warning, never
  dropped.
- The stim artifact is localized per leg in the first recorded of
  TAP, TA, TAD. Look channels up with `isaLabel`, never a bare
  `getDataAsVector`: its regex fallback makes `'RTA'` also match
  `RTAP`/`RTAD`.
- Sessions that record the `Stimulator_Trigger_Sync_*` channels
  without stimulating: `Hreflex.hasStimTrigger` is `false` when every
  sample of every `HreflexPin` column stays below `threshStim`
  (2.5 V) — a strict superset of the rising-edge detector,
  name-agnostic on purpose (`loadTrials` matches only the prefix) —
  and the full NaN set is returned.

`calcParameters` wraps the call in `try`/`catch`, so a remaining
failure (e.g., no TA channel on either leg) warns per trial instead
of aborting import, which also hides a class-wide failure: check
every trial's warnings, not just that the import completed.

### SpinalAdapt Bout Splitting
For `ExpDescription` `'SpinalAdapt'` (matched exactly: it is a prefix
of the older `'SpinalAdaptation'`/`'SpinalAdaptBoutStudy'`, and the
legacy `contains(..., 'SpinalAdaptation')` test that still routes the
2024 study to `SepCondsInExpByAudioCue` never matched it),
`loadSubject` ends with `splitSpinalAdaptBoutConds`: each bout trial
becomes one trial and condition per bout segment (`'Adapt 1 Ramp01'`,
`'Adapt 1 SS01'`, …), windowed by the datlog cues
(`getSpinalAdaptBoutSegments`: ramp cue → `Mid`/`Split` →
`Rest##_CountForward`) shifted by `dataLogTimeOffsetBest`. Strides
are **partitioned by `initTime`, not recomputed** — recomputing the
short pieces loses the stride at each cut and flags each piece's last
stride `badMissingEvent`. Never run `recomputeParameters`/
`flushAndRecomputeParameters`/`correctLegAssignment` on the split
`<ID>.mat`: recompute `<ID>OriginalCondName.mat` (the unsplit copy)
and split again. Split sessions exceed 99 trials, so `calcParameters`
reads the `trial` column from all trailing digits of
`rawDataFilename` (`_SplitIdx###`). See `EXPERIMENT_SETUP.md`.

### Full Call Chain

```
c3d2mat
 ├── GetInfoGUI
 └── loadSubject
      ├── determineRefLeg
      ├── getTrialMetaData
      ├── loadTrials               % Load C3D into rawTrialData
      │    ├── btkReadAcquisition  % BTK (external)
      │    ├── processGRFData      % GRF loading and offset calibration
      │    ├── syncEMGData         % EMG inter-PC synchronization
      │    └── rawTrialData(...)
      ├── SyncDatalog
      ├── experimentData(...)      % [save *RAW.mat]
      ├── experimentData.process
      │    └── labData.process     % per trial
      │         ├── processEMG
      │         ├── calcLimbAngles
      │         ├── getEvents
      │         ├── getBeltSpeedsFromFootMarkers
      │         ├── computeTorques / computeCOPAlt
      │         ├── processedTrialData(...)
      │         └── calcParameters
      │              ├── adjudicateStrideQuality  % bad/good + reasons
      │              │    └── getStrideQualityConfig
      │              ├── flagTriageOutliers     % non-destructive triage
      │              ├── computeTemporalParameters
      │              ├── computeSpatialParameters
      │              ├── computeEMGParameters
      │              ├── computeForceParameters
      │              ├── computeHreflexParameters
      │              │    └── hasStimTrigger  % trigger-present guard
      │              └── computePercParameters
      ├── appendEMGNormParameters
      ├── populateNewParamBackToExpData
      ├── [save *expData.mat]
      ├── experimentData.makeDataObj  % [save *params.mat]
      ├── splitSpinalAdaptBoutConds   % 'SpinalAdapt' only; see above
      │    └── getSpinalAdaptBoutSegments  % datlog cue windows
      └── SepCondsInExpByAudioCue     % legacy, 'SpinalAdaptation' only

% Post-processing:
experimentData.recomputeEvents
experimentData.recomputeParameters     → calcParameters
experimentData.flushAndRecomputeParameters → calcParameters (all)
```

---

## MATLAB Version Compatibility
All code must be compatible with MATLAB R2021a through the current
release.

## Code Style Requirements
- Wrap lines at 76 characters
- Use spaces around `=` and binary comparison operators
- No brackets around a single output: `out = func()` not `[out] = func()`
- Suffix no-argument method calls with `()`: `obj.method()` not
  `obj.method`
- Use an `arguments` block when it meaningfully constrains input type/
  size or replaces a `nargin` check with a declared default. Place it
  immediately after the documentation comment. Default values must be
  compile-time constants — compute argument-dependent defaults in the
  function body. Multiline validators indent to align with the argument
  name (see CONTRIBUTING.md for full examples).
- camelCase for function files, PascalCase for scripts. Do not rename
  existing files. Choose descriptive variable names; abbreviations are
  acceptable when unambiguous (`tbl`, `fig`, `lme`, `pval`).
- Do not use `i` or `j` as loop indices (reserved for imaginary unit).
  For stride loops use `st`; for generic enumeration use `ii`, `jj`,
  `kk`. Preferred short names: `mscl` (muscles), `mrkr` (markers),
  `lbl` (labels), `tr` (trials), `con` (conditions), `fp` (force
  plates), `ch` (channels). Never use `iMuscle`-style names.
- Do not indent the base level of code inside functions
- Align `=` within a group of closely related assignments
- Write `0.5` not `.5`
- Use `mean(x, 'omitnan')` not `nanmean(x)` (similarly for `median`,
  `std`, `sum`). For `min`/`max`: `min(x, [], 'omitnan')`.
- Define unexplained numeric literals as named constants (camelCase)
  with an end-of-line comment giving their source or rationale. The
  `aux` label/description block is exempt from this rule.
- Prefer `fullfile(...)` over string concatenation with `filesep`:
  `fullfile(dir, 'file.mat')` not `[dir filesep 'file.mat']`

## Documentation Comments
Every function requires a standard doc block after the definition line.

**H1 line** — immediately after `function`, no space between `%` and
the function name; name in ALL CAPS:
```matlab
%MYFUNCTION Compute stride-by-stride parameters from GRF data.
```

**Description** — one blank comment line after H1; first line indented
three spaces, continuation lines one space.

**Inputs / Outputs** — use separate `% Inputs:` and `% Outputs:`
headers; list each argument as `%   argName - description`; blank
comment line between the two headers.

**Toolbox Dependencies** — list required toolboxes; `None` if only
core MATLAB.

**See Also** — ALL CAPS for clickable hyperlinks:
`% See also RELATEDFUNCTION, ANOTHERFUNCTION.`

### GUI Code (GUIDE-Generated Files)
GUIDE-generated GUI files (e.g., `GetInfoGUI.m`, `ReviewEventsGUI.m`,
`PlotParamsGUI.m`, `uiCreateStudy.m`) are exempt from:
- The `end` keyword after each function definition (GUIDE omits it).
- H1 comment format for auto-generated stub callbacks (empty
  `_Callback` / `_CreateFcn` bodies with no logic).
- The 76-character line limit inside `% Begin/End initialization
  code - DO NOT EDIT` blocks.

All other style rules apply, including:
- Loop variables: no `i`/`j`; use `ii`, `jj`, or named vars
  (`con`, `tr`, `gg` for groups).
- Property strings: PascalCase (`'Enable'`, `'String'`, `'Value'`,
  `'BackgroundColor'`, `'ForegroundColor'`); value strings also
  PascalCase (`'On'`, `'Off'`, `'White'`, etc.). MATLAB is
  case-insensitive for property values — this is a style convention.
- Spaces around `=` and after `,`.
- Full doc blocks on all meaningful callbacks (`OpeningFcn`,
  `OutputFcn`, and any callback containing substantive logic).

## Code Organization
- Use `%%` section headers for all named logical phases; header text
  names the phase, not the code.
- Separate sections with a single blank line before `%%`. Separate
  logically distinct statement groups within a section with a blank
  line.
- In `aux` label/description blocks, keep each entry on one line
  regardless of length (exempt from the 76-character rule).

### Writing Comments
**Write a comment when:** starting a new `%%` section; a non-obvious
algorithm needs a block summary; a line encodes a domain rule or
formula; a magic number needs a source; a decision could have gone
another way. **Omit** when identifiers already make the purpose clear.

Special prefixes: `% TODO:` for known incomplete work; `% NOTE:` for
important caveats or non-obvious constraints.

When editing existing files, preserve: step-labeling comments,
WHY comments, commented-out alternative code, and end-of-line
clarifications (units, roles). Remove only comments that restate what
identifiers already make obvious.
