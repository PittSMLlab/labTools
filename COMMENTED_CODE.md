# Commented-Out Code

Blocks of commented-out code that the 2026-10 clean-up kept for a lab
decision (keep, turn into a `% NOTE:` explaining why it stays, or
delete). **Nothing has been deleted.** Related: [DEAD_FILES.md](DEAD_FILES.md),
[FUTURE.md](FUTURE.md).

The lists come from a heuristic detector (comment runs that look like
code, outside doc blocks): some entries are prose and a few real blocks
are missed. Line numbers are those of the commit each section names (or
of the working tree at that milestone) and drift with later edits:
search for the block in the file rather than trusting the number.
Sections are grouped by clean-up milestone (S1-S23), i.e. by folder.

## S1/S2

Heuristic detector (comment runs that look like code, outside the doc blocks). Some entries may be prose and a few real blocks may be missed. Line numbers are those of the working tree when this file was written.

### S1

- `classes/dataStructs/@adaptationData/Correlations.m`: 7 line(s) in 5 block(s): 62, 90-91, 109, 133, 161-162
- `classes/dataStructs/@adaptationData/adaptationData.m`: 100 line(s) in 22 block(s): 235, 296-297, 312-313, 507, 598-599, 997-999, 1545-1549, 1560, 1562-1563, 1565, 1668-1671, 1753, 2160-2165, 2167, 2169, 2171-2172, 2200-2201, 2222, 2415-2416, 2418-2425, 2427-2477, 2479
- `classes/dataStructs/@adaptationData/getEarlyLateData_v2.m`: 2 line(s) in 2 block(s): 73, 81
- `classes/dataStructs/@adaptationData/getEarlyLateData_v2_.m`: 2 line(s) in 2 block(s): 76, 79
- `classes/dataStructs/@adaptationData/plotGroupedSubjectsBars.m`: 13 line(s) in 5 block(s): 145-147, 156, 166-170, 210-212, 286
- `classes/dataStructs/@adaptationData/plotGroupedSubjectsBarsv2.m`: 15 line(s) in 5 block(s): 53-55, 159-160, 189, 225-232, 239
- `classes/dataStructs/@adaptationData/plotGroupedSubjectsTimeCourse.m`: 32 line(s) in 2 block(s): 35-65, 135
- `classes/dataStructs/@adaptationData/plotParamBarsByConditions.m`: 24 line(s) in 2 block(s): 59-77, 96-100
- `classes/dataStructs/@adaptationData/plotParamBarsByConditionsv2.m`: 2 line(s) in 2 block(s): 67, 79
- `classes/dataStructs/@adaptationData/scatterPlotLab.m`: 3 line(s) in 1 block(s): 75-77

### S2

- `classes/dataStructs/@experimentData/experimentData.m`: 23 line(s) in 3 block(s): 293-304, 310-317, 380-382
- `classes/dataStructs/@experimentData/getAlignedField.m`: 4 line(s) in 2 block(s): 50-51, 62-63
- `classes/dataStructs/@experimentData/getStridedField.m`: 2 line(s) in 1 block(s): 53-54
- `classes/dataStructs/@experimentData/makeDataObjNew.m`: 3 line(s) in 1 block(s): 71-73
- `classes/dataStructs/@experimentData/process.m`: 1 line(s) in 1 block(s): 44
- `classes/dataStructs/@processedLabData/getStrideInfo.m`: 22 line(s) in 1 block(s): 52-73
- `classes/dataStructs/@processedLabData/processedLabData.m`: 22 line(s) in 6 block(s): 210-213, 215-217, 238-240, 242-245, 247-250, 252-255
- `classes/dataStructs/@processedLabData/reduce.m`: 1 line(s) in 1 block(s): 58
- `classes/dataStructs/@processedLabData/separateIntoSuperStrides.m`: 1 line(s) in 1 block(s): 25
- `classes/dataStructs/@reducedLabData/reducedLabData.m`: 5 line(s) in 1 block(s): 105-109
- `classes/dataStructs/processedTrialData.m`: 3 line(s) in 1 block(s): 103-105

Total lines flagged: 287

## S3/S4

Heuristic detector (comment runs that look like code, outside the doc blocks). Some entries may be prose and a few real blocks may be missed. Line numbers are those of the working tree at commit time (docs commits 7b40030b and 0358f6b4).

### S3

