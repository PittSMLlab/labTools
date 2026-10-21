# Data and figure outputs

What labTools writes to disk, where, and whether a re-run overwrites
it. Tables follow the pipeline order: import, processing and
parameters, group/study, GUIs, plotting/examples/tools.

Conventions used in the tables:

- **Overwrite** is one of: *silent* (replaces an existing file with no
  warning), *guard: error* (throws if the file exists), *prompt* (asks
  first), *unique* (name includes a date or time stamp), *append*
  (adds to the existing file), or *none* (nothing is written).
- `<ID>` is `info.ID`; `<folder>` is `info.save_folder`, chosen in
  `GetInfoGUI` (folder browser or typed path).
- MAT-files marked `-v7.3` are saved in the HDF5 format; the others use
  MATLAB's default format.
- A name built by string concatenation (`[dir name]`) only works when
  `dir` ends with a file separator. Those rows say "concatenated".
- "pwd" means the MATLAB current folder at call time. Relative paths
  resolve against it.
- The `params` suffix keeps `<ID>params.mat` from replacing `<ID>.mat`.
- Post-processing methods (`recomputeEvents`, `recomputeParameters`,
  `flushAndRecomputeParameters`) write nothing. Save the returned
  `experimentData` yourself, then call `makeDataObj` to refresh the
  params file.

## 1. Import (`c3d2mat` → `loadSubject`)

`c3d2mat` itself writes nothing; the files below come from the steps it
calls.

| File pattern | Written by | Location | Overwrite | Notes |
|---|---|---|---|---|
| `<ID>info.mat` (`info`) | `GetInfoGUI` output step | `<folder>` | prompt if it exists; *No* renames the ID to `<ID>_<date>` (all later files are renamed too); *Yes* is silent | Saved twice: before the trial-notes dialog and again after. Closing the GUI with *Save* writes it silently. Not `-v7.3` |
| `<ID>loading.log` | `loadSubject` (`diary`) | `<folder>` | append | MATLAB's `diary` appends to an existing file, so a re-run adds to the old log |
| `<ID>RAW.mat` (`rawExpData`) | `loadSubject` | `<folder>` | silent | `-v7.3`. Written after datlog sync, before processing. Re-importing replaces it |
| `<ID>.mat` (`expData`) | `loadSubject` | `<folder>` | silent | `-v7.3`. Saved even if the EMG-norm step fails |
| `<ID>params.mat` (`adaptData`) | `loadSubject` via `makeDataObj` | `<folder>` | silent | `-v7.3`; see section 2 |
| `DatlogSyncRes/Trial##Sync.fig` and `.png` | `SyncDatalog` | `<folder>/DatlogSyncRes` | silent | Folder created if missing. Only when every trial has a datlog |
| `EMGSyncFile/fig/`, `eps/`, `png/` `Trial N Synchronization.*` | `syncEMGData` through `saveFig` | `<folder>/EMGSyncFile` | silent | 600 dpi; one figure per trial with EMG |
| `<ID>OriginalCondName.mat`, `<ID>OriginalCondNameparams.mat` | `loadSubject` (SpinalAdapt split step, `copyfile`) | `<folder>` | silent | Copies of the unsplit files. Rerunning the split step on already-split files replaces the unsplit copies with split data |
| `<ID>.mat`, `<ID>params.mat` (split) | `loadSubject` (SpinalAdapt split step) | `<folder>` | silent | `-v7.3`; replace the unsplit versions. Recompute from `OriginalCondName`, never from these |
| `<ID>Separated.mat` (`newExpData`) | `SepCondsInExpByAudioCue` (legacy `SpinalAdaptation`) | `resSavePath` | silent | `-v7.3`; concatenated, so `resSavePath` needs a trailing separator |
| `<ID>OriginalCondName.mat`, `<ID>OriginalCondNameparams.mat` | `SepCondsInExpByAudioCue` (`copyfile`) | `resSavePath` | silent | Only if the source file exists |
| `<ID>.mat`, `<ID>params.mat` | `SepCondsInExpByAudioCue` | `resSavePath` | silent | `-v7.3` |
| `<ID>SeparatedSpeeds.fig` and `.png` | `SepCondsInExpByAudioCue` | `resSavePath` | silent | Figure of fast/slow speeds, saved next to the data |
| `datlog-original/` (copy of all datlogs); renamed `trial##.mat` | `autoRenameDatlog` | datlog folder | `copyfile` and `movefile` are silent | Datlogs are renamed in place; the backup is the only copy of the original names. A re-run also copies the already-renamed files into the backup |
| `gui/importc3d/markerLabelKey.mat` (`matchedLabels`) | `addMarkerPair` | repo (`which`) | silent | Edits a tracked file that all users share |
| `<ID>RAW.mat`, `<ID>.mat`, `<ID>params.mat` | `reviseExperimentInfo` | `<folder>` | silent | `-v7.3`; replaces the originals with the revised session |

