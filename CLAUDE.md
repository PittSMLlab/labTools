# CLAUDE.md — labTools Repository Instructions

## Repository Overview
labTools is a MATLAB framework for biomechanics and sensorimotor
adaptation research. It provides hierarchical data containers and
processing pipelines for analyzing human gait — from raw motion
capture (C3D/Vicon Nexus) and force plate data through stride-indexed
adaptation metrics and group statistics.

## How to Run Code
No build system. All workflows are MATLAB-based:

- **Data import**: `gui/importc3d/c3d2mat` (primary entry point)
- **Study setup**: `gui/createStudy/uiCreateStudy`
- **Gait event review**: `gui/eventReview/ReviewEventsGUI`
- **Example workflows**: `example/` scripts
- **Docs**: `m2html('mfiles','labTools','htmldir','doc/html','recursive','on','globalHypertextLinks','on')`

No automated tests. Scripts in `example/` serve as manual integration
tests.

## Architecture

### Data Pipeline
```
Raw files (C3D / datalog)
  → rawTrialData         (markerData, EMGData, GRFData, beltSpeedData)
  → processedLabData     (gaitEvents, angleData, procEMGData)
  → strideData           (continuous data split into strides)
  → adaptationData       (stride-indexed parameters)
  → groupAdaptationData  (group statistics)
  → studyData            (multi-group comparisons)
```

### Post-Processing (Recompute Workflows)
After the initial `c3d2mat` run, load the saved `experimentData` MAT
file and recompute without re-parsing C3D files:

- `recomputeEvents` — redetects gait events only
- `recomputeParameters` — recomputes parameters from existing processed
  data, optionally for a subset of parameter classes; `eventClass` must
  match the original processing run (different eventClass → different
  stride count → error; use `flushAndRecomputeParameters` instead)
- `flushAndRecomputeParameters` — discards existing parameters and
  recomputes all from scratch; use when changing `eventClass`

**Important:** `experimentData` is a value class — recompute methods
return a modified copy. Capture the return value:
`expData = expData.recomputeParameters()`

### Class Hierarchy

**Data containers** (`classes/dataStructs/`):
- `experimentData` — session container; `metaData`, `subData`, `data`
  (cell array of labData). Value class.
- `adaptationData` — stride-indexed params; key methods: `removeBias`,
  `getParamInCond`, `getEarlyLateData_v2`, `getEpochData`,
  `addNewParameter`, `removeBadStrides`, `plotAvgTimeCourse`
- `groupAdaptationData` / `studyData` — group/study-level analysis

**Time series** (`classes/labTS/`):
- `labTimeSeries` — extends `timeseries`; uniform sampling, label access
- `orientedLabTimeSeries` — 3D vector data; adds `orientationInfo`
- `parameterSeries` — one scalar per stride, from `calcParameters`
- `processedEMGTimeSeries` — filtered EMG with envelopes

**Synergy analysis** (`classes/synergies/`):
`Synergy` → `SynergySet` → `SynergySetCollection` →
`ClusteredSynergySetCollection`

### Key Patterns

- **Label-based access**: Time series channels are identified by string
  labels (e.g., `'LANKx'`, `'LANKy'`, `'LANKz'`), not numeric indices.
- **Stride as the unit of analysis**: `strideData` splits continuous
  trials; `parameterSeries` stores one scalar per stride.
- **Classes vs. functions**: Classes handle data containers; domain
  algorithms live as plain functions in `fun/`; GUIs handle I/O.

### `fun/` Subdirectory Guide

| Directory | Purpose |
|---|---|
| `parameterCalculation/` | Stride-level biomechanical parameters |
| `eventExtraction/` | Gait event detection (HS, TO) |
| `biomechAnalysis/` | COM/COP, joint torques |
| `EMGanalysis/` | EMG filtering and envelope extraction |
| `plotting/` | Visualization utilities |
| `+dataMotion/`, `+Hreflex/`, `+utils/` | Namespace packages |
| `ext/` | BTK (unmodified); pitools and markerDataCleaning (first-party) |

