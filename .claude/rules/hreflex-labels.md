---
paths:
  - "fun/parameterCalculation/computeHreflexParameters.m"
  - "fun/+Hreflex/*.m"
---

# H-Reflex: Fixed Labels, Exact Channel Lookup

`computeHreflexParameters` always returns the same 66 labels: a
missing SOL/MG/LG channel is NaN-filled with a
`Hreflex:missingMuscleChannel` warning, and a `false`
`Hreflex.hasStimTrigger` returns the full NaN set. Look channels up
with `isaLabel`, never a bare `getDataAsVector` (its regex fallback
makes `'RTA'` match `RTAP`/`RTAD`). Details:
[FEATURES.md](../../FEATURES.md#h-reflex-parameters).
