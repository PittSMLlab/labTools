---
paths: ["**/*.m"]
---

# MATLAB Style Checklist

<!-- Compressed from CONTRIBUTING.md (the human reference, with
examples). Keep the two in sync: change one, change the other. -->

Full rules and examples: [CONTRIBUTING.md](../../CONTRIBUTING.md).

## Code
- Lines ≤ 76 characters; spaces around `=`, binary comparison
  operators, and after `,`.
- `out = func()`, not `[out] = func()`; call no-argument methods as
  `obj.method()`.
- `0.5`, not `.5`; `mean(x, 'omitnan')`, never `nanmean` (same for
  `median`, `std`, `sum`); `min(x, [], 'omitnan')`.
- Unexplained numeric literals become camelCase named constants with
  an end-of-line source/rationale comment (`aux` label blocks exempt).
- `fullfile(...)`, never concatenation with `filesep`.
- Align `=` within a group of related assignments; do not indent the
  base level of a function body.
- `arguments` block only when it constrains type/size or replaces a
  `nargin` default; directly after the doc block; compile-time
  constant defaults only.

## Naming
- Function files camelCase, scripts PascalCase; never rename existing
  files.
- No `i`/`j` loop indices: strides `st`, generic `ii`/`jj`/`kk`;
  `mscl`, `mrkr`, `lbl`, `tr`, `con`, `fp`, `ch`. No `iMuscle` names.

## Doc Blocks (every function)
- H1 right after `function`: `%MYFUNCTION One-line summary.`
- Blank `%` line, description (first line indented 3 spaces,
  continuation 1), then `% Inputs:` / `% Outputs:` with
  `%   argName - description`, `Toolbox Dependencies` (`None` if core
  only), `% See also NAMEONE, NAMETWO.`

## Organization and Comments
- `%%` header per named phase (names the phase, not the code); one
  blank line before `%%`.
- Comment sections, non-obvious algorithms, domain rules, magic-number
  sources, and decisions; omit comments that restate identifiers.
- `% TODO:` for known gaps, `% NOTE:` for caveats.
- When editing, keep step labels, WHY comments, commented-out
  alternative code, and end-of-line unit/role notes.
- `aux` label/description entries stay on one line.

## GUIDE Files (`GetInfoGUI`, `ReviewEventsGUI`, `PlotParamsGUI`,
`uiCreateStudy`, ...)
- Exempt: `end` after functions, H1 on empty stub callbacks, 76 cols
  inside `% Begin/End initialization code - DO NOT EDIT`.
- Property and value strings PascalCase (`'Enable'`, `'On'`, `'Off'`,
  `'White'`); full doc blocks on `OpeningFcn`, `OutputFcn`, and any
  callback with logic.
