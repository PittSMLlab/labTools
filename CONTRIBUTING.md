# Contributing to labTools

Thank you for contributing to labTools. This guide explains coding
conventions, documentation standards, and architectural patterns that
keep the codebase consistent and maintainable. Please read it before
submitting changes.

---

## Table of Contents

1. [Where to Put New Code](#where-to-put-new-code)
2. [MATLAB Version Compatibility](#matlab-version-compatibility)
3. [Code Style](#code-style)
4. [Naming Conventions](#naming-conventions)
5. [Documentation Comments](#documentation-comments)
6. [Code Organization](#code-organization)
7. [Writing Comments](#writing-comments)
8. [Third-Party Code](#third-party-code)
9. [Testing](#testing)

---

## Where to Put New Code

labTools separates concerns across three layers:

| Layer | Location | Purpose |
|---|---|---|
| Data containers | `classes/dataStructs/` | Holding and querying data |
| Time series | `classes/labTS/` | Uniform-sampled and labeled signal data |
| Algorithms | `fun/` | Domain computation and analysis |
| GUIs | `gui/` | User-facing data I/O |

**Rule of thumb:** if a function transforms or computes something, it
belongs in `fun/`. If it stores or retrieves structured data, it
belongs in a class. If it reads user input or renders plots driven by
user interaction, it belongs in `gui/`.

Relevant `fun/` subdirectories:

| Directory | Purpose |
|---|---|
| `parameterCalculation/` | Stride-level biomechanical parameters |
| `eventExtraction/` | Gait event detection (heel-strike, toe-off) |
| `biomechAnalysis/` | COM/COP, joint torques |
| `EMGanalysis/` | EMG filtering and envelope extraction |
| `plotting/` | Visualization utilities |
| `+dataMotion/` | Namespace: marker and segment utilities |
| `+Hreflex/` | Namespace: H-reflex analysis |
| `+utils/` | Namespace: general utilities |

---

## MATLAB Version Compatibility

All code must be compatible with **MATLAB R2021a through the current
release**. Avoid language features or toolbox functions introduced
after R2021a without a fallback.

---

## Code Style

### Line Length

Wrap all lines at **76 characters**. This keeps diffs readable and
avoids horizontal scrolling in split-pane editors.

### Spacing

Use spaces around `=` and all binary comparison operators:

```matlab
% Correct
result = a + b;
if x == 0

% Incorrect
result=a+b;
if x==0
```

### Function Output Brackets

Do **not** use brackets around a single output argument:

```matlab
% Correct
out = myFunction(x);

% Incorrect
[out] = myFunction(x);
```

Brackets are only for multiple outputs: `[a, b] = myFunction(x)`.

### Calling No-Argument Methods

Always append `()` when calling a method with no arguments. This
makes it unambiguous that you are calling a method, not reading a
property:

```matlab
% Correct
labels = ts.getLabels();

% Incorrect
labels = ts.getLabels;
```

### Numeric Literals

Write leading zeros: `0.5` not `.5`. This is a readability choice —
the leading zero makes the decimal point visually distinct.

### `arguments` Blocks

Use an `arguments` block when it meaningfully constrains input type
or size, or when it replaces a `nargin` check with a declared
default. Place it immediately after the documentation comment.

Default values in `arguments` must be **compile-time constants**.
Compute argument-dependent defaults in the function body after the
block:

```matlab
function result = computeMetric(data, options)
%COMPUTEMETRIC Compute a stride-level metric from processed data.
%
%   ...
%
arguments
    data    (:,1) double
    options.Window  (1,1) double {mustBePositive} = 10
    options.Colors  (:,3) double ...
        {mustBeInRange(options.Colors, 0, 1)} = []
end

% Argument-dependent defaults go here, not in the arguments block.
if isempty(options.Colors)
    options.Colors = lines(options.Window);
end
```

Multiline validators indent to align with the argument name (see
`options.Colors` above).

### NaN-Aware Statistics

Use the `'omitnan'` flag instead of the deprecated `nan*` functions:

```matlab
% Correct
m = mean(x, 'omitnan');
s = std(x,  'omitnan');
n = sum(x,  'omitnan');

% Incorrect
m = nanmean(x);
s = nanstd(x);
n = nansum(x);
```

For `min` and `max`, the syntax is slightly different:

```matlab
lo = min(x, [], 'omitnan');
hi = max(x, [], 'omitnan');
```

### Named Constants for Magic Numbers

Unexplained numeric literals must be extracted to named constants
with an end-of-line comment giving their source or rationale:

```matlab
% Correct
gravityAcc    = 9.81;  % gravitational acceleration (m/s^2)
impactWinFrac = 0.15;  % first 15% of stance (protocol spec)

% Incorrect
force = mass * 9.81;
win   = round(0.15 * nSamples);
```

The `aux` label/description block is exempt from this rule.

### Aligned Assignments

Within a group of closely related assignments, align the `=` signs.
This makes it easy to scan the right-hand side as a column:

```matlab
minSpacing  = max(1, round(options.MinSpacing));
optimizeFor = upper(options.OptimizeFor);
maxEvals    = round(options.MaxEvals);
```

Only align assignments that are genuinely related. Do not
artificially group unrelated lines just to create alignment.

---

## Naming Conventions

### Files

| Type | Convention | Example |
|---|---|---|
| Function files | camelCase | `computeStepLength.m` |
| Scripts | PascalCase | `RunGroupAnalysis.m` |

Do **not** rename existing files — this breaks any external code that
calls them by name.

### Variables

Choose descriptive names. Abbreviations are acceptable when
unambiguous. Preferred short names:

| Abbreviation | Meaning |
|---|---|
| `tbl` | table |
| `fig` | figure handle |
| `lme` | linear mixed-effects model |
| `pval` | p-value |
| `mscl` | muscles |
| `mrkr` | markers |
| `lbl` | labels |
| `tr` | trials |
| `con` | conditions |
| `fp` | force plates |
| `ch` | channels |

### Loop Indices

Never use `i` or `j` as loop indices — they shadow MATLAB's imaginary
unit, which can cause subtle numerical bugs:

```matlab
% Correct
for st = 1:nStrides        % stride loop
for ii = 1:numel(items)    % generic enumeration
for tr = 1:nTrials
for mscl = 1:nMuscles

% Incorrect
for i = 1:nStrides
for iMuscle = 1:nMuscles   % Hungarian prefix style also incorrect
```

For stride loops, prefer `st`. For general enumeration without a
more meaningful name, use `ii`, `jj`, or `kk`.

---

## Documentation Comments

Every function requires a documentation block placed immediately
after the `function` definition line.

### Structure

```matlab
function out = myFunction(arg1, arg2)
%MYFUNCTION One-line summary beginning with a capital letter.
%
%   Full description. The first line of the description is indented
% three spaces. Continuation lines use one space after the %.
% Wrap at 76 characters.
%
% Inputs:
%   arg1 - description of arg1
%   arg2 - description of arg2
%
% Outputs:
%   out - description of out
%
% Toolbox Dependencies: Signal Processing Toolbox
%
% See also RELATEDFUNCTION, ANOTHERFUNCTION.
```

### Rules

**H1 line** — no space between `%` and the function name; function
name in ALL CAPS. MATLAB's `help` command uses this line as the
one-line summary.

**Description** — one blank comment line after H1; first content
line indented three spaces; continuation lines indented one space.

**Inputs/Outputs** — list each argument with a short description.
Use the exact parameter name as it appears in the signature.

**Toolbox Dependencies** — list any required toolboxes by name.
Write `None` if only core MATLAB is needed.

**See Also** — write function names in ALL CAPS so MATLAB renders
them as clickable hyperlinks in the documentation browser.

### Complete Example

```matlab
function events = getEventsFromForces(vGRF, sampleRate, options)
%GETEVENTSfromforces Detect heel-strike and toe-off events from
% vertical GRF signals.
%
%   Applies a threshold to the vertical ground-reaction force to
% identify the onset (heel-strike) and offset (toe-off) of each
% stance phase. Returns a sparse labTimeSeries with event labels
% LHS, RHS, LTO, RTO.
%
% Inputs:
%   vGRF       - labTimeSeries of vertical GRF (N), two channels:
%                'LGRF' and 'RGRF'
%   sampleRate - sampling rate in Hz
%   options    - struct with optional fields:
%     .Threshold - force threshold in N (default: 30)
%
% Outputs:
%   events - sparse labTimeSeries with columns LHS, RHS, LTO, RTO
%
% Toolbox Dependencies: None
%
% See also GETEVENTSFROMANGLES, GETSTANCEFROMFORCESALT.

arguments
    vGRF        labTimeSeries
    sampleRate  (1,1) double {mustBePositive}
    options.Threshold (1,1) double {mustBePositive} = 30
end
```

---

## Code Organization

### Section Headers

Use `%%` section headers to mark all named logical phases of a
function or script. The header text names the phase (what is
happening), not the code (what MATLAB is doing):

```matlab
% Correct
%% Compute bilateral symmetry index

% Incorrect
%% For loop over strides
```

Separate each section from the previous one with a single blank line
before `%%`. Separate logically distinct statement groups within a
section with a blank line.

### Function Body Indentation

Do **not** indent the base level of code inside a function. The
function definition line is the outermost scope; its body is
flush-left:

```matlab
% Correct
function result = add(a, b)
%ADD Add two numbers.

result = a + b;
end

% Incorrect
function result = add(a, b)
%ADD Add two numbers.

    result = a + b;  % <-- do not indent the base level
end
```

Control flow inside the function indents normally.

### `aux` Label/Description Blocks

In `aux` blocks that list labels and descriptions, keep each entry
on one line regardless of length. These blocks are exempt from the
76-character line-length rule.

---

## Writing Comments

### When to Write a Comment

Write a comment when:

- **Starting a new `%%` section** — the header is itself a required
  comment.
- **A non-obvious algorithm needs a block summary** — summarize the
  approach, not the steps.
- **A line encodes a domain rule or formula** — cite the source
  (protocol specification, paper, anatomical convention).
- **A magic number needs a source** — see Named Constants above.
- **A decision could have gone another way** — explain why this
  branch was chosen.

Omit comments when identifiers already make the purpose clear.
Redundant comments rot as the code evolves:

```matlab
% Incorrect — restates what the identifier already says
strideCount = strideCount + 1;  % increment stride count

% Correct — explains a non-obvious domain rule
hsIdx = hsIdx - round(0.02 * sampleRate);
% NOTE: subtract 20 ms to correct for shoe-sensor propagation delay
%       (protocol calibration, 2019-03-12).
```

### Special Prefixes

- `% TODO:` — known incomplete work that should be addressed later.
- `% NOTE:` — important caveats or non-obvious constraints that a
  future reader must not miss.

### Editing Existing Files

When editing an existing file, preserve:

- Step-labeling comments (numbered phases, `%%` headers)
- WHY comments (rationale, domain rules, citations)
- Commented-out alternative code (may be intentional)
- End-of-line clarifications (units, roles)

Remove only comments that restate what identifiers already make
obvious.

---

## Third-Party Code

`fun/ext/BTK/` is an unmodified external library. **Do not edit it.**
Changes will be overwritten when BTK is updated.

`fun/ext/pitools/` and `fun/ext/markerDataCleaning/` are treated as
first-party labTools code even though they originated from external
repositories. Apply labTools code style when editing these files.
They may diverge from the upstream repositories over time.

---

## Testing

labTools has no automated test suite. The `example/` scripts serve
as manual integration tests. When making a change:

1. Run the relevant script(s) in `example/` to confirm the pipeline
   still produces expected output.
2. If your change affects gait event detection, load a saved
   `*expData.mat` file and call `recomputeEvents` to verify events
   look correct in `ReviewEventsGUI`.
3. If your change affects parameter calculation, call
   `recomputeParameters` and compare the output `adaptationData`
   object against a known-good baseline.
4. Note that `experimentData` is a **value class** — recompute
   methods return a modified copy. Always capture the return value:

   ```matlab
   expData = expData.recomputeParameters();
   ```