Code in `fun/ext/pitools/` and `fun/ext/markerDataCleaning/` is
maintained as first-party labTools code — update and reformat to
conform to labTools code style as needed. Unlike `fun/ext/BTK/`, these
files do not track an external upstream.

### Key Functions

#### `getEvents` (called from `labData.process`)
Detects heel-strike (HS) and toe-off (TO) gait events; packages them
into a sparse `labTimeSeries` with 12–15 labeled columns. Strategy
depends on trial type:
- **OG / NIM trials** — limb angles (`getEventsFromAngles`)
- **TM trials with GRF data** — vertical forces (`getEventsFromForces`);
  kinematic events also computed and stored for diagnostics
- **TM trials without GRF data** — toe/heel markers
  (`getEventsFromToeAndHeel`)

Output always contains `LHS`, `RHS`, `LTO`, `RTO` (primary events for
`calcParameters`), plus `forceLHS/RHS/LTO/RTO` and
`kinLHS/RHS/LTO/RTO` (diagnostic copies).

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
      │              ├── computeTemporalParameters
      │              ├── computeSpatialParameters
      │              ├── computeEMGParameters
      │              ├── computeForceParameters
      │              ├── computeHreflexParameters
      │              └── computePercParameters
      ├── appendEMGNormParameters
      ├── populateNewParamBackToExpData
      ├── [save *expData.mat]
      └── experimentData.makeDataObj  % [save *params.mat]

% Post-processing:
experimentData.recomputeEvents
experimentData.recomputeParameters     → calcParameters
experimentData.flushAndRecomputeParameters → labData.process
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
  function body. Multiline validators indent to align with the argument:
  ```matlab
  options.Colors (:,3) double ...
      {mustBeInRange(options.Colors, 0, 1)} = []
  ```
- camelCase for function files, PascalCase for scripts. Do not rename
  existing files. Choose descriptive variable names; abbreviations are
  acceptable when unambiguous (`tbl`, `fig`, `lme`, `pval`).
- Do not use `i` or `j` as loop indices (reserved for imaginary unit).
  For stride loops use `st`; for generic enumeration use `ii`, `jj`,
  `kk`. Preferred short names: `mscl` (muscles), `mrkr` (markers),
  `lbl` (labels), `tr` (trials), `con` (conditions), `fp` (force
  plates), `ch` (channels). Never use `iMuscle`-style names.
- Do not indent the base level of code inside functions
- Align `=` within a group of closely related assignments:
  ```matlab
  minSpacing  = max(1, round(options.MinSpacing));
  optimizeFor = upper(options.OptimizeFor);
  maxEvals    = round(options.MaxEvals);
  ```
- Write `0.5` not `.5`
- Use `mean(x, 'omitnan')` not `nanmean(x)` (similarly for `median`,
  `std`, `sum`). For `min`/`max`: `min(x, [], 'omitnan')`.
- Define unexplained numeric literals as named constants with an
  end-of-line comment giving their source or rationale:
  ```matlab
  gravityAcc    = 9.81;  % gravitational acceleration (m/s^2)
  impactWinFrac = 0.15;  % first 15% of stance (protocol spec)
  ```
  The `aux` label/description block is exempt from this rule.

## Documentation Comments
Every function requires a standard doc block after the definition line.

**H1 line** — immediately after `function`, no space between `%` and
the function name; name in ALL CAPS:
```matlab
%MYFUNCTION Compute stride-by-stride parameters from GRF data.
```

**Description** — one blank comment line after H1, then paragraphs
with first line indented three spaces, continuation lines one space:
```matlab
%
%   First sentence of description.
% Continuation line uses one space after %.
```

**Inputs / Outputs**:
```matlab
% Inputs:
%   argName - description
%
% Outputs:
%   out - description
```

**Toolbox Dependencies** — list required toolboxes; `None` if only
core MATLAB.

**See Also** — ALL CAPS for clickable hyperlinks:
```matlab
% See also RELATEDFUNCTION, ANOTHERFUNCTION.
```

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
