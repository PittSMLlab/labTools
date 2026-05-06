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
  data, optionally for a subset of parameter classes
- `flushAndRecomputeParameters` — fully reprocesses all parameters

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
- Wrap lines at 76 characters (the MATLAB editor default)
- Use spaces around `=` and binary comparison operators (`~=`, `==`,
  `<`, `>`, `<=`, `>=`)
- Do not use brackets around a single output argument: write
  `out = func()` not `[out] = func()`
- Suffix no-argument method calls with `()` to distinguish them from
  property access: write `obj.method()` not `obj.method`
- A MATLAB `arguments` block is optional but often beneficial for input
  argument validation and default value setting. Use one when it
  meaningfully constrains input size or type, or replaces a `nargin`
  check with a declared default. Omit it when the overhead outweighs
  the benefit (e.g., simple one-liner helpers). When an `arguments`
  block is used, place it immediately after the documentation comment;
  declare input sizes, types, and default values there rather than
  using `nargin` checks. When adding an `arguments` block to an
  existing function, verify all callers supply the now-required
  arguments. Note that default values must be compile-time constants
  or literals — they cannot reference other input arguments; when a
  default must be computed from another input, declare the default as
  `NaN` (for numeric arguments) and compute the actual value in the
  function body. Place multiline validators on the line(s) following
  the argument name, indented to align with the argument name:
  ```matlab
  options.Colors (:,3) double ...
      {mustBeInRange(options.Colors, 0, 1)} = []
  ```
- Use camelCase for function file names and PascalCase for script
  file names (not underscore-separated). Do not rename existing files
  unless explicitly instructed — file renaming can complicate git
  version history. Use camelCase or PascalCase for variable names.
  Choose names that make their purpose clear without a comment —
  prefer `participantCount` over `n`, `knotLocations` over `kl`.
  Abbreviations are acceptable when they are unambiguous in context
  (e.g., `tbl`, `fig`, `lme`, `pval`).
- Do not use `i` or `j` as loop index variables (reserved for the
  imaginary unit in MATLAB). For stride loops use `st`; for generic
  enumeration use `ii`, `jj`, or `kk`. When iterating over a named
  collection and a terse abbreviation adds unambiguous clarity, prefer
  it over `ii`: `mscl` (muscles), `mrkr` (markers), `lbl` (labels),
  `fld` (fields), `tr` (trials), `con` (conditions), `fp` (force
  plates), `fi` (files), `stp` (steps), `lg` (legs), `sd` (sides),
  `ord` (order), `ch` (channels), `stat` (statistics), `hrm`
  (harmonics). Use `ii` when no short name adds clarity or when a
  terse name would introduce ambiguity. Never use verbose `i`-prefix
  names (e.g., `iMuscle`, `iMarker`) — these conflict with the
  imaginary-unit prohibition.
- Do not indent the base level of code inside functions, as the MATLAB
  IDE autoformatter removes this indentation
- Align `=` signs within a group of closely related assignments to make
  differences between variable names visually apparent:
  ```matlab
  minSpacing  = max(1, round(options.MinSpacing));
  optimizeFor = upper(options.OptimizeFor);
  maxEvals    = round(options.MaxEvals);
  ```
  Apply this within a logical group; do not force alignment across
  unrelated statements separated by blank lines.
- Write decimal numbers with an explicit leading zero: use `0.5`
  not `.5`.
- Use modern NaN-omitting aggregation functions rather than the
  deprecated `nan*` family: write `mean(x, 'omitnan')` instead of
  `nanmean(x)`, and equivalently for `median`, `std`, and `sum`.
  For `min` and `max`, the `'omitnan'` flag requires an explicit
  empty placeholder for the second argument:
  `min(x, [], 'omitnan')` / `max(x, [], 'omitnan')`. Writing
  `min(x, 'omitnan')` invokes the element-wise two-array form and
  returns an array, not a scalar.