- `classes/dataStructs/@labData/calcLimbAngles.m`: 15 line(s) in 14 block(s): 39, 76, 92, 95-96, 109, 123, 139, 142, 190, 193, 197, 200, 204, 208
- `classes/dataStructs/@labData/checkMarkerDataHealth.m`: 7 line(s) in 4 block(s): 103-104, 109-111, 125, 127
- `classes/dataStructs/@labData/computeCOPAlt.m`: 1 line(s) in 1 block(s): 31
- `classes/dataStructs/@labData/computeHemiCOP.m`: 4 line(s) in 1 block(s): 59-62
- `classes/dataStructs/@labData/getBeltSpeedsFromFootMarkers.m`: 8 line(s) in 4 block(s): 64, 71-73, 85, 89-91
- `classes/dataStructs/@labData/getEvents.m`: 16 line(s) in 7 block(s): 165-166, 170-172, 176, 196, 207-211, 216-217, 258-259
- `classes/dataStructs/@labData/labData.m`: 41 line(s) in 22 block(s): 112, 114-115, 118, 120-121, 124-125, 249, 251, 253, 255, 257-258, 260-262, 264-266, 268, 270, 272, 274-276, 278-280, 282-284, 286, 288-289, 291-293, 295-297
- `classes/dataStructs/@labData/process.m`: 1 line(s) in 1 block(s): 69
- `classes/dataStructs/@labData/processEMG.m`: 3 line(s) in 2 block(s): 122, 159-160
- `classes/dataStructs/metaData/@experimentMetaData/experimentMetaData.m`: 1 line(s) in 1 block(s): 183
- `classes/dataStructs/metaData/@experimentMetaData/getConditionsThatMatch.m`: 6 line(s) in 3 block(s): 48, 50-51, 53-55
- `classes/dataStructs/metaData/@experimentMetaData/getConditionsThatMatchV2.m`: 9 line(s) in 6 block(s): 43, 46, 48, 52, 54-55, 57-59
- `classes/dataStructs/metaData/@experimentMetaData/numerateRepeatedConditionNames.m`: 3 line(s) in 1 block(s): 34-36
- `classes/dataStructs/metaData/@experimentMetaData/replaceConditionNames.m`: 1 line(s) in 1 block(s): 30
- `classes/dataStructs/metaData/derivedMetaData.m`: 7 line(s) in 4 block(s): 85-86, 120, 122-123, 125-126

### S4

- `classes/dataStructs/@groupAdaptationData/groupAdaptationData.m`: 11 line(s) in 8 block(s): 150-151, 153, 156-157, 163, 166, 1828, 1832, 2074-2075
- `classes/dataStructs/@groupAdaptationData/plotBars.m`: 9 line(s) in 8 block(s): 100, 103, 141-142, 145, 149, 151, 154, 157
- `classes/dataStructs/@groupAdaptationData/plotMultipleGroupsBars.m`: 23 line(s) in 19 block(s): 217, 259-260, 269-270, 275-276, 281-282, 321, 346, 397, 399, 401, 403, 405, 407, 409, 443, 453, 469, 501, 516
- `classes/dataStructs/@stridedExperimentData/plotAllStrides.m`: 2 line(s) in 2 block(s): 65, 68
- `classes/dataStructs/@stridedExperimentData/plotAvgStride.m`: 1 line(s) in 1 block(s): 50
- `classes/dataStructs/@stridedExperimentData/stridedExperimentData.m`: 2 line(s) in 2 block(s): 107, 109
- `classes/dataStructs/@studyData/studyData.m`: 2 line(s) in 1 block(s): 71-72

## S5-S6

Heuristic detector : comment runs that look like code, outside the doc blocks. Some entries may be prose and a few real blocks may be missed. Line numbers are those of the working tree at the docs commit. Nothing was deleted.

### S5

- `classes/auxData/@labDate/labDate.m`: 2 line(s) in 1 block(s): 111-112
- `classes/auxData/strokeSubjectData.m`: 1 line(s) in 1 block(s): 103
- `classes/dataStructs/@strideData/plotCell2.m`: 84 line(s) in 27 block(s): 28, 32-33, 35-38, 40-48, 50-52, 54, 57-58, 60, 63-70, 73-74, 76, 86, 89-94, 97-107, 109-111, 113-114, 116-117, 119, 122, 125, 128, 131-133, 135-137, 140, 145-146, 149-157, 159-161
- `classes/dataStructs/@strideData/plotCellAvg.m`: 2 line(s) in 2 block(s): 86, 162
- `classes/dataStructs/@strideData/strideData.m`: 25 line(s) in 8 block(s): 183-188, 192-196, 198-201, 242-244, 246-247, 249, 252-253, 255-256
- `classes/synergies/@ClusteredSynergySetCollection/plot.m`: 12 line(s) in 5 block(s): 153-154, 156, 158-164, 166, 169
- `classes/synergies/@FactorizedMatrix/FactorizedMatrix.m`: 4 line(s) in 3 block(s): 49, 686, 724-725
- `classes/synergies/@SynergySet/SynergySet.m`: 2 line(s) in 1 block(s): 72-73
- `classes/synergies/@SynergySetCollection/cluster.m`: 1 line(s) in 1 block(s): 47

### S6 (paths relative to `classes/labTS/`)

- `processingInfo.m`: 18 line(s) in 4 block(s): 52-55, 57-62, 64-69, 71-72
- `@labTimeSeries/findOutliers.m`: 11 line(s) in 3 block(s): 40-48, 52, 54
- `@labTimeSeries/getArrayedEvents.m`: 3 line(s) in 2 block(s): 31-32, 44
- `@labTimeSeries/getIndexClosestToTimePoint.m`: 5 line(s) in 2 block(s): 20-22, 30-31
- `@labTimeSeries/getSample.m`: 5 line(s) in 4 block(s): 81, 83, 86-87, 89
- `@labTimeSeries/integrate.m`: 1 line(s) in 1 block(s): 25
- `@labTimeSeries/labTimeSeries.m`: 6 line(s) in 4 block(s): 439-441, 449, 453, 458
- `@labTimeSeries/medianFilter.m`: 1 line(s) in 1 block(s): 25
- `@labTimeSeries/plot.m`: 6 line(s) in 4 block(s): 78-80, 88, 92, 97
- `@labTimeSeries/plotAligned.m`: 2 line(s) in 2 block(s): 29, 31
- `@labTimeSeries/resample.m`: 1 line(s) in 1 block(s): 43
- `@labTimeSeries/resampleLogical.m`: 1 line(s) in 1 block(s): 23
- `@labTimeSeries/split.m`: 5 line(s) in 5 block(s): 23, 26, 28, 33, 41
- `@labTimeSeries/substituteNaNs.m`: 1 line(s) in 1 block(s): 36