## 2. Processing and parameters

| File pattern | Written by | Location | Overwrite | Notes |
|---|---|---|---|---|
| `<filename>params.mat` (`adaptData`) | `makeDataObj` → `makeDataObjNew` | Wherever `filename` points; a bare name resolves against pwd | silent | `-v7.3`. Nothing is written if `filename` is empty. Callers: `loadSubject`, `ReviewEventsGUI`, `SepCondsInExpByAudioCue`, `reviseExperimentInfo`, `batchReProcess`, `updateParams` |
| `<sub>.mat` (`expData`) | `hmhFun/updateParams` | pwd, or `<sub>/` under pwd when the subject has a folder | silent | Not `-v7.3`. Also refreshes `<sub>params.mat` |
| `<sub>.mat` (`expData`) | `hmhFun/batchReProcess` | Folder the `RAW.mat` was loaded from (pwd or `<sub>/`) | silent | `-v7.3`; also writes `<sub>params.mat` |
| `<subID>params.mat` (`adaptData`) | `changeCondName` | pwd | silent | `-v7.3`; edits condition names in the file you loaded |
| copies of `*params.mat` | `hmhFun/moveParamFilesHere` | pwd | `copyfile` is silent | Gathers params files from subject folders |
| `DependParamRecipes.mat` (`fieldList`) | `CreateDependentParamRecipes` | Folder of the function (repo) | silent | Read back by the dependent-parameter code |
| `<subject>_SLBF_day*.mat`, `<subject>_PerceptionBF_day.mat`, `<subject>_VazE2B_day*.mat` | `saveit` in the six Biofeedback classes (`BiofeedbackSL`, `BiofeedbackSL_c3d`, `BiofeedbackSLBF_Percp`, `BiofeedbackPerception`, `BiofeedbackVazE2B`, `SombricTaiChi`) | pwd | silent | Saves the object under a variable named after the subject code |
| `<LTfilename>params.mat`, `<subject>params.mat` (`adaptData`) | `Biofeedback/AddPythonData`, `SyncPython_forStatic` | pwd (`saveloc = []`) | silent | Not `-v7.3` |
| `<subject>Pyton2.mat` | `SyncPython_forStatic` | pwd | silent | Spelling is as in the code |
| `<ddmmmyyyy>_<file>_SL_Realtime.mat` (`RTdata`) | `SL_Realtime`, `SL_RealtimeAlpha` | Next to the C3D file | silent | Unique per trial per day; a second run on the same trial on the same day replaces the file |

## 3. Group and study

| File pattern | Written by | Location | Overwrite | Notes |
|---|---|---|---|---|
| `<name>.mat` (`studyData`) | `uiCreateStudy` *Save* | `uiputfile` choice | prompt (OS dialog) | `-v7.3`. Cancelling is not handled: `file` is `0` and the save fails |

## 4. GUIs

| File pattern | Written by | Location | Overwrite | Notes |
|---|---|---|---|---|
| `<filename>.mat` (`expData` under its original name) | `ReviewEventsGUI` *Write to Disk* | Folder the subject was opened from (concatenated) | silent | `-v7.3`. This replaces the only copy of the edited events; no backup is made |
| `<filename minus .mat>params.mat` | `ReviewEventsGUI` *Write to Disk* (`makeDataObj`) | Same folder | silent | Regenerated from the edited `expData` |
| `ExpDetails/<name>.mat` (`expDes`) | `GetInfoGUI` *Create description* | `gui/importc3d/ExpDetails` (repo) | prompt | Name is stripped to alphanumerics |
| `ExpDetails/<group>.mat` (`expDes`) | `Template.m` | `gui/importc3d/ExpDetails` (repo) | guard: error | Never overwrites; warns if the same name exists in `Archive/` |
| `Plotting Colors/<name>.mat` (`colorOrder`) | `PlotParamsGUI` *Save colors* | `gui/eventReview/Plotting Colors` (repo) | silent | Cancelling the name dialog is not handled |
| `<ID>info.mat` | `GetInfoGUIbeta`, `errorProofInfobeta` (deprecated) | `<folder>` | silent | Deprecated copies of the `GetInfoGUI` behavior |

## 5. Plotting, examples, tools

