# Dead-File Candidates

Files that nothing in this repository calls, found during the 2026-10
clean-up. **Nothing has been deleted** and nothing here is verified
for code outside this repository (analysis scripts in personal
folders, other lab repos): only the lab can confirm a file is unused.

How to use this list: for each row, fill `action` with keep, archive,
delete or merge into another file. Before deleting, grep the basename
over `.m`/`.fig`/`.mlx`/`.md`/`.txt`, check `feval`/`str2func`/GUIDE
callback strings and inline classdef methods, and record the evidence.
Related follow-ups: [FUTURE.md](FUTURE.md); commented-out code:
[COMMENTED_CODE.md](COMMENTED_CODE.md).

Labels: **C4** = Biofeedback / real-time feedback triage (merge,
archive or delete as a group); **C5** = a family of near-duplicate
files that could be merged behind one name. Section D groups files by
the clean-up milestone that found them (S1-S23, C7); the commit hashes
in its notes are where the evidence was gathered.

Section B comes from a token search at tag `pre-cleanup` (82e48521):
105 zero-caller files, 18,515 lines.

## A. deprecated/ and Archive/ directories (24 files, 3,229 lines)

| file | lines | verified | action |
|---|---|---|---|
| fun/+dataMotion/deprecated/processAndFillSmallMarkerGapsSession.m | 66 | | |
| fun/+dataMotion/deprecated/reconstructAndLabelSession.m | (116 with next) | | |
| fun/+dataMotion/deprecated/reconstructAndLabelTrial.m | | | |
| fun/eventExtraction/deprecated/getEventsFromSwitches.m | 14 | | |
| fun/eventExtraction/deprecated/getStanceFromSwitches.m | 9 | | |
| fun/parameterCalculation/deprecated/getIndsForAllSteps.m | 109 | | |
| fun/parameterCalculation/deprecated/getIndsForThisStep.m | 100 | | |
| gui/importc3d/ExpDetails/Archive/OldAbrupt.m | 53 | | |
| gui/importc3d/ExpDetails/Archive/OldAbruptNoCatch.m | 52 | | |
| gui/importc3d/ExpDetails/Archive/OldAbruptSecondVisit.m | 4 | | |
| gui/importc3d/ExpDetails/Archive/OldAbruptSelfSelected.m | 58 | | |
| gui/importc3d/ExpDetails/Archive/OldGradual.m | 52 | | |
| gui/importc3d/ExpDetails/Archive/OldGradualNoCatch.m | 49 | | |
| gui/importc3d/ExpDetails/Archive/OldGradualSelfSelected.m | 58 | | |
| gui/importc3d/ExpDetails/Archive/PabloDistraction.m | 46 | | |
| gui/importc3d/ExpDetails/Archive/PabloOld.m | 46 | | |
| gui/importc3d/ExpDetails/Archive/YoungAbrupt.m | 4 | | |
| gui/importc3d/ExpDetails/Archive/YoungAbruptSecondVisit.m | 4 | | |
| gui/importc3d/ExpDetails/Archive/YoungGradual.m | 4 | | |
| gui/importc3d/deprecated/GetInfoGUIbeta.m (+ .fig) | 1,636 | | |
| gui/importc3d/deprecated/c3d2matbeta.m | 36 | | |
| gui/importc3d/deprecated/errorProofInfobeta.m | 276 | | |
| gui/importc3d/deprecated/experimentDetails.m | 423 | | |
| gui/importc3d/deprecated/getLabelsFromc3d.m | 14 | | |

Also in Archive/: `gui/importc3d/ExpDetails/Archive/README.txt`
(decide with the folder). `OldAbrupt.m`/`OldGradual.m` are not on the
zero-caller list (some file mentions their names): find out who
before deleting.

## B. Zero-caller candidates outside A (no reference anywhere)