## S7-S8

Heuristic detector : comment runs that look like code, outside the doc blocks. Some entries may be prose and a few real blocks may be missed. Line numbers are those of the working tree at the docs commits. Nothing was deleted. Paths relative to `classes/labTS/`.

### S7

- `@orientedLabTimeSeries/addLabelSuffix.m`: 3 line(s) in 1 block(s): 26-28
- `@orientedLabTimeSeries/animate2.m`: 6 line(s) in 6 block(s): 59, 62, 80, 98, 102, 108
- `@orientedLabTimeSeries/assessMissing.m`: 1 line(s) in 1 block(s): 41
- `@orientedLabTimeSeries/fixBadLabels.m`: 1 line(s) in 1 block(s): 27
- `@orientedLabTimeSeries/orientedLabTimeSeries.m`: 248 line(s) in 87 block(s): 65, 262, 264-267, 270-271, 273-276, 279-280, 290-304, 306-308, 311, 314-315, 317-318, 320, 322-323, 325-326, 328-332, 339, 342, 348, 350, 353, 357-360, 362-364, 368, 370, 372, 375-376, 378-381, 384-386, 388-390, 392-398, 401, 403-405, 410-412, 415, 417-419, 423-425, 429-431, 436-438, 445, 452-457, 459-462, 472-486, 488-490, 493, 496-497, 499-500, 505-507, 509-510, 512-516, 523, 526, 532, 534, 537, 541-544, 546-548, 552, 554, 556, 559-560, 562-565, 568-570, 572-574, 576-582, 585, 587-589, 594-596, 599, 601-603, 607-609, 613-615, 620-622, 629, 636-641, 643-646, 663, 666-668, 672, 674-681, 684, 686, 688-695, 698, 701-702, 704, 707, 709-718

### S8

- `@alignedTimeSeries/alignedTimeSeries.m`: 4 line(s) in 4 block(s): 430, 433, 446, 449
- `@alignedTimeSeries/getPartialStridesAsATS.m`: 1 line(s) in 1 block(s): 20
- `@alignedTimeSeries/mean.m`: 2 line(s) in 2 block(s): 30, 53
- `@alignedTimeSeries/plot.m`: 4 line(s) in 4 block(s): 174, 177, 190, 193
- `@alignedTimeSeries/plotCheckerboard.m`: 1 line(s) in 1 block(s): 36
- `@alignedTimeSeries/prctile.m`: 1 line(s) in 1 block(s): 26
- `@alignedTimeSeries/std.m`: 1 line(s) in 1 block(s): 25
- `@parameterSeries/cat.m`: 3 line(s) in 1 block(s): 32-34
- `@parameterSeries/linearStretch.m`: 8 line(s) in 3 block(s): 49-53, 55, 58-59
- `@parameterSeries/parameterSeries.m`: 18 line(s) in 9 block(s): 203-205, 221-224, 302, 304-305, 308, 310-312, 319, 321-322, 342

## S9-S10

Heuristic; nothing deleted. Paths under `fun/parameterCalculation/`. Line numbers are working-tree numbers at the docs commits (S9 numbers from ae57626a, S10 numbers from the S10 docs commit).

### S9
- `fun/parameterCalculation/calcParameters.m`: 18 line(s) in 7 block(s): 133, 153-154, 430, 433-436, 444-451, 453, 519
- `fun/parameterCalculation/computeSpatialParameters.m`: 24 line(s) in 9 block(s): 332-335, 337, 340-343, 345, 404-407, 494, 498-501, 555, 558-561
- `fun/parameterCalculation/computeForceParameters.m`: 17 line(s) in 9 block(s): 163-164, 202-204, 397-398, 400, 404, 407-408, 410, 414, 416-419
- `fun/parameterCalculation/computeHSParameters.m`: 9 line(s) in 4 block(s): 37, 42-43, 45-46, 61-64
- `fun/parameterCalculation/computeHreflexParameters.m`: commented-out aux entries (HreflexBEMGMAV*), 6 line(s): 146-151 (exempt from line length as aux entries)

### S10
- `fun/parameterCalculation/CreateDependentParamRecipes.m`: 2 line(s) in 1 block(s): 27-28
- `fun/parameterCalculation/appendBodyCOM.m`: 1 line(s) in 1 block(s): 181
- `fun/parameterCalculation/appendEMGNormParameters.m`: 1 line(s) in 1 block(s): 153
- `fun/parameterCalculation/computeCOM.m`: 2 line(s) in 2 block(s): 73, 81
- `fun/parameterCalculation/computeLegForceParameters.m`: 8 line(s) in 2 block(s): 116, 118-124
- `fun/parameterCalculation/computeTSStatParameters.m`: 9 line(s) in 9 block(s): 79, 83, 87, 92, 97, 103, 109, 115, 119
- `fun/parameterCalculation/determineTMAngle.m`: 11 line(s) in 6 block(s): 51, 53-54, 57-58, 61-62, 64-66, 69
- `fun/parameterCalculation/extractKinematicDataAtEvents.m`: 1 line(s) in 1 block(s): 186
- `fun/parameterCalculation/getKinematicData.m`: 12 line(s) in 6 block(s): 92, 94, 97, 99, 101-104, 137-140

