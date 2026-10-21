---
paths:
  - "fun/parameterCalculation/computeForceParameters.m"
  - "fun/parameterCalculation/adjudicateStrideQuality.m"
  - "fun/parameterCalculation/flagTriageOutliers.m"
  - "fun/parameterCalculation/calcParameters.m"
  - "classes/dataStructs/@adaptationData/removeStridesByReason.m"
  - "classes/dataStructs/@adaptationData/adaptationData.m"
---

# Informational Flags Never Fold into `bad`

`HandrailHolding` and `triageOutlier` are informational: never OR them
into `bad`/`good`. Users censor them opt-in with
`removeHandrailStrides` or `removeStridesByReason`. Handrail
parameters stay `NaN` (not 0) without an `HFz` channel, and are not
gated on `'TM'` trials. Details:
[FEATURES.md](../../FEATURES.md#instrumented-handrail).
