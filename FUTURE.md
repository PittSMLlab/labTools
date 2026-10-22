# Future Work

Improvements found during the 2026-10 clean-up that were out of its
scope. Each section is sorted by value, then by effort. Nothing here is
scheduled. Files and functions may or may not be deleted; that decision
is made with [DEAD_FILES.md](DEAD_FILES.md) and
[COMMENTED_CODE.md](COMMENTED_CODE.md).

**Effort:** S = under a day, M = a few days, L = a week or more.
**Value:** what the lab gains. **Risk:** chance that the change alters
existing results or breaks callers (High = changes published
parameters or saved files, so it needs a before/after comparison per
[TESTING.md](TESTING.md) and lab sign-off).

## Contents
1. [Data Safety (Output Overwrites)](#1-data-safety-output-overwrites)
2. [Core Pipeline Bugs](#2-core-pipeline-bugs)
3. [Parameter Definitions (Lab Decision)](#3-parameter-definitions-lab-decision)
4. [Testing and CI](#4-testing-and-ci)
5. [Pending Lab Decisions](#5-pending-lab-decisions)
6. [Repository and Install](#6-repository-and-install)
7. [Analysis, Plotting and GUI Bugs](#7-analysis-plotting-and-gui-bugs)
8. [Rarely Used Code (Synergies, Markers, Biofeedback)](#8-rarely-used-code-synergies-markers-biofeedback)
9. [Code Quality](#9-code-quality)
10. [Lessons for Future Refactors](#10-lessons-for-future-refactors)

## Top 10
| # | Item | Section | Effort | Value | Risk |
|---|---|---|---|---|---|
| 1 | Guard `<ID>RAW.mat` against silent overwrite (O-1) | 1 | S | High | Low |
| 2 | Guard `copyfile` onto `<ID>OriginalCondName*.mat` (O-3) | 1 | S | High | Low |
| 3 | Fix `recomputeEvents` | 2 | M | High | Medium |
| 4 | `groupAdaptationData` `hiddenID` and `getAllParameters` bugs | 2 | S | High | Medium |
| 5 | Decide the flipped-leg stash (`stash@{1}`) | 5 | M | High | Medium |
| 6 | `.gitattributes` and CRLF renormalization | 6 | S | Medium | Low |
| 7 | Small `experimentData` fixture (< 100 MB) | 4 | M | High | Low |
| 8 | `matlab.unittest` suite from the `testing/` scripts | 4 | L | High | Low |
| 9 | CI running `codeIssues` on R2021a and the current release | 4 | M | Medium | Low |
| 10 | Ship or document the Windows BTK `.mexw64` | 6 | S | Medium | Low |

## 1. Data Safety (Output Overwrites)
Write sites and current overwrite behavior: [DATA_OUTPUTS.md](DATA_OUTPUTS.md).
Update that file in the same commit as any change below. A
`loadSubject` change needs a C3D session for the before/after check.

| ID | Item | Effort | Value | Risk |
|---|---|---|---|---|
| O-1 | `loadSubject` and `reviseExperimentInfo` overwrite `<ID>RAW.mat` silently. Add an `isfile` guard (error), or copy the old file to `<ID>RAW_<timestamp>.mat` first. Affects `c3d2mat`, every re-import and the TESTING.md reference runs. | S | High | Low |
| O-3 | `saveSplitBoutFiles` (in `loadSubject`) and `SepCondsInExpByAudioCue` `copyfile` onto `<ID>OriginalCondName*.mat` unguarded: a second run replaces the unsplit backup, the only source for recomputing a split session, with split data. Guard each `copyfile` with `~isfile(dest)`. | S | High | Low |
| O-2 | `ReviewEventsGUI.write_Callback` overwrites `<filename>.mat` and the params file with no backup of manually edited events. Add one `copyfile(f, [f '.bak'])` before the first write of a session. | S | High | Low |
| O-4 | `autoRenameDatlog` copies `*` into `datlog-original`, then renames in place; a re-run copies the renamed files over the backup. It is also called once per trial with a missing datlog, so one import can copy the folder several times. Skip the copy when `datlog-original` exists (caller: `getTrialMetaData`). | S | Medium | Low |
| O-7 | Bug: `PlotHelper` (~L411-412) saves `f` under the `Diagnostic` name instead of `fDiagnostic`, so the diagnostic figure is never written. | S | Medium | Low |
| O-9 | Cancelled dialogs error: `uiCreateStudy` (`uiputfile` returns `0`; add `if isequal(file, 0), return, end`) and `PlotParamsGUI` Save colors (empty `inputdlg` result; add `if isempty(answer), return, end`). | S | Low | Low |
| O-5 | `DetermineOptimalReconstructAndLabelParams` rewrites the Nexus pipeline XML in place (`fopen 'w'`); write a copy or back the file up once. | S | Medium | Low |
| O-6 | `processAndFillMarkerGapsSession` calls `vicon.SaveTrial`, replacing the Vicon trial in place; optional `.c3d` backup (lab decision). | S | Medium | Low |
| O-10 | Consistency: `-v7.3` missing on the `GetInfoGUI` info save, `updateParams` and `AddPythonData`; `ReviewEventsGUI`, `SepCondsInExpByAudioCue` (first save; it also omits the separator in `<ID>Separated.mat`) and `updateParams` concatenate paths instead of `fullfile`; the `loadSubject` diary appends across re-runs; figures are saved two different ways (`saveas` vs `saveFig`); `*params.mat` is written by `makeDataObj` in most places but by bare `save` in `changeCondName`, `AddPythonData`, `SyncPython_forStatic`. | M | Medium | Low |
| O-8 | pwd-dependent saves (`changeCondName`, `AddPythonData`, `SyncPython_forStatic`, Biofeedback `saveit`, `EMG_traces_example`, the `example/` `saveFig(..., './', ...)` calls, `moveParamFilesHere`): add a `saveDir` argument that defaults to `pwd`. | M | Low | Low |
| O-11 | Biofeedback `saveit` uses `eval([subjectcode '=this;'])`, which breaks for a subject code that is not a valid variable name. Saving under a fixed variable name changes the saved variable name (needs approval). | S | Low | Medium |

## 2. Core Pipeline Bugs
Import, events, parameters and the adaptation/group classes.

| Item | Effort | Value | Risk |
|---|---|---|---|
| `recomputeEvents` errors: pass `perceptualFlag` to `getEvents` and define `processedData`/`subData`/`eventClass` in `@processedLabData/recomputeEvents.m`; honor the ignored `eventClass`/`initEventSide` arguments of `experimentData.recomputeEvents`. Removes the "currently errors" caveat from README, TESTING and CLAUDE.md. | M | High | Medium |
| `groupAdaptationData` constructor assigns `hiddenID = groupID` to a local variable, so `groupID` is ignored. `getAllParameters` indexes `adaptData{s}` (loop counter) instead of `adaptData{subs(s)}`, so it can read the wrong subjects; `getCommonParameters` builds its warning with an invalid index. | S | High | Medium |
| `getEventsFromAngles`: the dropout filter indexes `rdata` for the left events (`LeftTO(rdata(LeftTO) == 0)`); `ldata` is probably meant. Changes events for affected sessions. | S | High | High |
| `adaptationData.removeBaselineEpoch` computes `baseData` but never applies it (the subtraction is commented out), so it equals `removeBias` plus restoring the protected columns. | S | High | High |
| `getEarlyLateIdxs`: `Ne`/`Nf` defaults are computed but `exemptLast`/`exemptFirst` are used, so omitting them errors; `case 2` is unreachable; `names` is unset when `numberOfStrides` is empty; `length(relInds) < abs(numberOfStrides)` compares against a vector. | S | Medium | Medium |
| `loadTrials` `EMGList{k}(1:4)` (~L196) errors for unrecognized channel names shorter than 4 characters (`GenerateHreflexRecruitmentCurves` uses `strncmpi` for the same test). | S | Medium | Low |
| `dataMotion.reconstructAndLabelTrial` is called from `interpolTraj` and `processAndFillMarkerGapsTrial`, but the only copies are in `+dataMotion/deprecated/` and `misc/OptimizedReconstructAndLabel/` (not package folders), so the call probably does not resolve. | S | Medium | Low |
| `c3d2matCLI` calls `loadInfoFile`, which does not exist, so it cannot run. | S | Medium | Low |
| `getConditionsThatMatchV2` carries a temporary R01 fallback (TM/NIM -> TR conditions) flagged TODO; confirm it is still wanted. | S | Medium | Medium |
| `computeSpatialParameters` overwrites `stepLengthSlow/Fast` and `takeOffLengthSlow/Fast` about 5 lines after assigning them (4 dead stores). | S | Low | Low |
| `strokeSubjectData.set.affectedSide` silently ignores invalid values (the `error` call is commented out). | S | Medium | Medium |
| `derivedMetaData` constructor passes `parentMeta.type` and ignores its own `type` argument; `experimentMetaData` assigns `conditionOrder` and never uses it. | S | Low | Medium |
| `SepCondsInExpByAudioCue`: `exist(...params.mat)` has no `'file'` option; prints to the command window (`condsToUpdate`, `pracNames`, `newName'`). | S | Low | Low |
| OGFP pair (`computeForceParameters_OGFP`, `_aligned`) quirks: inverted `if isempty(ImpactMagS_all)`, a variable that persists across strides, a dotted `exist` string that probably always returns 0, stance splits using the previous iteration's events, NaN from `SHS-SHS+1`. Dead `if false` COM block and empty `outCOP` stub. Needs an overground (FP4-7) session as a baseline before any change. | L | Medium | High |
| `loadSubject` and `SyncDatalog` close figures, run `clc` and `clearvars` as a memory workaround (FIXME in both); find the leak. | M | Low | Low |
| `SepCondsInExpByAudioCue` and `SyncDatalog` hard-code study logic (`SAS01V02` trial 9 cut at 180 s, TM-only sync, 0.90 correlation threshold); move it to the study configuration when the next study needs it. | M | Low | Medium |
| `findLabel` loads `markerLabelKey.mat` on every call; cache it if import time matters. `addMarkerPair` overwrites the first copy of the MAT on the path. | S | Low | Low |
| `getBeltSpeedsFromFootMarkers`: the comment says "median absolute speed" but the code takes the median of the signed heel speed (fix the comment or the code). | S | Low | Low |

## 3. Parameter Definitions (Lab Decision)
These change parameters used in published work. Ask the lab first;
each has a `TODO`/`FIXME` in the code.

| Item | Effort | Value | Risk |
|---|---|---|---|
| `computeSpatialParameters` FIXMEs (~L379, L441): `abs()` drops the sign of `velocitySlow/Fast` and `singleStanceSpeedSlow/Fast`. Remove `abs` or document why it stays. | S | High | High |
| `computeLegForceParameters` `SBmaxQS`/`SPmaxQS` factor of 2 (~L103, L113): source unknown. | S | Medium | High |
| `circCorr` assumes zero-mean inputs (no mean-centering). | S | Medium | High |
| `computeCOM` label `'COMsymZ_Norm_Rot_WHOLEmea'` is missing an `n`; renaming breaks scripts that use it. | S | Low | High |
| Constants with no recorded source: `noiseThreshold = 0.01`, `inclineAPFactor = 0.5` (`computeForceParameters`); stride bounds 0.4 s, 2.5 s, factor 1.5 (`getStrideQualityConfig`); `lowPassFilter`/`highPassFilter` stop-band factors and attenuations; hmhFun stride windows; `getEMGworksdataAcc` `lastOneDigitSensorField = 36`; `errorProofInfo` `maxYear = 3000`. All are marked `TODO: source?`. | M | Medium | Low |
| `computeTSStatParameters` SNR can divide by ~0; `computeHSParameters` catch-all NaN hides missing fast-leg events. | S | Medium | Medium |
| H-reflex `minArtifactPeak` 1 mV QC threshold: the left LTAP artifact (~0.5 mV) trips it on every SAST90 stim trial. | S | Medium | Low |

## 4. Testing and CI
| Item | Effort | Value | Risk |
|---|---|---|---|
| Store a small `experimentData` fixture (a few trials, < 100 MB) so recompute regressions run without server data ([testing/regression/](testing/regression/README.md) needs a session copy today). | M | High | Low |
| Build a `matlab.unittest` suite from the `testing/` scripts (stride quality, handrail, H-reflex, bout split) and the fixture. | L | High | Low |
| Keep an overground session (OG/NIM with FP4-7) and a C3D session as regression baselines: the 2026-10 baselines (C3S36_S1 treadmill 'kin', SAYA90 SpinalAdapt from RAW) never run the OGFP functions, `loadSubject`, `loadTrials`, `processGRFData`, `syncEMGData` or `SyncDatalog`. | M | High | Low |
| CI that runs `codeIssues` on R2021a and the current release; move lint from `checkcode` (not recommended since R2022b) to `codeIssues`. | M | Medium | Low |
| `compareAdaptationData`: optional native comparison of per-reason stride-quality columns and warning text. | S | Medium | Low |
| Give `makeDataObj` an explicit "no save" option instead of relying on an empty filename. | S | Low | Low |
| A lint rule against `nanmean`/`nanstd`/... so the `omitnan` migration cannot regress. | S | Low | Low |

## 5. Pending Lab Decisions
| Item | Effort | Value | Risk |
|---|---|---|---|
| Flipped-leg detection (`detectFlippedLegs`, `correctLegAssignment`, ...) exists only in `stash@{1}`. Merge it (needs a flipped session to verify) or drop it. | M | High | Medium |
| `stash@{0}` "pre-cleanup WIP" (6 files): `getEventsFromForces` force threshold 10 -> 60 N, `getKinematicDataAbs` walking-direction sign, `plotMultipleEpochBars`, `plotAvgTimeCourse`. The stash no longer applies to the restyled files; each change is re-expressed as a patch in [stash-patches/](stash-patches/README.md). The 60 N threshold shifts events by ~12 ms. | M | High | High |
| Zero-caller and deprecated files: [DEAD_FILES.md](DEAD_FILES.md). | M | Medium | Medium |
| Commented-out code: [COMMENTED_CODE.md](COMMENTED_CODE.md). | M | Medium | Low |
| Merge `removeBias` / `removeBiasV2`-`V4` behind one name with a shared helper. `removeBiasV2` errors on its first line; V3 has no live caller; V4 warns "...passed to removeBiasV3" and exempts 1 stride where V3 says 10. All four must keep the protected-label list (see `.claude/rules/remove-bias-protected.md`). | M | Medium | High |
| Shared helper for the OGFP pair (offset estimation, handrail, constants, output). Not safe as written: the stride loop's first iteration uses events left over from the offset loop. Needs the overground baseline (section 4). | M | Medium | High |
| Biofeedback classes (6, all zero-caller): `SL`, `SLBF_Percp`, `SL_c3d`, `VazE2B` repeat the same `AnalyzePerformance` structure; `SL_Realtime` and `SL_RealtimeAlpha` are 212 of 214 lines identical and save the same file name. Merge, archive or delete. | M | Low | Low |
| `@strideData/strideData.m` does not parse (nested `methods` block, stray `end`), so the class cannot load; `separateIntoStrides` and friends call it. Repair or remove. | M | Low | Low |
| `studyData` stubs (`anova`, `barPlot`, `getCommonConditions`, `getCommonParameters`) return `[]`; implement or remove. | S | Low | Low |
| `labTimeSeries.m` (`plot`, `plotAligned`, `bilateralPlot`) and `alignedTimeSeries.m` (`plot`) define methods inline that also exist as separate files; the inline versions win. Keep one copy. | S | Low | Low |
| `getStanceFromToeAndHeel`: `getStance2` (Hough) and `getStance3` (acceleration) are unused local functions. | S | Low | Low |
| `medianFilter`: enable the commented `medfilt1(..., 'omitnan')` now that R2021a is the minimum (changes NaN handling). | S | Low | High |
| `computeHreflexParameters` 66-row label table could be generated by a loop (~-40 lines), but the fixed label set is an invariant. GUIDE `_CreateFcn` boilerplate (134 identical bodies, ~400 lines) could become helper calls, but a GUIDE re-save reverts it. | S | Low | Medium |
| `defineEpochs` returns a `dataset` (deprecated since R2013b); a `table` version needs coordinated changes in `adaptationData`, `groupAdaptationData` and `studyData`. | L | Medium | High |
| `Nim_EMG_traces_per_Cond` and `VR_EMG_traces_per_Cond` differ only in condition names and the normalization condition; share one script. | S | Low | Low |

## 6. Repository and Install
| Item | Effort | Value | Risk |
|---|---|---|---|
| Add `.gitattributes` (`*.m text eol=crlf` or `text=auto`) and renormalize the 36 CRLF-in-index files in one isolated commit. | S | Medium | Low |
| Ship the Windows BTK `.mexw64` (now only on `Z:\Nathan\btk`) or document the install step in README. | S | Medium | Low |
| Toolbox audit with `requiredFilesAndProducts` (full depth) across the repo; list required toolboxes in README. Several doc blocks' `Toolbox Dependencies` lines came from an analyzer that missed callee use (e.g. `lowpassfiltering2` -> `butter`). | M | Medium | Low |
| Untrack the generated `doc/` HTML (793 files) and build it in CI or on demand. | S | Low | Low |

## 7. Analysis, Plotting and GUI Bugs
Left as is because fixing them changes behavior.

| Item | Effort | Value | Risk |
|---|---|---|---|
| `groupAdaptationData.plotCheckerboards`/`getCheckerboardsData` default `summFlag` is the string `'nanmean'`, `eval`'d into a call; replace with `@(x) mean(x, 'omitnan')`. | S | Medium | Low |
| `plotParamBarsByConditionsv2`: `Nf = exemptLast` where `exemptFirst` is meant. | S | Medium | Medium |
| `plotMultipleEpochBars`: `NaN(length(groups,1))` should be `NaN(length(groups),1)`; `elseif posthocEpochByGroupFlag==1 (maineff...` is probably missing `&&`. | S | Medium | Medium |
| `adaptationData.replaceLR` is an empty stub; `getBias` leaves its outputs unassigned when the object was not unbiased. | S | Low | Low |
| `matchControlsFixedGUI`: `canonicalUnits.weight` is pounds but heights/weights are converted as meters/kilograms regardless of the unit dropdowns; the tolerance label hard-codes inches; returns five matches, not two; `uidatepicker` needs a release newer than R2021a. | M | Medium | Medium |
| `PlotHelper.computeAndPlotCorrelations`/`plotCorrelations`: the `plotDiagnostic` default test reads `isempty(performKws)`, and an empty argument errors. | S | Low | Low |
| `updateParams` loads `[char(ss) '.mat']` with `ss` a loop index (`subjects{ss}` is meant). | S | Low | Low |
| `filterEMG` notch loop uses `fz` before assigning it and designs from `filterList{3}` every pass; `BW = [200,450]` is overwritten by the next line. | S | Low | Medium |
| `CalcStrides2SS_PostAdapt` falls back to an undefined `t` when no stride is below the threshold; `normalityTestWithFig` ignores `alpha`. | S | Low | Medium |
| `EMGtracesplot` is a script fragment that needs `colorOrder` and `alignmentLengths` from elsewhere; it and `plotEMGtraces` hard-code the 40-stride window and 16/32 alignment lengths. | S | Low | Low |
| `GenerateHreflexRecruitmentCurves`: the `%% Save the Data` block is commented-out `SL_Realtime` code; `refAux` (~L269-280) is computed and never used. | S | Low | Low |
| `OptimizedReconstructAndLabel`: `results` and `pathOutCSV` are never filled; `Part1RL`'s commented `pipelinePath` names the wrong step. | S | Low | Low |

## 8. Rarely Used Code (Synergies, Markers, Biofeedback)
Check whether anyone still uses these before fixing them.

| Item | Effort | Value | Risk |
|---|---|---|---|
| Synergy code calls functions not in the repo (`freezeColors`, `empiric*EigDistributions*`, `createUnstructuredParametersFromData`); confirm the external toolbox. `whitenEMG` never assigns `newSignal`; `getSynergies` never assigns `fullSyns`; `coefExtrFromSyn` calls the removed `matlabpool`. | M | Low | Low |
| `FactorizedMatrix`: `sort` reads `this.factMethod` (property is `factorizationMethod`); `percentErrorPerRow`/`percErrPerDim` pass wrong arguments; constructor `try ... catch keyboard`; `nargin < 2` defaults should be `nargin < 3`. `Synergy.plot` opens a second figure; `SynergyAnalysis.getFactorization` reads misspelled properties; `chooseDim` is not implemented. | M | Low | Low |
| `fun/ext/markerDataCleaning` calls missing functions (`updateKF`, `getRotationAndTranslation`, `getPositionFromDistances*`) and `distanceModelReferenceData.mat`; `markerModel.labelData` errors immediately and four methods are stubs. `naiveDistances.validateMarkerModel` compares a logical with 10, so its check never fires. `amp_estim` assigns `procList{2}` twice (index 4 probably meant). | M | Low | Low |
| `labTimeSeries.castAsSTS`/`spectrogram` need `spectroTimeSeries`, which is not in the repo. | S | Low | Low |
| `BiofeedbackPerception.AnalyzePerformance` sets `lhits{z}(badR) = NaN` where `badL` is meant. The Biofeedback classes are value classes whose parse cache is lost on return; they `eval` on `global ID`; `comparedays` parses a variable name from the file name by position. | S | Low | Low |
| `parameterSeries.addStrides` warning says "Ask Pablo for guidance"; `animate2` geometry has no recorded source. | S | Low | Low |

## 9. Code Quality
| Item | Effort | Value | Risk |
|---|---|---|---|
| File/function name mismatches: `getEarlyLateData_v2_.m` declares `getEarlyLateData_v2`; `dataMotion.fillSmallMarkerGapsSpline` declares `fillSmallMarkerGaps`; `skDistenforce.m` defines `skDistlearnenforce`. | S | Low | Low |
| `@orientedLabTimeSeries/orientedLabTimeSeries.m` keeps ~400 lines of old method bodies beside the separate method files (candidates in COMMENTED_CODE.md). | S | Low | Low |
| Existing UPPER_CASE constants in `fun/eventExtraction` (`ENERGY_FRAC`, `HOUGH_*`, ...) break the camelCase rule; plot-layout literals were left as literals (decide whether a layout-constants struct is worth it). | S | Low | Low |
| `getEMGworksdata`: unused `analogsInfoNexus` and `C(jj)`; `getEMGworksdataAcc` carries a stale `aux` across iterations (`exist('aux')`). | S | Low | Low |
| `setExpDescription` `iStr`, `testSkeleton` prints `fr = n` (was `i = n`): cosmetic leftovers of the loop-variable rename. | S | Low | Low |

## 10. Lessons for Future Refactors
- Edit CRLF files with Python (`newline=''`), never GNU `sed -i` (it
  strips the CR). Check with `git ls-files --eol`.
- Renaming a variable must also rename it inside `eval` strings and
  double-quoted strings (`strides{i}`, `idxList(j)`); token-diff tools
  that strip strings cannot see these. Grep string literals after every
  rename.
- `matlab.codetools.requiredFilesAndProducts` with `'toponly'` misses
  callee toolboxes and resolves class method names (`prctile`, `iqr`
  in `@alignedTimeSeries`) to the class; check toolbox lines against a
  body scan.
- A zero-caller search must include inline classdef methods, `feval`/
  `str2func`, GUIDE callbacks in `.fig` files and `.mlx` files.
- `calcParameters` turns a failing parameter class into one warning per
  trial: compare per-trial warning text and label sets, not only
  parameter values (`compareAdaptationData` 0 Changed is not enough).
- Wrapping a long statement can move a trailing `%#ok<...>` onto its
  own line and drop the suppression; re-run the lint count after
  wrapping.