## S11-S12

Heuristic; nothing deleted. Line numbers are working-tree numbers at the docs commits.

### S11

- `fun/+Hreflex/fitCal.m`: 4 line(s) in 3 block(s): 39, 43, 48-49
- `fun/+Hreflex/plotCal.m`: 4 line(s) in 2 block(s): 140-141, 143-144
- `fun/eventExtraction/getEventsFromAngles.m`: 2 line(s) in 2 block(s): 96, 196
- `fun/eventExtraction/getStanceFromToeAndHeel.m`: 28 line(s) in 12 block(s): 26, 30-31, 33, 73-76, 107-108, 187, 189, 194, 313-316, 318-321, 340-344, 349-350

### S12

- `gui/importc3d/loadSubject.m`: 3 line(s) in 3 block(s): 130, 134, 183
- `gui/importc3d/loadTrials.m`: 12 line(s) in 5 block(s): 415, 419, 421, 480-486, 489-490
- `gui/importc3d/processGRFData.m`: 5 line(s) in 4 block(s): 157, 179, 219-220, 223
- `gui/importc3d/syncEMGData.m`: 10 line(s) in 8 block(s): 119, 144-145, 182, 184, 233, 240, 242, 244-245
- `gui/importc3d/SyncDatalog.m`: 26 line(s) in 14 block(s): 98, 112, 114, 120, 122, 127, 132, 186, 188, 190-192, 194-198, 202, 208-210, 227-231
- `gui/importc3d/SepCondsInExpByAudioCue.m`: 2 line(s) in 2 block(s): 110, 201
- `gui/importc3d/autoRenameDatlog.m`: 13 line(s) in 4 block(s): 130-134, 136, 139-140, 142-146
- `gui/importc3d/loadSubject.m` also keeps a commented-out `expMD = experimentMetaData(...)` constructor call (about lines 117-122) that the heuristic reads as prose.
- `gui/importc3d/SepCondsInExpByAudioCue.m` also keeps `% for origTrialIdx = 3` (debug) next to the live loop.

## S13-S14

Heuristic; nothing deleted. Line numbers are working-tree numbers at the docs commits (c0e0d2e8 for S14, ecd684d2 for S13). In PlotHelper the style pass re-wrapped long commented lines, so those blocks are reflowed but not removed.

### S13

- `gui/createStudy/uiCreateStudy.m`: 1 line(s) in 1 block(s): 65
- `gui/importc3d/GetInfoGUI.m`: 1 line(s) in 1 block(s): 278
- `gui/importc3d/errorProofInfo.m`: 31 line(s) in 7 block(s): 172-173, 176-181, 341-343, 345-356, 360-364, 415-416, 420
- `gui/importc3d/findLabel.m`: 12 line(s) in 11 block(s): 34, 36, 38, 40, 42, 44, 46, 48, 50, 52, 54-55
- `gui/importc3d/getEMGworksdata.m`: 8 line(s) in 5 block(s): 138-139, 141-142, 148-149, 152, 188
- `gui/importc3d/getEMGworksdataAcc.m`: 16 line(s) in 11 block(s): 31, 34, 37, 39, 41, 51-52, 54-55, 62, 157-158, 160-161, 167-168

### S14

- `fun/misc/PlotHelper.m`: 43 line(s) in 30 block(s): 376, 379, 382, 406, 668, 691, 694, 697-699, 702, 835, 1002-1003, 1005, 1008, 1079, 1082-1085, 1087, 1090, 1097, 1184, 1190, 1268, 1271-1275, 1277-1278, 1297, 1303, 1338, 1358, 1363, 1426-1428, 1430
- `fun/misc/alignPercTasks.m`: 3 line(s) in 3 block(s): 38, 68, 74
- `fun/misc/bin_dataV1.m`: 5 line(s) in 1 block(s): 50-54
- `fun/misc/plotMarkerProcessingTrajectories.m`: 24 line(s) in 11 block(s): 65-71, 73-74, 76, 78, 80-82, 84, 88, 90, 92, 94-96, 98-100

## S15-S16

Heuristic; nothing deleted. Line numbers are working-tree numbers at the docs commits (f4451f12 for S15, 7e272aa7 for S16). In `Part1RL` three commented `pipelinePath` paths were re-split into `fullfile(...)` form by the style pass. `GenerateHreflexRecruitmentCurves` lines 393-417 are the commented save block under `%% Save the Data` (TODO: implement or delete).

### S15

- `fun/misc/matchControlsFixedGUI.m`: 3 line(s) in 3 block(s): 186, 1102, 1132
- `fun/misc/GenerateHreflexRecruitmentCurves.m`: 23 line(s) in 5 block(s): 147, 393-408, 410, 412, 414-417
- `fun/misc/OptimizedReconstructAndLabel/OptimizedReconstructAndLabel.m`: 2 line(s) in 1 block(s): 88-89
- `fun/misc/OptimizedReconstructAndLabel/Part1RL.m`: 20 line(s) in 11 block(s): 26, 49, 52, 64, 67, 88, 101-107, 112, 115, 212-215, 217
- `fun/misc/OptimizedReconstructAndLabel/processAndFillMarkerGapsTrial.m`: 4 line(s) in 2 block(s): 149-151, 153

