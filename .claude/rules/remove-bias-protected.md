---
paths:
  - "classes/dataStructs/@adaptationData/adaptationData.m"
  - "classes/dataStructs/@adaptationData/removeBias*.m"
  - "fun/parameterCalculation/getStrideQualityConfig.m"
---

# Bias Removal Must Skip Binary Stride Flags

`removeBias` (inline in `adaptationData.m`) and `removeBiasV2`-`V4`
each build a protected-label list from
`getStrideQualityConfig().reasonLabels` plus `triageOutlier` and
`HandrailHolding`. Any new binary per-stride flag must join that list
in all four, or bias removal silently subtracts a baseline mean from
it (no error, no warning). Details:
[FEATURES.md](../../FEATURES.md#stride-quality-labeling).