| File pattern | Written by | Location | Overwrite | Notes |
|---|---|---|---|---|
| `<savePath>.fig` and `.png`; `<savePath>Diagnostic.*`; `<savePath>InfluentPointLoc.*` | `PlotHelper` plotting methods when `saveResAndFigure` is true | Caller-supplied `savePath` (full path, no extension) | silent | Off by default. Figures only; the plotted data is not saved |
| `<id>_Hreflex<type>Curve[Normalized]_Trial<n>_<leg>.png` and `.fig` | `+Hreflex/plotCal` | `pathFig` | silent | |
| `<id>_NoiseDistribution_Trial<n>_<leg>.png` and `.fig` | `+Hreflex/plotNoiseHistogram` | `options.pathFig`; skipped when empty | silent | |
| `<id>_HreflexSnippets_Trial<n>.fig` and `.png` | `+Hreflex/plotSnippets` | `options.pathFig`; skipped when empty | silent | |
| `<id>_StimArtifactPeakFinding_Trial<n>.png` and `.fig` | `+Hreflex/plotStimArtifactPeaks` | `options.pathFig`; skipped when empty | silent | |
| `HreflexCalFigs/` and a config `.mat` | `GenerateHreflexRecruitmentCurves` | `<trial folder>/HreflexCalFigs` | silent | Config rewritten only when the answers change |
| Vicon trial (in place); `TrajectoryFigures/fig/` and `png/` | `+dataMotion/processAndFillMarkerGapsSession` | Vicon session; `<parent of session>/TrajectoryFigures` | silent (trial is replaced in place) | A failed save only warns |
| `<savePath>` `.mat` (`mrkrData`) | `plotMarkerProcessingTrajectories` | Caller-supplied full path | silent | `-v7.3`; failure only warns |
| Vicon pipeline XML (in place); results CSV | `DetermineOptimalReconstructAndLabelParams` | `pathPipeline`; `pathOutCSV` | silent | The pipeline file is rewritten once per parameter set |
| `<strSess>_EMG_Normalized_*.fig` and `.png` | `EMG_traces_example` | pwd | silent | Example script |
| `fig/`, `eps/`, `png/` `<name>.*` | `saveFig` (pitools); called by `syncEMGData` and the `example/` scripts `PlotIndividualsInGroup` and `PlotParameterTimeCourseWithFilters` | `<dir>/{fig,eps,png}`; the examples use `./` (pwd) | silent | 600 dpi EPS and PNG; creates the folders |
| `hreflexGuardBaseline_<timestamp>.mat` | `testing/ValidateHreflexGuardOnServer` | Session folder | unique | |

## Same artifact, two ways

- Figures are written either as `.fig` + `.png` in one folder
  (`saveas`: `PlotHelper`, `+Hreflex`, `SyncDatalog`, `SepConds`, the
  EMG example) or as `fig/`, `eps/`, `png/` subfolders (`saveFig`:
  `syncEMGData`, the `example/` scripts).
- `*params.mat` is written by `makeDataObj` in most places and by a bare
  `save` in `changeCondName`, `AddPythonData`, and
  `SyncPython_forStatic`.
- Paths are built with `fullfile` in `loadSubject`, `reviseExperimentInfo`,
  and `SepConds`'s later saves, and by concatenation in
  `ReviewEventsGUI`, `updateParams`, `batchReProcess`, and
  `SepConds`'s first save.

## Excluded search hits

`rg -n -g '*.m' "\bsave\b|savefig|saveas|\bprint\b|exportgraphics|write(table|matrix|cell)|imwrite|uisave|fopen\("`
(`-t m` is not a ripgrep type) returns hits that are not outputs:

| Hits | Reason |
|---|---|
| `getEMGworksdata`, `getEMGworksdataAcc`, `loadTrials`, `isaLabel`, `markerModel`, `GenerateHreflexRecruitmentCurves` ("save memory", "save time") | Prose in comments |
| `errorProofInfo`, `syncEMGData` (prompt text), `ReviewEventsGUI` (dialog text and doc lines), `Template.m` (doc lines), `experimentData`, `adaptationData` ("overwrite (save) your file" warnings), `parameterEvolutionPlot`, `parameterTimeCourse`, `makeDataObj` (doc text), `normalityTestWithFig`, `plotCal`, `autoRenameDatlog` (`print` in prose) | Prose, doc text, or user messages that mention saving |
| `computeForceParameters_OGFP`, `computeForceParameters_OGFP_aligned`, `VR_EMG_traces_per_Cond`, `Nim_EMG_traces_per_Cond`, `ReviewEventsGUI` L1050-1054, `GenerateHreflexRecruitmentCurves` L394-414 | Commented-out code; nothing runs |
| `reconstructAndLabelTrial` (`+dataMotion/deprecated` and `OptimizedReconstructAndLabel`), `fillSmallMarkerGapsSpline`, `fillMarkerGapsPattern`, `processAndFillMarkerGapsTrial` | `shouldSave` documentation only; the Vicon `SaveTrial` call is listed in section 5 |
| `AddPythonData` L93; the `fopen` reads in `BiofeedbackSL`, `BiofeedbackSLBF_Percp`, `BiofeedbackPerception`, `SombricTaiChi`; `JSONtxt2cell`; `V2P_tester` | `fopen` for reading (each paired with `fclose`) |
| `fun/ext/BTK/**` (incl. `btkEmulateC3Dserver`), `fun/ext/markerDataCleaning/**` (`naiveDistances`) | Third-party or print-message prose (BTK is untouchable) |
| `testing/*` fixtures | Reads only; the one write (`ValidateHreflexGuardOnServer`) is in section 5 |