### S16

- `fun/misc/hmhFun/getForceResults.m`: 56 line(s) in 40 block(s): 38, 167-170, 213-214, 219-221, 232, 234, 236, 240, 243, 250, 252, 254, 256, 259-260, 264-265, 267-268, 270-271, 274, 276, 278, 283, 309, 329, 333, 340-341, 343-344, 406, 412, 414, 429, 431-434, 436, 681, 691, 707, 712-713, 726, 732, 734, 736
- `fun/misc/hmhFun/getResults.m`: 16 line(s) in 7 block(s): 172, 378, 380-383, 385, 388-391, 393, 395-398
- `fun/misc/hmhFun/getResultsSMART.m`: 11 line(s) in 5 block(s): 188, 506, 509-512, 514, 516-519
- `fun/misc/hmhFun/makeSMatrix.m`: 1 line(s) in 1 block(s): 33
- `fun/misc/hmhFun/makeSMatrixV2.m`: 1 line(s) in 1 block(s): 28

## S17-S18

Heuristic; nothing deleted. Line numbers are working-tree numbers at the docs commits (3821d5c2 for S17, 00553e0e for S18). In `filterEMG` the alternative `BW` values are kept as commented code next to the present-tense rationale; in `interpolTraj` the whole earlier function body (lines 36-145) is kept behind a NOTE; in `colorScheme` and `poster_colors` the two older palettes are kept as comments (rewrapped); in `COPCalculator` the experimental calibration matrices (lines 45-70) are kept as comments (the live ones load from coordinateTransformation_06022017.mat). Candidates for deletion once you approve: Nim/VR EMG trace scripts (about 125 commented lines each, older loading and saving code).

### S17

- `fun/+dataMotion/interpolTraj.m`: 107 line(s) in 54 block(s): 39-40, 42, 45-49, 52, 54, 59-62, 65, 68-69, 71-73, 76, 78, 80, 83, 86, 90, 92-95, 100, 104-106, 110-112, 115, 117-118, 120, 127, 131-133, 136, 139-140, 144, 147-148, 151-152, 154-158, 164, 267-269, 272-273, 282, 353-355, 358, 361-363, 367-369, 372, 375-376, 378, 385, 389-391, 394, 397-398, 402, 405-406, 409-410, 412-416, 421, 424, 428-431, 433-434, 436-438
- `fun/+dataMotion/processAndFillMarkerGapsSession.m`: 1 line(s) in 1 block(s): 163
- `fun/Biofeedback/AddPythonData.m`: 48 line(s) in 27 block(s): 87, 191-192, 194-195, 197, 199-200, 208-209, 211-212, 214, 250, 254, 256, 289-290, 334-335, 339-341, 374, 447, 457, 460, 463, 465, 564-567, 569-573, 575, 765-768, 770-772, 794, 809
- `fun/Biofeedback/SyncPython_forStatic.m`: 27 line(s) in 10 block(s): 479-484, 521-526, 564-568, 570, 581, 601, 605, 611, 615, 619-622
- `fun/SeparateConditions.m`: 2 line(s) in 2 block(s): 139, 169
- `fun/reviseExperimentInfo.m`: 1 line(s) in 1 block(s): 38

### S18

- `fun/EMGanalysis/filterEMG.m`: 10 line(s) in 5 block(s): 36-37, 42, 67, 76, 90-94
- `fun/EMGanalysis/procEMGhealthCheck.m`: 1 line(s) in 1 block(s): 51
- `fun/EMGanalysis/rawEMGhealthCheck.m`: 53 line(s) in 35 block(s): 55, 62, 64-65, 69, 71-72, 74, 76, 78-79, 167-168, 170, 172, 191, 193, 198-200, 203-206, 208, 211, 214, 216, 218, 220, 222, 225, 227-228, 231, 233-235, 239-245, 247, 250, 253, 255, 257, 259, 261, 264
- `fun/EMGanalysis/whitenEMG.m`: 4 line(s) in 4 block(s): 24, 29, 32, 34
- `fun/PlotEMGTraces/Func/EMGtracesplot.m`: 1 line(s) in 1 block(s): 32
- `fun/PlotEMGTraces/Func/getDataEMGtraces.m`: 1 line(s) in 1 block(s): 36
- `fun/PlotEMGTraces/Func/plotEMGtraces.m`: 14 line(s) in 6 block(s): 55-57, 59-60, 112-113, 118-119, 148-149, 151-153
- `fun/PlotEMGTraces/Nim_EMG_traces_per_Cond.m`: 133 line(s) in 61 block(s): 23-25, 31-33, 69-75, 80-82, 85, 91-92, 94-95, 98-101, 103-104, 107-109, 112, 114, 117, 121, 123, 128, 130, 135, 137, 142, 144, 149, 151, 156, 158, 163, 165, 170, 172, 179, 181, 188, 193-197, 199-204, 207-210, 212, 216-220, 222-227, 230-233, 235, 237, 240, 242-247, 250-253, 255, 257-263, 265, 268, 270, 275, 277, 280-282, 285-286, 293-294, 297-302, 304-305, 308, 310, 312-314, 316, 318-320
- `fun/PlotEMGTraces/VR_EMG_traces_per_Cond.m`: 128 line(s) in 59 block(s): 21-24, 62-68, 73-74, 78, 83, 85, 87, 90, 92, 94-97, 100, 102-103, 105, 107, 110, 113, 115, 120, 122, 127, 129, 134, 136, 141, 143, 148, 150, 155, 157, 162, 164, 171, 173, 176, 181-192, 195-198, 202, 206-213, 218-221, 227-230, 238, 240, 242, 245-250, 253-256, 258, 260-266, 268, 271, 273, 278-279, 286, 301, 303-309, 311-312, 315, 317-320, 322-325, 327
- `fun/SteadyStateTau/CalcStrides2SS_PostAdapt.m`: 9 line(s) in 4 block(s): 81, 102-103, 105-109, 138
- `fun/SteadyStateTau/SSTauPostAdapt.m`: 6 line(s) in 2 block(s): 28-31, 48-49
- `fun/biomechAnalysis/COMCalculator.m`: 46 line(s) in 20 block(s): 65, 68, 70-71, 73, 75, 78, 80, 82, 84, 87-89, 92, 95-97, 100, 103, 105, 107, 109, 119-126, 131-138, 143-150
- `fun/biomechAnalysis/COPCalculator.m`: 20 line(s) in 5 block(s): 44, 57, 101-102, 111-120, 136-141
- `fun/biomechAnalysis/TorqueCalculator.m`: 1 line(s) in 1 block(s): 45
- `fun/plotting/CleanStudyData.m`: 2 line(s) in 2 block(s): 28, 31
- `fun/plotting/colors/colorScheme.m`: 2 line(s) in 2 block(s): 24, 28
- `fun/plotting/colors/figuresColorMap.m`: 5 line(s) in 3 block(s): 29, 35-36, 39-40
- `fun/plotting/colors/poster_colors.m`: 2 line(s) in 2 block(s): 23, 27
- `fun/plotting/figureFullScreen.m`: 1 line(s) in 1 block(s): 22
- `fun/plotting/figuresColorMap.m`: 5 line(s) in 3 block(s): 31, 37-38, 41-42
- `fun/plotting/getFigStruct.m`: 7 line(s) in 1 block(s): 29-35
- `fun/plotting/prettyBarPlot.m`: 2 line(s) in 2 block(s): 105, 118
- `fun/plotting/subplotSize.m`: 2 line(s) in 1 block(s): 32-33