| file | kind | lines | verified | action |
|---|---|---|---|---|
| classes/Biofeedback/BiofeedbackPerception.m | classdef | 1097 | | C4 |
| classes/Biofeedback/BiofeedbackSL.m | classdef | 1002 | | C4 |
| classes/Biofeedback/BiofeedbackSLBF_Percp.m | classdef | 1011 | | C4 |
| classes/Biofeedback/BiofeedbackSL_c3d.m | classdef | 668 | | C4 |
| classes/Biofeedback/BiofeedbackVazE2B.m | classdef | 1042 | | C4 |
| classes/Biofeedback/SombricTaiChi.m | classdef | 537 | | C4 |
| classes/dataStructs/@adaptationData/getBaseData.m | method | 22 | | |
| classes/dataStructs/@adaptationData/getEarlyLateData_v2_.m | method | 85 | | |
| classes/dataStructs/@adaptationData/plotGroupedSubjectsTimeCourse.m | method | 160 | | |
| classes/dataStructs/@adaptationData/plotParamBarsByConditions.m | method | 73 | | |
| classes/dataStructs/@adaptationData/plotParamBarsByConditionsv2.m | method | 83 | | |
| classes/dataStructs/@experimentData/computeAngles.m | method | 27 | | |
| classes/dataStructs/@groupAdaptationData/plotBars.m | method | 104 | | |
| classes/dataStructs/@labData/alignAllTS.m | method | 19 | | |
| classes/dataStructs/@processedLabData/calcAdaptParams.m | method | 18 | | |
| classes/dataStructs/@processedLabData/separateIntoDoubleStrides.m | method | 32 | | |
| classes/dataStructs/@strideData/fakeStride.m | method | 19 | | |
| classes/dataStructs/@strideData/plotCell2.m | method | 141 | | |
| classes/dataStructs/@stridedExperimentData/discardBadStrides.m | method | 20 | | |
| classes/dataStructs/@studyData/createStudyData.m | method | 28 | | |
| classes/dataStructs/metaData/@experimentMetaData/splitConditionIntoTrials.m | method | 42 | | |
| classes/labTS/@alignedTimeSeries/rescaleTime.m | method | 36 | | |
| classes/labTS/@labTimeSeries/createLabTSFromTimeVector.m | method | 22 | | |
| classes/labTS/@labTimeSeries/dispCov.m | method | 24 | | |
| classes/labTS/@labTimeSeries/join.m | method | 34 | | |
| classes/labTS/@labTimeSeries/monotonicFilter.m | method | 31 | | |
| classes/labTS/@labTimeSeries/plotStridedTimeSeries.m | method | 33 | | |
| classes/labTS/@labTimeSeries/removeParameter.m | method | 26 | | |
| classes/labTS/@orientedLabTimeSeries/vectorNorm.m | method | 19 | | |
| classes/labTS/@parameterSeries/incorporateDependentParameters.m | method | 40 | | |
| classes/labTS/@parameterSeries/plotAlt.m | method | 39 | | |
| classes/synergies/@SynergyAnalysis/SynergyAnalysis.m | classdef | 240 | | |
| classes/synergies/exampleClusteredSynergySetCollection.m | script | 22 | | |
| classes/synergies/exampleFactorizedMatrix.m | script | 63 | | |
| classes/synergies/exampleSynergy.m | script | 12 | | |
| classes/synergies/exampleSynergySet.m | script | 16 | | |
| classes/synergies/exampleSynergySetCollection.m | script | 27 | | |
| fun/+dataMotion/TrajCheckOnePipeline.m | script | 51 | | |
| fun/+dataMotion/exportSessionToC3D.m | function | 56 | | |
| fun/+dataMotion/interpolTraj.m | function | 385 | | |
| fun/+dataMotion/processAndFillMarkerGapsSession.m | function | 330 | | |
| fun/Biofeedback/AddPythonData.m | script | 755 | | |
| fun/Biofeedback/SyncPython_forStatic.m | function | 576 | | |
| fun/EMGanalysis/equalizeMuscleActivity.m | function | 10 | | |
| fun/EMGanalysis/flipEMGdata.m | function | 9 | | |
| fun/EMGanalysis/getSymmetry.m | function | 9 | | |
| fun/EMGanalysis/procEMGhealthCheck.m | function | 40 | | |
| fun/EMGanalysis/rawEMGhealthCheck.m | function | 155 | | |
| fun/EMGanalysis/synergyAnalysis/getSynergies.m | function | 25 | | |
| fun/PlotEMGTraces/EMG_traces_example.m | script | 58 | | |
| fun/PlotEMGTraces/Func/EMGtracesplot.m | script | 95 | | |
| fun/PlotEMGTraces/Nim_EMG_traces_per_Cond.m | script | 256 | | |
| fun/PlotEMGTraces/VR_EMG_traces_per_Cond.m | script | 260 | | |
| fun/SeparateConditions.m | function | 178 | | |
| fun/SteadyStateTau/SSTauPostAdapt.m | function | 91 | | |
| fun/misc/DetermineOptimalReconstructAndLabelParams.m | script | 371 | | |
| fun/misc/GenerateHreflexRecruitmentCurves.m | script | 700 | | |
| fun/misc/OptimizedReconstructAndLabel/CompareTrajectory_RL.m | script | 99 | | |
| fun/misc/OptimizedReconstructAndLabel/OptimizedReconstructAndLabel.m | script | 137 | | |
| fun/misc/OptimizedReconstructAndLabel/TrajCheckOtherPipeline.m | script | 62 | | |
| fun/misc/OptimizedReconstructAndLabel/TrajectoryCheckOptimizedRL.m | script | 114 | | |
| fun/misc/PlotHelper.m | classdef | 1017 | | |
| fun/misc/SL_RealtimeAlpha.m | script | 351 | | C4 |
| fun/misc/V2P_tester.m | script | 47 | | |
| fun/misc/changeCondName.m | function | 78 | | |
| fun/misc/getOGspeed.m | function | 71 | | |
| fun/misc/hmhFun/batchReProcess.m | function | 49 | | |
| fun/misc/hmhFun/expResults.m | function | 235 | | |
| fun/misc/hmhFun/gaitMovieHH.m | function | 273 | | |
| fun/misc/hmhFun/getForceResults.m | function | 691 | | |
| fun/misc/hmhFun/getResultsBF.m | function | 245 | | |
| fun/misc/hmhFun/getResultsSMART.m | function | 519 | | |
| fun/misc/hmhFun/getSubsFromFolders.m | function | 33 | | |
| fun/misc/hmhFun/moveParamFilesHere.m | function | 44 | | |
| fun/misc/hmhFun/subFileList.m | function | 25 | | |
| fun/misc/hmhFun/updateParams.m | function | 62 | | |
| fun/misc/matchControlsFixedGUI.m | function | 1051 | | |
| fun/misc/plotMarkerProcessingTrajectories.m | function | 99 | | |
| fun/parameterCalculation/CreateDependentParamRecipes.m | script | 78 | | |
| fun/plotting/CleanStudyData.m | function | 26 | | |
| fun/plotting/colors/poster_colorsHH.m | script | 31 | | |
| fun/plotting/getNiceAxisLimits.m | function | 24 | | |
| fun/plotting/niceMap.m | function | 10 | | |
| fun/plotting/prettyBarPlot.m | function | 90 | | |
| fun/reviseExperimentInfo.m | function | 134 | | |
| gui/importc3d/c3d2matCLI.m | function | 49 | | |
| testing/TestHreflexStimTriggerGuard.m | script | 124 | | keep (test) |
| testing/ValidateHreflexGuardOnServer.m | script | 236 | | keep (test) |

