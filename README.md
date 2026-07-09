# labTools

A MATLAB framework for biomechanics and sensorimotor adaptation
research developed by the [Sensorimotor Learning (SML) Laboratory][sml]
at the University of Pittsburgh. labTools provides hierarchical data
containers and processing pipelines for analyzing human gait — from raw
motion capture (Vicon Nexus C3D files) and force plate recordings
through stride-indexed adaptation metrics and group statistics.

[sml]: https://www.engineering.pitt.edu/subsites/Labs/sml/

---

## Table of Contents

1. [Requirements](#requirements)
2. [Getting Started](#getting-started)
3. [Third-Party Libraries](#third-party-libraries)
4. [Repository Layout](#repository-layout)
5. [Data Pipeline Overview](#data-pipeline-overview)
6. [Key Classes](#key-classes)
7. [Working with Your Data](#working-with-your-data)
8. [GUI Tools](#gui-tools)
9. [Example Scripts](#example-scripts)
10. [Generating Documentation](#generating-documentation)
11. [Reporting Bugs](#reporting-bugs)
12. [Development](#development)

---

## Requirements

- **MATLAB R2021a or later** (tested through current release)
- [Biomechanics Toolkit (BTK)][btk] — required to read `.c3d` files
- A Vicon Nexus motion capture system is assumed for data collection,
  but the processing pipeline can be adapted to other sources

[btk]: https://biomechanical-toolkit.github.io/

---

## Getting Started

1. Clone or download this repository and add it to your MATLAB path:

   ```matlab
   addpath(genpath('/path/to/labTools'));
   ```

2. Install BTK and add it to your MATLAB path as well.

3. To import a motion capture session, run:

   ```matlab
   c3d2mat
   ```

   A GUI (`GetInfoGUI`) will open and prompt you for participant
   demographics, experiment metadata, C3D file locations,
   trial/condition assignments, and EMG channel labels.

4. After the import completes you will find three `.mat` files in your
   output directory:
   - `*RAW.mat` — raw trial data (`experimentData` object,
     pre-processing)
   - `*.mat` — processed trial data (`experimentData` object,
     with gait events and stride parameters)
   - `*params.mat` — stride-indexed adaptation metrics
     (`adaptationData` object)

To add a new experiment type to the GetInfoGUI dropdown, or to update
the Vicon marker label mappings, see
[EXPERIMENT_SETUP.md](EXPERIMENT_SETUP.md).

---

## External Libraries

labTools includes several external libraries in `fun/ext/`. No submodule
initialization is needed — a plain `git clone` is sufficient to get a
fully functional copy of the repository.

| Library | Path | License | Purpose |
|---|---|---|---|
| [BTK][btk] | `fun/ext/BTK/` | LGPLv3 | C3D file I/O |
| [pi-tools][pitools] | `fun/ext/pitools/` | GPL v2 | Signal processing, utilities |
| [markerDataCleaning][mdc] | `fun/ext/markerDataCleaning/` | See ATTRIBUTION | Marker outlier detection |

BTK is included unmodified. The pi-tools and markerDataCleaning
functions were originally authored by members of the SML Laboratory and
are maintained as part of labTools; they may diverge from the original
repositories over time. The ATTRIBUTION files record the upstream commit
hashes at the time of initial incorporation. See
`fun/ext/pitools/LICENSE` for the pi-tools GPL v2 license.

[pitools]: https://github.com/pabloi/pi-tools
[mdc]: https://github.com/pabloi/markerDataCleaning

---

## Repository Layout

```
labTools/
├── classes/
│   ├── dataStructs/       % High-level data containers
│   │   ├── @experimentData/
│   │   ├── @adaptationData/
│   │   ├── @groupAdaptationData/
│   │   └── @studyData/
│   ├── labTS/             % Time series classes
│   │   ├── @labTimeSeries/
│   │   ├── @orientedLabTimeSeries/
│   │   ├── @parameterSeries/
│   │   └── @processedEMGTimeSeries/
│   └── synergies/         % EMG synergy analysis classes
├── fun/
│   ├── parameterCalculation/  % Stride-level biomechanical parameters
│   ├── eventExtraction/       % Heel-strike / toe-off detection
│   ├── biomechAnalysis/       % COM, COP, joint torques
│   ├── EMGanalysis/           % EMG filtering and envelope extraction
│   ├── plotting/              % Visualization utilities
│   ├── eventReview/           % Event validation helpers
│   ├── +dataMotion/           % Namespace: marker/segment utilities
│   ├── +Hreflex/              % Namespace: H-reflex analysis
│   ├── +utils/                % Namespace: general utilities
│   └── ext/                   % Vendored third-party libraries (BTK, pitools, etc.)
├── gui/
│   ├── importc3d/             % c3d2mat and GetInfoGUI (primary entry point)
│   ├── createStudy/           % uiCreateStudy — experiment setup
│   └── eventReview/           % ReviewEventsGUI — event validation; PlotParamsGUI — parameter plotting
├── ExpDetails/                % Experiment description files (auto-populate GUI)
├── example/                   % Example and validation scripts
└── doc/                       % Generated HTML documentation (via m2html)
```

---

## Data Pipeline Overview

```
Raw files (C3D / datalog)
  └─► rawTrialData         per-trial: markers, EMG, GRF, belt speed, H-reflex
        └─► processedLabData   adds gait events, limb angles, processed EMG
              └─► strideData         continuous data split into strides
                    └─► adaptationData     stride-indexed parameters
                          └─► groupAdaptationData  group statistics
                                └─► studyData      multi-group comparisons
```

The pipeline is orchestrated by `c3d2mat` → `loadSubject` →
`experimentData.process()`. After the initial run, you can reload the
saved `*.mat` and recompute without re-parsing C3D files:

| Method | What it does |
|---|---|
| `recomputeEvents` | Re-detects gait events only |
| `recomputeParameters` | Recomputes parameters from existing processed data |
| `flushAndRecomputeParameters` | Full reprocessing from already-loaded data |

`experimentData` is a value class — always capture the return:
`expData = expData.recomputeParameters()`

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

## Key Classes

### `experimentData`
Top-level session container. Holds experiment metadata, subject data,
and an array of `labData` trial objects. Provides `process()`,
`recomputeEvents()`, `recomputeParameters()`, and `makeDataObj()`.

### `adaptationData`
Stride-indexed parameter storage. Key methods:

- `removeBias` / `removeBiasV4` — baseline subtraction by trial type
- `getParamInCond`, `getParamInTrial` — parameter retrieval
- `getEarlyLateData_v2`, `getEpochData` — epoch extraction
- `addNewParameter`, `removeBadStrides`, `removeHandrailStrides` —
  data manipulation
- Static plotting: `plotAvgTimeCourse`, `plotGroupedSubjectsBars`,
  `createGroupAdaptData`

### `groupAdaptationData` / `studyData`
Group- and study-level aggregation and statistics.

### `labTimeSeries` / `orientedLabTimeSeries`
Time series containers extending MATLAB's `timeseries`. Channels are
identified by string labels (e.g., `'LANKx'`, `'LANKy'`) rather than
numeric indices. `orientedLabTimeSeries` adds 3D transformation
support for marker and force data.

### `parameterSeries`
Stride-indexed parameter storage (one scalar value per stride),
produced by `calcParameters`.

---

## Working with Your Data

### Gait Event Detection
Event detection strategy depends on trial type:
- **OG / NIM trials** — limb angles (`getEventsFromAngles`)
- **TM trials with GRF** — vertical forces (`getEventsFromForces`);
  kinematic events are also stored for diagnostics
- **TM trials without GRF** — toe/heel marker kinematics
  (`getEventsFromToeAndHeel`)

Use `gui/eventReview/ReviewEventsGUI` to visually inspect and correct
detected events.

### Stride-Level Parameters
`calcParameters` computes temporal, spatial, EMG, force, H-reflex,
and perceptual parameters for each stride. Force parameters
(`computeForceParameters`) include ~45 labels covering AP braking and
propulsion, bilateral symmetry, impulse, vertical and mediolateral
peaks, treadmill incline angle, and handrail holding (`HandrailHolding`
binary flag + `HandrailForceNorm`/`HandrailForceN` continuous values,
computed from an instrumented handrail's vertical force channel when
present — see
[EXPERIMENT_SETUP.md](EXPERIMENT_SETUP.md#instrumented-handrail-optional)).
`HandrailHolding` is informational by default; opt into censoring held
strides with `adaptData.removeHandrailStrides()`.

### EMG Analysis
Raw EMG is processed through amplitude extraction and optional spike
removal. EMG normalization parameters are appended automatically when
normalization data are present. Synergy analysis is available through
the classes in `classes/synergies/`.

### Group Analysis
Use `adaptationData.createGroupAdaptData` to aggregate across
participants, then `groupAdaptationData` and `studyData` for
group-level statistics and plotting.

### Recompute Workflows

After the initial import, reload the saved `*.mat` and recompute
without re-parsing C3D files. The three recompute methods are
summarized in [Data Pipeline Overview](#data-pipeline-overview).

`recomputeParameters` accepts optional arguments to narrow scope:

- **Single parameter class** — pass a class name string as the first
  argument: `expData.recomputeParameters('force')`
- **Multiple parameter classes** — pass a cell array as the third
  argument with `[]` placeholders for the first two:
  `expData.recomputeParameters([], [], {'force', 'spatial'})`
- **Initial-step leg** — pass `'L'` or `'R'` as the second argument
  to control which leg's step is counted first. By default the fast
  leg's step falls after the slow leg's step. Passing `'L'` treats the
  left leg as the initial step: `expData.recomputeParameters([], 'L')`.
  Note this is not the reverse of the default — if left steps are
  odd-numbered and right even-numbered, the default computes
  R(2)−L(1) and R(4)−L(3), while `'L'` computes L(3)−R(2) and
  L(5)−R(4).

See `example/TestPipelineRecompute.m` for a regression-testing
template and [TESTING.md](TESTING.md) for a full test matrix.

---

## GUI Tools

labTools provides four graphical tools that cover the full workflow
from data import through group-level plotting. All are GUIDE-based
MATLAB GUIs and require no additional toolboxes.

### `GetInfoGUI` / `c3d2mat` — Session Import

Covered in [Getting Started](#getting-started) step 3. Prompts for
participant demographics, data file locations, trial/condition
assignments, and EMG channel labels. The experiment-description
dropdown is auto-populated from `.mat` files in
`gui/importc3d/ExpDetails/`. To define a new experiment type, use the
`Template.m` script in that directory — see
[EXPERIMENT_SETUP.md](EXPERIMENT_SETUP.md) for the full workflow.

### `ReviewEventsGUI` — Gait Event Review and Stride Labeling

**Purpose:** Visually inspect detected gait events, correct errors,
and mark individual strides as bad or good before computing final
stride-level parameters.

**Launch:**
```matlab
ReviewEventsGUI
```

**Workflow:**
1. Click the **Open** toolbar icon and select a `*.mat` file.
2. Choose a condition from the **Condition** drop-down, then choose a
   trial from the **Trial** drop-down.
3. Select a data channel for the **top** and **bottom** plot panels
   from the respective drop-down menus.
4. Use the radio buttons to switch between default, force, and
   kinematic event classes (enabled only when both force and kinematic
   events are present in the file).
5. Correct events:
   - **Delete** — click a point in the plot, then press **Delete** to
     remove the nearest event.
   - **Delete Range** — press **Delete Range**, click two points to
     define a window, and all events within it are removed.
   - **Add** — press **Add**, then click a point to insert a new event
     of the type selected in the event-type panel.
6. Label strides:
   - Click on a stride in the plot to select it, then press **Label
     Bad** or **Label Good**.
7. Press **Mark Save** when finished reviewing a trial, then **Write
   to Disk** to save the corrected `*.mat` and regenerate
   `*params.mat`.

### `uiCreateStudy` — Study Assembly

**Purpose:** Scan a directory for `*params.mat` files, assign
participants to named groups, and save the resulting `studyData`
object for group-level analysis.

**Launch:**
```matlab
cd('/path/to/params/files')
uiCreateStudy
```

**Workflow:**
1. The **All Subjects** list is populated automatically from every
   `*params.mat` file in the current directory.
2. Select one or more files in **All Subjects** and click **Add** to
   move them to the **Selected Subjects** list.
3. Type a group name in the **Group Name** field, then click **Add
   Group**. Repeat for each group.
4. Click **Save** and choose an output filename. The saved `.mat` file
   contains a `studyData` struct with one field per group.

### `PlotParamsGUI` — Parameter Plotting

**Purpose:** Load a `studyData` file and generate publication-quality
plots (time course, early/late bars, scatter, epoch bars, correlation)
interactively without writing MATLAB scripts.

**Launch:**
```matlab
PlotParamsGUI
```

**Workflow:**
1. Click the **Open** toolbar icon and select a `studyData` `.mat`
   file.
2. Choose a **plot type** using the radio buttons (Time Course, Early
   Late Bars, Scatter, Epoch Bars, Correlation).
3. Select one or more **groups** from the Group list, and optionally
   select individual subjects from the Subject list.
4. Select one or more **parameters** from the Parameter list
   (double-click a parameter for a description).
5. Select the **conditions** and/or **epochs** to include.
6. Adjust optional settings: bin width, bias-removal baseline,
   color order.
7. Click **Plot**.

The **Print Code** checkbox echoes the equivalent programmatic call
to the Command Window for reproducibility and scripting.

---

## Example Scripts

The `example/` directory contains working scripts that serve as both
usage examples and manual integration tests:

| Script | Purpose |
|---|---|
| `TestPipelineRecompute.m` | Regression-test recompute pipelines |
| `EMGNormalization.m` | Normalize EMG parameters to baseline |
| `LabTSManipulation.m` | Demonstrate `labTimeSeries` operations |
| `TSDiscretizationAndCheckerboards.m` | Discretize/align time series; plot checkerboards |
| `PlotIndividualsInGroup.m` | Plot individual behavior within a group |
| `PlotParameterTimeCourseWithFilters.m` | Parameter time courses with monotonic LS filter |
| `TestMarkerHealthCheck.m` | Validate marker data integrity |
| `TestMarkerOutlierDetectAndCorrect.m` | Detect and correct marker outliers |
| `HowToUsePlottingFunc.mlx` | Interactive live script for plotting functions |

---

## Generating Documentation

[m2html][m2html] generates browsable HTML from MATLAB doc comments.

**Prerequisites:** Download m2html from its [GitHub repository][m2html]
and add it to your MATLAB path.

**Standard update** — increments existing HTML for changed or new
files without removing pages for deleted functions:

1. Change directory to the **parent folder** of labTools:
   ```matlab
   cd('/path/to/parent')   % labTools is a subdirectory here
   ```

2. Run m2html:
   ```matlab
   m2html('mfiles', 'labTools', 'htmldir', 'labTools/doc', ...
       'recursive', 'on', 'globalHypertextLinks', 'on')
   ```

HTML is written to `doc/` inside your labTools directory.

**Full rebuild** — removes stale pages for functions that no longer
exist. Use this when the repository structure has changed
significantly. The `doc/` directory is fully auto-generated and safe
to delete:

1. Delete the `doc/` folder:
   ```matlab
   rmdir('labTools/doc', 's')
   ```

2. Run m2html (same command as above).

**Checking your m2html version:** run `which m2html` in MATLAB to
find your installed copy, check its header for a version date, and
compare against the latest commit on the [m2html GitHub repo][m2html].

[m2html]: https://github.com/gllmflndn/m2html

---

## Reporting Bugs

To help us reproduce and fix a bug as quickly as possible, please open
a [GitHub issue][issues] and include all of the following:

1. **Steps to reproduce** — a clear, numbered sequence of actions that
   another person on a different computer can follow to observe the
   same behavior.
2. **Expected behavior** — describe what the code should do.
3. **Actual behavior** — describe what the code actually does,
   including any error messages or warnings printed to the MATLAB
   Command Window (copy the full text, not just the last line).
4. **MATLAB version and OS** — output of `version` and your operating
   system (e.g., Windows 11, macOS 14).
5. **labTools version** — the Git commit hash (`git rev-parse HEAD`)
   or the tag/branch you are using.
6. **Screenshots or figures** — attach any plots or Command Window
   screenshots that illustrate the problem.
7. **Data** — if the bug occurs only with a specific dataset, attach
   the data file or provide a link to it on your shared server. If
   the data cannot be shared publicly, note that in the issue and a
   maintainer will contact you directly.

[issues]: https://github.com/PittSMLlab/labTools/issues

> **Tip:** The more precisely you can isolate the problem — ideally to
> a short script that triggers the error with minimal data — the faster
> it can be resolved.

---

## Development

For coding conventions, documentation standards, and architectural
guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md).