## S19-S20

Heuristic; nothing deleted. Line numbers are working-tree numbers at the docs commits (7208565a for S19, 7b1458b5 for S20). `hold on` hits in the example scripts are real code, not comments.

### S19

- `fun/ext/markerDataCleaning/models/markerModel.m`: 21 line(s) in 9 block(s): 285-291, 294-295, 298, 300-302, 304, 307, 373-375, 488, 702-703 (the whole figure block "Reference data" in `seeModel`, alternative heuristics in `labelData`)
- `fun/ext/markerDataCleaning/models/naiveDistances.m`: 54 line(s) in 24 block(s): the old `tryPermutations` (about 45 lines, kept with a TODO to benchmark against `markerModel.tryPermutations`), the validation-warning blocks in `reconstruct`, a debug `disp` block in `validateMarkerModel`
- `fun/ext/markerDataCleaning/old_markerModels/createZeroModel.m`, `determineLikelihoodFromZeroModel.m`, `staticSkeleton/sk3Ddetect.m`, `skDistdetect.m`: 1-2 lines each (alternative formulas)
- `fun/ext/pitools/signalProcessing/amp_estim.m`: 19 lines in 7 blocks (whitening, hilbert and moving-average alternatives)
- `fun/ext/pitools/signalProcessing/findTemplate.m`: 26 lines in 8 blocks (slow reference loop, plotting)
- `fun/ext/pitools/signalProcessing/estimateDopplerShift.m`: 14 lines in 3 blocks
- `fun/ext/pitools/signalProcessing/interpft1.m`: 12 lines in 3 blocks (multi-dimension draft)
- `fun/ext/pitools/signalProcessing/resampleShiftAndScale.m`: 5 lines; `usefulCode/checkBelongings.m`: 3; `dimReduction/myNNMF.m`, `DiscreteTimeFourierTransform.m`, `diverging_map.m`, `xticklabel_rotate90_cell.m`: 1 each

### S20

- `example/PlotIndividualsInGroup.m` (1), `PlotParameterTimeCourseWithFilters.m` (6), `TestMarkerHealthCheck.m` (2), `TestMarkerOutlierDetectAndCorrect.m` (3), `TestPipelineRecompute.m` (1), `testing/TestHreflexStimTriggerGuard.m` (1), `testing/TestSpinalAdaptBoutSegments.m` (1): alternative calls and optional plot lines in example scripts

## S21-S22

Heuristic; nothing deleted. Line numbers are
working-tree numbers at the S21/S22 docs commits (b3946a68, c684af71).
The wrapped legacy blocks in `plotMultipleEpochBars` (lines ~288-end) and
the `computeForceParameters_OGFP*` commented stride-fraction code were
re-wrapped mechanically, so some commented continuation lines break
inside a bracket; re-join them before uncommenting.

Specific blocks worth a decision:
- `plotMultipleEpochBars`: the whole "TO DO: add stats" legacy block
  (~line 288 to the end, ~200 lines: old subplot grid, pairwise ttest/RM
  ANOVA overlays); superseded by `groupAdaptationData.AnovaEpochs`.
- `plotAvgTimeCourse` ~286-340: perceptual-task alternative
  (`pertSizePercTask` non-NaN transition logic), "Maybe needed later".