- Define unexplained numeric literals as named constants at the top of
  the function (or at the top of the `%%` section where they are first
  used). Give each a descriptive name and add an end-of-line comment
  documenting the value's source or rationale (e.g., anthropometric
  table, protocol specification, or empirical threshold):
  ```matlab
  shoeWeightKg  = 3.4;   % Nimbus shoe pair mass (two shoes; update if shoes change)
  gravityAcc    = 9.81;  % gravitational acceleration (m/s^2)
  impactWinFrac = 0.15;  % first 15% of stance (protocol spec)
  ```
  The label/description `aux` block (and dynamically constructed
  description strings that populate it) are exempt from this rule.

## Documentation Comments
Every function requires a standard doc block after the definition line.

**H1 line** — the first comment line, on the line immediately after
`function`. No space between `%` and the function name; the name is
in ALL CAPS, followed by a brief one-line description. This is the
only place in a comment block where there is no space after `%`:
```matlab
%MYFUNCTION Compute stride-by-stride parameters from GRF data.
```

**Description** — follows the H1 line with exactly one blank comment
line (`%`) between them. No section header. Use paragraph
indentation: the first line of each paragraph is indented three
spaces after `%`; all continuation lines in the same paragraph use
one space after `%`:
```matlab
%
%   First sentence of description, indented.
% Continuation lines use one space after %.
%
%   A second paragraph, again indented on its first line.
% Continuation lines use one space here too.
```

**Inputs / Outputs** — labeled section headers (`% Inputs:`,
`% Outputs:`), with each argument indented three spaces:
```matlab
% Inputs:
%   argName - description
%
% Outputs:
%   out - description
```

**Examples** (optional) — include after Outputs when it would
clarify how the function is used within the labTools pipeline.

**Toolbox Dependencies** — list required toolboxes; `None` if only
core MATLAB.

**See Also** — ALL CAPS for clickable hyperlinks:
```matlab
% See also RELATEDFUNCTION, ANOTHERFUNCTION.
```

Do not include a `Syntax` section — it redundantly restates the
function definition and adds no information.

## Code Organization
- Use `%%` section headers to divide every script and function into
  named logical phases. The header text should name the phase, not
  describe the code:
  ```matlab
  %% Validate Input Arguments
  %% Fit Zero-Knot Linear Mixed-Effects Model (ML)
  %% Prepare Output Data Structure
  ```
- Separate sections with a single blank line before the `%%` header.
  Separate logically distinct groups of statements within a section
  with a single blank line.
- Maintain consistent whitespace and indentation throughout.
- In the 'Labels and Descriptions' `aux` block found in parameter
  computation functions, keep each parameter name and its description
  on a single line regardless of length — this block is exempt from
  the 76-character line-wrap rule

### Writing Comments
Write comments to help a future reader understand purposes and
decisions not obvious from the code itself.

**Write a comment when:**
- Starting a new `%%` section — make the header descriptive.
- A group of statements implements a non-obvious algorithm — add a
  short block comment summarizing what it does and why.
- A single line encodes a domain-specific rule or formula — add an
  end-of-line comment explaining its meaning.
- A value is a magic number whose meaning would not be obvious to
  a reader unfamiliar with the study protocol.
- A decision could reasonably have been made differently — explain
  why this choice was made.

**Omit a comment when** the identifier names already make the purpose
completely clear, or the comment would merely restate the code in
English.

**Special prefixes:**
- `% TODO:` — known incomplete work or a known limitation to
  revisit later.
- `% NOTE:` — an important caveat, subtle invariant, or
  non-obvious constraint that future editors must not accidentally
  remove.

### Comment Preservation
When editing existing files, preserve: step-labeling comments (navigation
aids for multi-step algorithms), WHY comments (non-obvious decisions or
constraints), commented-out code (alternative implementations or
work-in-progress), and end-of-line clarifications (units, roles, or
non-obvious behavior). Remove only comments that redundantly restate what
the adjacent code already makes obvious from its identifier names alone.
