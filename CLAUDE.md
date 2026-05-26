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
- `flushAndRecomputeParameters` — full reprocessing from existing data

**Important:** `experimentData` is a value class — always capture the
return value: `expData = expData.recomputeParameters()`

### Key Classes
- `experimentData` — session container (value class); `metaData`,
  `subData`, `data` (cell array of `labData`)
- `adaptationData` — stride-indexed params; key methods: `removeBias`,
  `getParamInCond`, `getEarlyLateData_v2`, `getEpochData`,
  `addNewParameter`, `removeBadStrides`, `plotAvgTimeCourse`
- `groupAdaptationData` / `studyData` — group/study-level analysis
- `labTimeSeries` — time series with string-label channel access;
  extended by `orientedLabTimeSeries`, `parameterSeries`,
  `processedEMGTimeSeries`

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
- Define unexplained numeric literals as named constants with an
  end-of-line comment giving their source or rationale. The `aux`
  label/description block is exempt from this rule.
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