- `ReviewEventsGUI`: two zoomed-in time-window alternatives in
  `timeSlider_Callback`; two commented `plot(... goodStrides ...)` lines in
  `plotData`; the old `eval(save...)` / `recomputeParameters` lines in
  `write_Callback` (they keep their dated "PI ... 28/4/2015" and "HH"
  narration because they belong to the commented code; trim if you agree).
  These were deleted by the local stash and restored here per your request.
- `PlotParamsGUI`: groupList_Callback `conditions=[conditions ...]` loop.
- `computeForceParameters_OGFP` / `_aligned`: ~95-110 blocks each, mostly
  the `find(ns_all>=...)` stride-fraction pruning alternatives and filter
  variants.
- `removeBiasV2/V3/V4`: the `if nargin>1 && ~isempty(conditions)` sketch,
  `trialTypes=this.data.trialTypes`, data(isnan)=-100000. V2 is
  unreachable code after its `error(...)`.
- `getEventsFromForces`: Butterworth pre-filter block; `checkEventConsistency`.
- `getKinematicDataAbs`: rotation matrix block; `sAnkRel` alternative.
- `SL_Realtime`: "use these two lines when processing c3d not open in Nexus".

Full heuristic output:

- `classes/dataStructs/@adaptationData/plotAvgTimeCourse.m`: 52 line(s) in 31 block(s): 144-147, 193-195, 286, 289-290, 296-298, 303, 332, 336, 340, 505-506, 609-610, 674, 721, 766, 775, 796, 809, 812, 814-815, 818-822, 824, 837, 843-844, 847-848, 851, 854, 865-867, 873, 875-876, 884, 935-936
- `classes/dataStructs/@groupAdaptationData/plotMultipleEpochBars.m`: 217 line(s) in 89 block(s): 119, 288, 291-292, 301-304, 306-316, 318-320, 322, 324, 326, 328-333, 336-338, 342, 346-351, 355-362, 364, 366-367, 369, 371, 374-382, 384-385, 387-388, 390-396, 398-402, 406, 412, 415, 417-418, 420-421, 423-426, 428, 434, 437-439, 443, 446-450, 452, 454, 456, 458-459, 461-462, 464-466, 472, 484-486, 488-492, 494-495, 497, 500, 502-503, 505-506, 508-509, 511, 515-516, 520-527, 529, 531-532, 534-536, 539-540, 543, 546, 548-552, 558, 561, 574, 580-581, 601-602, 604, 606-609, 611, 614-615, 618-619, 622-624, 631, 633, 636, 639, 642-647, 650, 653, 657-658, 662-663, 666, 668, 670, 673-675, 678-679, 683-684, 687-694, 696-697, 699-702, 704
- `fun/eventExtraction/getEventsFromForces.m`: 7 line(s) in 4 block(s): 28-29, 31, 34-36, 46
- `fun/parameterCalculation/getKinematicDataAbs.m`: 12 line(s) in 6 block(s): 86, 88, 91, 93, 95-98, 131-134
- `gui/eventReview/PlotParamsGUI.m`: 7 line(s) in 3 block(s): 86, 225-227, 229-231
- `gui/eventReview/ReviewEventsGUI.m`: 10 line(s) in 6 block(s): 69, 442, 472-475, 479-480, 579, 581
- `classes/dataStructs/@adaptationData/removeBiasV2.m`: 6 line(s) in 5 block(s): 38, 49, 54-55, 58, 61
- `classes/dataStructs/@adaptationData/removeBiasV3.m`: 3 line(s) in 3 block(s): 39, 50, 57
- `classes/dataStructs/@adaptationData/removeBiasV4.m`: 3 line(s) in 3 block(s): 44, 55, 73
- `fun/misc/SL_Realtime.m`: 2 line(s) in 1 block(s): 28-29
- `fun/parameterCalculation/computeForceParameters_OGFP.m`: 197 line(s) in 94 block(s): 98, 120, 124-127, 130-133, 208, 304-305, 331-332, 413-414, 416-417, 440-441, 505, 522, 537, 574-575, 583, 602, 604-606, 608-618, 621-627, 629, 631, 635-640, 642-643, 673, 690, 705, 765, 767-769, 771-781, 784-790, 792, 794, 798, 833, 837-838, 841, 844-845, 870-871, 882, 892, 894-895, 897, 915, 919-922, 925-926, 1042-1043, 1055, 1180-1181, 1189, 1191, 1202, 1204-1205, 1207-1210, 1212, 1215-1216, 1219, 1221-1227, 1230-1231, 1233, 1235-1236, 1238-1239, 1241-1245, 1247-1248, 1251, 1253-1259, 1262-1263, 1266, 1268, 1270-1271, 1273, 1275, 1277-1278, 1280, 1282, 1284-1285, 1287, 1289, 1291-1292, 1306-1307, 1309, 1313, 1316, 1323, 1332, 1344, 1347, 1353, 1395-1397, 1416-1418, 1436, 1440, 1476-1477, 1479-1482, 1484
- `fun/parameterCalculation/computeForceParameters_OGFP_aligned.m`: 211 line(s) in 108 block(s): 107-108, 118-126, 128, 131-133, 141, 228, 234, 440, 443, 575, 578, 640, 657, 675, 715-716, 725, 745, 747-748, 750, 752-762, 765-771, 773, 775, 779-784, 786-787, 790, 792, 794, 796, 831, 848, 866, 930, 932-933, 935, 937-947, 950-956, 958, 960, 964, 966, 969, 971, 973, 1011, 1015-1016, 1019, 1022-1023, 1048-1049, 1060, 1070, 1072-1073, 1075, 1093, 1097-1100, 1103-1104, 1220-1221, 1233, 1358-1359, 1367, 1369, 1380, 1382-1383, 1385-1388, 1390, 1393-1394, 1397, 1399-1405, 1408-1409, 1411, 1413-1414, 1416-1417, 1419-1423, 1425-1426, 1429, 1431-1437, 1440-1441, 1444, 1446, 1448-1449, 1451, 1453, 1455-1456, 1458, 1460, 1462-1463, 1465, 1467, 1469-1470, 1472, 1474, 1476-1478, 1491-1492, 1494, 1498, 1501, 1508, 1517, 1529, 1532, 1538, 1583-1585, 1604-1606, 1624, 1628, 1664-1665, 1667-1670, 1672

