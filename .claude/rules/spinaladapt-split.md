---
paths:
  - "gui/importc3d/splitSpinalAdaptBoutConds.m"
  - "gui/importc3d/getSpinalAdaptBoutSegments.m"
  - "gui/importc3d/loadSubject.m"
  - "classes/dataStructs/@experimentData/recomputeParameters.m"
  - "classes/dataStructs/@experimentData/flushAndRecomputeParameters.m"
---

# Never Recompute a Split SpinalAdapt File

Bout splitting partitions strides by `initTime`; it never recomputes
(short pieces lose the stride at each cut and flag their last stride
`badMissingEvent`). Never recompute a split `<ID>.mat`: recompute
`<ID>OriginalCondName.mat`, then split again. Dispatch matches
`'SpinalAdapt'` exactly, and split sessions exceed 99 trials. Details:
[FEATURES.md](../../FEATURES.md#spinaladapt-bout-splitting).
