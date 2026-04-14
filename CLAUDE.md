# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Is

**labTools** is a MATLAB framework for biomechanics and sensorimotor adaptation research. It provides hierarchical data containers and processing pipelines for analyzing human gait — from raw motion capture and force plate data through to stride-indexed adaptation metrics and group statistics.

## How to Run Code

There is no build system. All workflows are MATLAB-based:

- **Documentation generation**: Run from MATLAB with m2html on the path:
  ```matlab
  m2html('mfiles','labTools', 'htmldir','doc/html', 'recursive','on', 'globalHypertextLinks','on')
  ```
- **Example workflows**: See `example/` scripts (e.g., `exRecomputeParams.m`, `labTSmanipulation.m`)
- **Data import**: Use the `gui/importc3d/` GUI (`c3d2mat`) to convert motion capture `.c3d` files
- **Study setup**: Use `gui/createStudy/uiCreateStudy` to initialize experiment metadata
- **Gait event review**: Use `gui/eventReview/ReviewEventsGUI`

There are no automated tests. Validation scripts like `testMarkerHealthCheck.m` in `example/` serve as manual integration tests.

## Architecture

### Data Pipeline

```
Raw files (c3d/datalog)
  → rawTrialData         (per-trial: markerData, EMGData, GRFData, beltSpeedData)
  → processedLabData     (adds gaitEvents, angleData, procEMGData via experimentData.process())
  → strideData           (continuous data split into strides)
  → adaptationData       (stride-indexed parameters via parameterCalculation/)
  → groupAdaptationData  (group statistics)
  → studyData            (multi-group comparisons)
```

Gait event detection is in `fun/eventExtraction/` and is called by `experimentData.process()`. Parameter computation lives in `fun/parameterCalculation/` and is invoked by `experimentData.makeDataObj()` or `recomputeParameters()`.

### Class Hierarchy

**Data containers** (in `classes/dataStructs/`):
- `experimentData` — top-level session container; holds `metaData` (experimentMetaData), `subData` (subjectData), and `data` (cell array of labData objects)
- `adaptationData` — stride-indexed parameters; holds `metaData`, `subData`, and a `parameterSeries`
- `groupAdaptationData` / `studyData` — group/study-level analysis

**Time series** (in `classes/labTS/`):
- `labTimeSeries` extends MATLAB's `timeseries`; enforces uniform sampling, adds label-based access
- `orientedLabTimeSeries` extends `labTimeSeries` for 3D vector data (markers, forces); adds an `orientationInfo` object and 3D transformation methods
- `parameterSeries` — stride-indexed parameter storage (one value per stride)
- `processedEMGTimeSeries` — filtered EMG with envelopes

**Synergy analysis** (in `classes/synergies/`): `Synergy` → `SynergySet` → `SynergySetCollection` → `ClusteredSynergySetCollection`

### Key Patterns

- **Label-based access**: Time series channels are identified by string labels (e.g., `'LANK_x'`, `'LANK_y'`, `'LANK_z'`), not numeric indices. Marker labels follow `BODYPART` convention; 3D components use `_x/_y/_z` suffixes.
- **Stride as the unit of analysis**: The framework is built around stride-indexed data. `strideData` objects split continuous trials; `parameterSeries` stores one scalar per stride.
- **Classes vs. functions**: Classes (in `classes/`) handle data container logic. Domain algorithms live as plain functions in `fun/`. GUIs handle I/O.
- **Composition**: Data containers hold time series objects; e.g., `rawTrialData` composes `orientedLabTimeSeries` for markers and forces.
- **Backward compatibility**: Classes use `loadobj` to handle deprecated or renamed fields when loading older `.mat` files.

### `fun/` Subdirectory Guide

| Directory | Purpose |
|---|---|
| `parameterCalculation/` | Stride-level biomechanical parameters (force, EMG, angle, COM, harmonic ratio, H-reflex) |
| `eventExtraction/` | Gait event detection (heel strike, toe-off) from forces or angles |
| `biomechAnalysis/` | Center of mass/pressure, joint torques |
| `EMGanalysis/` | EMG signal filtering and envelope extraction |
| `plotting/` | Visualization utilities and figure styling |
| `eventReview/` | Event validation helpers |
| `+dataMotion/`, `+Hreflex/`, `+utils/` | MATLAB namespace packages for specialized domains |
