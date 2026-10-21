---
paths:
  - "gui/importc3d/loadSubject.m"
  - "fun/parameterCalculation/calcParameters.m"
---

# QC and Optional Steps Never Abort Import

Optional or QC steps (EMG norms, bout splitting, optional parameter
classes, any new check) run inside `try`/`catch` and end in a
`warning` plus the error report, never an `error`. Gate any prompt on
an `info` flag so headless imports never block. Callers must then
check warnings per trial ([TESTING.md](../../TESTING.md),
[FEATURES.md](../../FEATURES.md)).