Scripts are user-run entry points by nature: default `keep` unless the
user marks them obsolete.

## C. Referenced only from docs/.fig/.mlx (entry points — keep)

| file | referenced from |
|---|---|
| classes/dataStructs/@adaptationData/plotGroupedSubjectsBars.m | README.md |
| classes/dataStructs/@adaptationData/removeStridesByReason.m | CLAUDE.md, EXPERIMENT_SETUP.md, README.md (called inline from adaptationData.m wrappers — heuristic blind spot) |
| example/*.m (8 files) | README.md, TESTING.md |
| fun/misc/compareExperimentData.m | CONTRIBUTING.md, TESTING.md |
| gui/eventReview/PlotParamsGUI.m | CLAUDE.md, README.md |
| gui/eventReview/ReviewEventsGUI.m | CLAUDE.md, CONTRIBUTING.md, EXPERIMENT_SETUP.md |
| testing/TestSpinalAdaptBoutSegments.m | TESTING.md |
| testing/ValidateSpinalAdaptBoutSplitOnServer.m | TESTING.md |

## D. Flagged for lab discussion, by milestone

### S3-S4

Nothing is deleted. Each file was styled and kept. "Evidence" means a
repo-wide word search at the S4 docs commit (0358f6b4). Callers outside
this repo cannot be seen, so only the lab can confirm.

| file | evidence | note |
|---|---|---|
| @labData/alignAllTS.m | only the classdef declaration and doc line | doc already says "(unimplemented)" |
| @experimentMetaData/splitConditionIntoTrials.m | only the classdef declaration and doc line | no repo caller |
| @groupAdaptationData/plotBars.m | only the declaration in groupAdaptationData.m | older bar-plot path; see plotMultipleGroupsBars |
| @stridedExperimentData/discardBadStrides.m | only the declaration; doc says deprecated | |
| @studyData/createStudyData.m | only the declaration and doc line | |
| @studyData/anova.m, barPlot.m, getCommonConditions.m, getCommonParameters.m | stubs that return [] | never implemented; implement or remove |

Correction to section B: `@experimentMetaData/getConditionsThatMatchV2.m`
is NOT unused. It is called from `@adaptationData/removeBiasV4.m` and
`fun/parameterCalculation/appendEMGNormParameters.m`.

### S5 (strideData / auxData / synergies)

| file | evidence | note |
|---|---|---|
| @strideData/fakeStride.m | declared in strideData.m only; body is a stub ("implementation needed") | never implemented |
| @strideData/plotCell2.m | no caller; body is a stub plus ~100 lines of an older plotCell as comments | commented-out code kept |
| @strideData/alignEvents.m | declared in strideData.m only; returns [] | doc says unimplemented |
| @strideData/strideData.m | does not parse at pre-cleanup (nested `methods` block under Phase Extraction Methods, stray `end` after alignEvents); MATLAB's dependency analyzer reports syntax errors | `separateIntoStrides`, `separateIntoDoubleStrides`, `separateIntoSuperStrides`, `stridedExperimentData.getDataAsMatrices` still reference the class |
| @SynergyAnalysis/SynergyAnalysis.m | zero callers (section B); also calls functions that are not in the repo (empiric*EigDistributions*, createUnstructuredParametersFromData) | research code |
| synergies/example*.m (5 scripts) | zero callers (section B) | demo scripts for the synergy classes; now carry header comments |

### S6 (labTimeSeries)

| file | evidence | note |
|---|---|---|
| @labTimeSeries/createLabTSFromTimeVector.m | zero callers (section B); body is a stub ("not implemented") | |
| @labTimeSeries/dispCov.m | zero callers (section B) | |
| @labTimeSeries/join.m | zero callers (section B) | |
| @labTimeSeries/monotonicFilter.m | zero callers (section B); declared in labTimeSeries.m | |
| @labTimeSeries/plotStridedTimeSeries.m | zero callers (section B) | |
| @labTimeSeries/removeParameter.m | zero callers (section B) | |
| @labTimeSeries/align_v2.m | called by `align.m` (not dead); C5 family (align / align_v2) | merge candidate for C5 |
| @labTimeSeries/plot.m, plotAligned.m, bilateralPlot.m | the same three methods are also defined inline in labTimeSeries.m, which takes precedence over the separate files | duplicate definitions; resolve in C |
| @labTimeSeries/castAsSTS.m, spectrogram.m | call `spectroTimeSeries`, which is not in the repository | both fail at call time unless the class is on the path |


### S7-S8 (orientedLabTimeSeries / alignedTimeSeries / parameterSeries)

| file | evidence | note |
|---|---|---|
| @orientedLabTimeSeries/vectorNorm.m | zero callers (section B); only listed in the class header and method block of orientedLabTimeSeries.m | |
| @alignedTimeSeries/rescaleTime.m | zero callers (section B); only declared in alignedTimeSeries.m | |
| @parameterSeries/plotAlt.m | zero callers (section B); only declared in parameterSeries.m | |
| @parameterSeries/incorporateDependentParameters.m | zero static callers (section B), declared in parameterSeries.m; it evals the 901 recipe handles in `DependParamRecipes.mat` and may be called dynamically | verify with the lab before any deletion |
| @alignedTimeSeries/plot.m | the same method is also defined inline in alignedTimeSeries.m, which takes precedence over the separate file | duplicate definition; resolve in a C milestone |

### S10 (parameterCalculation B)
- `fun/parameterCalculation/CreateDependentParamRecipes.m` (script, 78 lines): zero callers (§B row). Builds and saves `DependParamRecipes.mat` next to itself. Styled and kept; lab to decide.

### S11 (eventExtraction / +Hreflex)

| file | evidence | note |
|---|---|---|
| fun/eventExtraction/checkEventConsistency.m | no live caller: the only references are commented-out calls in `getEventsFromAngles.m`, `getEventsFromForces.m`, `deprecated/getEventsFromSwitches.m` and a NOTE in `getEventsFromToeAndHeel.m` (word search at the S11 docs commit) | debugging helper kept for the commented calls; wire in or remove |

### S13-S14 (gui/ rest, fun/misc A)

Six milestone files are zero-caller rows of section B (word search at
the S2 census); all were styled and kept.

| file | evidence | note |
|---|---|---|
| gui/importc3d/c3d2matCLI.m | section B: no reference anywhere | non-GUI twin of the `c3d2mat` script (takes a saved info file); keep as batch entry point or remove |
| fun/misc/PlotHelper.m | section B: classdef with no reference (its `.m` name is only mentioned in comments and in its own docs) | static plotting helpers from the Automaticity analyses (see `plotSingleCorrelation` example path) |
| fun/misc/V2P_tester.m | section B: script | interactive diagnostic for V2P timing files; keep as a user-run script |
| fun/misc/changeCondName.m | section B | edits `*params.mat` condition names in place; keep as a utility |
| fun/misc/getOGspeed.m | section B | overground speed from hip markers; `deleteShortPhases` caller only |
| fun/misc/plotMarkerProcessingTrajectories.m | section B | runs the OLD/NEW marker pipelines; its plotting variant is commented out below the function |

### S15-S16 (fun/misc B, hmhFun)

Evidence: repo-wide word search over .m/.md/.mlx/.txt (excluding doc/ and the file itself) at 7e272aa7. Styled and kept.

| file | evidence | note |
|---|---|---|
| fun/misc/matchControlsFixedGUI.m | no reference | standalone GUI; needs uidatepicker (> R2021a) |
| fun/misc/GenerateHreflexRecruitmentCurves.m | no reference | Nexus-side experiment script |
| fun/misc/DetermineOptimalReconstructAndLabelParams.m | no reference | overwrites a Nexus pipeline file |
| OptimizedReconstructAndLabel/CompareTrajectory_RL, OptimizedReconstructAndLabel, TrajCheckOtherPipeline, TrajectoryCheckOptimizedRL | no reference | Nexus scripts; the folder's helpers call each other only |
| OptimizedReconstructAndLabel/reconstructAndLabelSession | no caller (dataMotion.* names only) | duplicate of fun/+dataMotion version (C5) |
| hmhFun/batchReProcess, expResults, gaitMovieHH, getForceResults, getResultsBF, getResultsSMART, getSubsFromFolders, moveParamFilesHere, subFileList, updateParams | no reference | expResults says deprecated (use getResults) |

### S17-S18 (dataMotion, fun/*.m, Biofeedback, EMGanalysis, PlotEMGTraces, SteadyStateTau, biomechAnalysis, plotting)

Evidence: `git grep -w` over tracked files (excluding doc/ and the file itself) at 00553e0e; the only hits for some files are the `See also` lines added in S17/S18. Styled and kept.

| file | evidence | note |
|---|---|---|
| fun/+dataMotion/TrajCheckOnePipeline, exportSessionToC3D, interpolTraj, processAndFillMarkerGapsSession | no reference | Nexus-side scripts and session drivers; `exportTrialToC3D`, `extractMarkerGapsTrial`, `fillMarkerGapsPattern`, `fillSmallMarkerGapsSpline`, `openTrialIfNeeded` are called by the OptimizedReconstructAndLabel scripts. `interpolTraj` also keeps its earlier function body as comments |
| fun/Biofeedback/AddPythonData, SyncPython_forStatic | no reference | biofeedback import scripts for the distraction study (`SyncPython_forStatic` says it is study specific) |
| fun/SeparateConditions, reviseExperimentInfo | no reference | study-specific condition splitting and session-info revision |
| fun/EMGanalysis/equalizeMuscleActivity, flipEMGdata, getSymmetry, procEMGhealthCheck, rawEMGhealthCheck, synergyAnalysis/getSynergies | no reference | EMG utilities and health checks; `rawEMGhealthCheck` has 53 commented lines |
| fun/PlotEMGTraces/EMG_traces_example, Func/EMGtracesplot, Nim_EMG_traces_per_Cond, VR_EMG_traces_per_Cond | no reference | user-run plotting scripts; `EMGtracesplot` is not self-contained (older copy of `plotEMGtraces`), the Nim/VR scripts hold about 130 commented lines each |
| fun/SteadyStateTau/SSTauPostAdapt | no reference | its helper `CalcStrides2SS_PostAdapt` is called only from it |
| fun/plotting/CleanStudyData, getNiceAxisLimits, niceMap, prettyBarPlot, colors/poster_colorsHH | no reference | `prettyBarPlot` uses `figuresColorMap` |
| fun/biomechAnalysis/TorqueCalculatorNew | called only by a commented-out line in `TorqueCalculator` (C5 family) | `TorqueCalculator` always returns empty moments |
| fun/plotting/figuresColorMap, fun/plotting/colors/figuresColorMap | C5 family | two copies; the `plotting/` one warns "Loading OLD figuresColorMap" and has a different `condColors` |

### S1-S2 (adaptationData, experimentData, processedLabData; added 2026-10-08)

S1 and S2 ran before the flag rule. Evidence: `git grep -w` over tracked .m/.md/.mlx/.txt (excluding doc/ and the file itself) at 00553e0e. All files were styled and kept; nothing deleted.

| file | evidence | note |
|---|---|---|
| @adaptationData/getBaseData.m | only caller is an inline method in adaptationData.m (line 409, `getBaseData(this, baseCond, labels)`); no other reference | dead if that method is dead; check with the lab |
| @adaptationData/getEarlyLateData_v2_.m | no reference | file/function name mismatch (FUTURE.md); trailing-underscore copy of getEarlyLateData_v2 |
| @adaptationData/plotGroupedSubjectsTimeCourse.m | only an inline wrapper in adaptationData.m (line 1975); header there says "not functional; use plotAvgTimeCourse" | superseded by plotAvgTimeCourse |
| @adaptationData/plotParamBarsByConditions.m | no reference | superseded by plotParamBarsByConditionsv2 |
| @adaptationData/plotParamBarsByConditionsv2.m | NOT dead: called by inline methods in adaptationData.m (lines 1628, 1793) | C5 family; section B listed it wrongly |
| @adaptationData/plotGroupedSubjectsBarsv2.m | NOT dead: called by plotMultipleGroupsBars, PlotParamsGUI and inline wrappers | C5 family |
| @experimentData/computeAngles.m | classdef declaration and doc line only | |
| @experimentData/splitIntoStrides.m | classdef declaration and doc line only | not in section B (heuristic counted the declaration) |
| @experimentData/parameterEvolutionPlot.m | classdef declaration and doc line only | not in section B |
| @experimentData/parameterTimeCourse.m | classdef declaration and doc line only | not in section B |
| @experimentData/makeDataObjNew.m | NOT dead: called by makeDataObj | C5 family |
| @processedLabData/calcAdaptParams.m | classdef declaration and doc line only | |
| @processedLabData/separateIntoDoubleStrides.m | classdef declaration only | |
| @processedLabData/getStepInfo.m | classdef declaration only | not in section B |

Callers outside this repo cannot be seen; only the lab can confirm.

### S19-S20 (fun/ext/markerDataCleaning, fun/ext/pitools, example/, testing/; added 2026-10-08)

Evidence: `git grep -w` over tracked .m/.md/.mlx/.txt (excluding doc/ and the file itself) at 7208565a. Styled and kept.

| file | evidence | note |
|---|---|---|
| fun/ext/markerDataCleaning/staticSkeleton/testSkeleton.m | no reference | demo script; stale (`W` is never defined, `sk3Denforce` takes four arguments) |
| fun/ext/pitools/efficientOverload/effconvn.m | no reference | `effconvnfull` is its helper-style twin and is referenced |
| fun/ext/markerDataCleaning/staticSkeleton/sk3Denforce.m, skDistenforce.m | called only from testSkeleton / example/TestMarkerOutlierDetectAndCorrect.m | call `updateKF`, `computeDiffMatrix(N)` with a scalar: not runnable as written; `skDistenforce.m` defines `skDistlearnenforce` (name/file mismatch) |
| fun/ext/markerDataCleaning/old_markerModels/* | `createZeroModel` and `determineLikelihoodFromZeroModel` are called from `@labData/checkMarkerDataHealth.m`; `getBestReconsFromZeroModel` only from `createZeroModel` | not dead, but `getBestReconsFromZeroModel` needs `getRotationAndTranslation` and `getPositionFromDistances`, which are not in the repository |
| fun/ext/markerDataCleaning/models/markerModel.m, naiveDistances.m | used by `extractMarkerModels` and example/TestMarkerHealthCheck.m | `validateMarkerModel`, `labelData`, `dropMarkers`, `sortMarkerOrder`, `getSharedMarkerList` are stubs; `reconstruct`/`anchor` need `getTranslationAndRotation`/`getPositionFromDistances_v3` (not in the repo); `getRefData`/`validateMarkerModel` need `distanceModelReferenceData.mat` (not in the repo) |
| testing/TestHreflexStimTriggerGuard.m, testing/ValidateHreflexGuardOnServer.m | section B "keep (test)": no reference | user-run test scripts |

### S21-S22 (WIP-stash files + C survivors; added 2026-10-20)

Evidence: `git grep -w` over tracked .m/.md/.mlx/.txt (excluding doc/ and the file itself) at b3946a68. Styled and kept.

| file | evidence | note |
|---|---|---|
| fun/misc/SL_Realtime.m, SL_RealtimeAlpha.m | no reference | Nexus-pipeline scripts (zero callers by design); both save `<date>_<trial>_SL_Realtime.mat`, so Alpha overwrites Realtime's file name; needs ViconNexus + BTK. C4 |
| classes/dataStructs/@adaptationData/removeBiasV2.m | the `adaptationData.m` lines 177-180 are a signature listing, not calls; `getEarlyLateData_v2_.m:82` calls it, itself dead | first statement is `error('... deprecated ...')`, so the rest is unreachable. Corrects the earlier "called from adaptationData.m" note |
| classes/dataStructs/@adaptationData/removeBiasV3.m | `adaptationData.m:182` signature listing and `:234-235` commented example only | no live caller; V4 is what `removeBias` uses (adaptationData.m:237, plotAvgTimeCourse flag 2 for H-reflex) |
| fun/parameterCalculation/computeForceParameters_OGFP.m, _OGFP_aligned.m | NOT dead: `calcParameters.m:348` and `:362` | C3 family |

### S23 (classes/Biofeedback; added 2026-10-20)

Evidence: `git grep -w` over tracked .m/.md/.mlx/.txt (excluding doc/ and the files themselves) at 839d94ee; the matches in `doc/` are generated HTML. Styled and kept; deletion is the C4 decision.

| file | evidence | note |
|---|---|---|
| classes/Biofeedback/BiofeedbackPerception.m, BiofeedbackSL.m, BiofeedbackSLBF_Percp.m, BiofeedbackSL_c3d.m, BiofeedbackVazE2B.m, SombricTaiChi.m | no reference outside their own files | study-specific session classes (step-length biofeedback / perception / Vazquez 2B / tai chi). Need `cprintf`, `uigetfiles`, `JSONtxt2cell` (fun/misc) and, for SL_c3d, BTK; `editTriallist` uses `eval` on a base-workspace variable named by subjectcode; SL, SLBF_Percp, SL_c3d and VazE2B repeat the same `AnalyzePerformance` structure but differ by about 670-830 lines pre-cleanup (diff vs SL). C4 |

### Phase C, C7 (2026-10-20; commit 42626434)

Nothing deleted. A `% NOTE:` was added to each doc block. "Shadowed" means the same method is defined inline in the classdef file, which takes precedence over the separate file (checked in MATLAB R2024a for the first four; read from the classdef for the rest). Evidence: `git grep -nw` over tracked .m/.md/.mlx (excluding doc/) at b084593d.

| file | evidence | note |
|---|---|---|
| @labTimeSeries/plot.m, plotAligned.m, bilateralPlot.m | inline definitions in labTimeSeries.m win; bodies identical (plotAligned: error id differs) | shadowed copies, 204 lines |
| @alignedTimeSeries/plot.m | inline definition in alignedTimeSeries.m wins; bodies identical | shadowed, 233 lines |
| @processedLabData/getAlignedField.m, getStridedField.m | inline definitions at processedLabData.m:259 and :354 | shadowed, 90 lines |
| @groupAdaptationData/GroupDemographics.m | inline `GroupDemographics(this)` at groupAdaptationData.m:2222; this file calls `.GroupDemographics(grps{g})` with an argument the inline method does not accept | shadowed; would break if it ever won. Working study-level function: fun/misc/hmhFun/GroupDemographics.m |
| @adaptationData/getEarlyLateData_v2_.m | no caller; live version is getEarlyLateData_v2.m | superseded |
| @adaptationData/plotParamBarsByConditions.m | no caller | superseded by plotParamBarsByConditionsv2 |
| @adaptationData/plotGroupedSubjectsTimeCourse.m | errors on its first statement; only the inline wrapper (adaptationData.m:1975, documented as not functional) references it | superseded by plotAvgTimeCourse |
| @strideData/plotCell2.m | no caller; stub | superseded by plotCell |
| eventExtraction/getStanceFromForcesAlt.m | no caller; getEventsFromForces uses getStanceFromForces | different algorithm (derivative vs threshold), not a copy |
| biomechAnalysis/TorqueCalculatorNew.m | only a commented-out call in TorqueCalculator | no live caller |

Not marked: `fun/plotting/figuresColorMap.m` vs `fun/plotting/colors/figuresColorMap.m` (which copy wins is checked with `which -all` in the C7 log; see FUTURE.md).