## S23

Heuristic; nothing deleted. Line numbers are
working-tree numbers at the S23 docs commit (839d94ee). The commented
plotting blocks (`fill`/`plot`/`hold on` with the long `cell2mat(rhits(...))`
expressions) were re-wrapped mechanically by `wrapcc.py`: continuation
lines start with `%    `, and the mirrored indent was collapsed, so re-join
and re-indent them before uncommenting. The banner lines `%%!!!!...` were
truncated to fit 76 columns.

- `classes/Biofeedback/BiofeedbackPerception.m`: 40 line(s) in 18 block(s): 329, 334, 359, 364, 381-382, 388, 394-395, 401, 716, 735-754, 771, 774, 781, 784, 1295-1296, 1311, 1492, 1498
- `classes/Biofeedback/BiofeedbackSL.m`: 30 line(s) in 28 block(s): 104, 660, 690-691, 700-701, 758, 760, 765, 777, 782, 840, 842, 927, 929, 941, 1010, 1460, 1462, 1466, 1471, 1476, 1481, 1505, 1523, 1525, 1528, 1533, 1538, 1543
- `classes/Biofeedback/BiofeedbackSLBF_Percp.m`: 184 line(s) in 126 block(s): 105, 461, 483, 508, 544, 550, 607, 629, 654, 688, 694, 701, 720-721, 723-724, 728, 730, 732-735, 737-738, 741, 743, 745-746, 748, 750-753, 768, 776-777, 780, 791, 794, 808, 810, 815-816, 820, 826-827, 829, 832-833, 836, 839-841, 844, 847, 849-852, 867, 875-876, 879, 890, 893, 907, 909, 914-915, 919, 922-923, 925, 928-929, 932, 935-937, 940, 948-951, 966, 975-976, 979, 990-991, 994, 1007-1008, 1010-1011, 1021-1022, 1024, 1027-1028, 1031, 1034, 1037, 1040, 1042, 1044-1047, 1062, 1071-1072, 1075, 1088, 1091, 1104-1105, 1107-1108, 1115-1116, 1118, 1121-1122, 1125, 1128, 1131, 1134, 1137, 1139, 1142-1143, 1146, 1159, 1167-1168, 1170, 1180, 1182, 1195-1196, 1199, 1202, 1205-1207, 1212, 1215-1216, 1219, 1232, 1240-1241, 1243, 1253, 1255, 1268-1269, 1272, 1275, 1278-1280, 1332, 1334-1340, 1592, 1594, 1598, 1603, 1608, 1613, 1637, 1655, 1657, 1660, 1665, 1670, 1675
- `classes/Biofeedback/BiofeedbackSL_c3d.m`: 42 line(s) in 25 block(s): 104, 517, 521, 523, 529, 639, 643, 645, 651, 768, 772, 775, 781, 891, 895, 898, 904, 926-927, 929-930, 932-935, 937-938, 940-941, 992, 995-1001, 1021-1025
- `classes/Biofeedback/BiofeedbackVazE2B.m`: 159 line(s) in 105 block(s): 98, 372-373, 377-378, 380-381, 399, 401, 407-409, 416-417, 424-426, 428-429, 432-434, 436, 438, 442-443, 445, 447, 454, 456-457, 485, 579, 597, 604-605, 607, 612, 615, 618, 624, 636-637, 640, 657-658, 661, 683-684, 686-689, 692, 694, 696, 701, 706-712, 716-717, 730-731, 733-734, 736-737, 739-742, 745, 802, 804, 809, 814-815, 824-825, 840, 848-849, 852, 863, 866, 880, 882, 887-888, 892, 895-897, 900-902, 905, 911, 974, 976, 981-982, 990-991, 1006, 1015-1016, 1019, 1032, 1035, 1048-1049, 1051-1052, 1059-1061, 1064, 1067, 1070, 1074, 1136, 1141, 1147, 1155, 1157, 1166-1167, 1169, 1181-1182, 1184, 1186-1190, 1290, 1297, 1303, 1312, 1633, 1635, 1639, 1644, 1649, 1654, 1678, 1696, 1698, 1701, 1706, 1711, 1716
- `classes/Biofeedback/SombricTaiChi.m`: 37 line(s) in 20 block(s): 218, 300-301, 303-304, 365, 597, 602, 604, 606, 608, 610, 612, 614, 616-617, 664-665, 670, 672, 684-685, 687-692, 727, 739-746
