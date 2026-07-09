# EXPERIMENT_SETUP.md — Configuring New Experiments

This guide covers three setup tasks that are specific to each study or
lab configuration:

1. [Adding a New Experiment Type](#adding-a-new-experiment-type)
2. [Marker Label Mapping](#marker-label-mapping)
3. [Instrumented Handrail (Optional)](#instrumented-handrail-optional)

---

## Adding a New Experiment Type

The `GetInfoGUI` experiment-description dropdown is driven by `.mat`
files stored in `gui/importc3d/ExpDetails/`. Each file describes one
experiment: its conditions, types, names, and default trial numbers.
No code needs to be edited — dropping a new `.mat` file into that
directory is sufficient for it to appear in the GUI.

The `Template.m` script at `gui/importc3d/ExpDetails/Template.m`
generates these `.mat` files. Do not edit `Template.m` directly;
instead follow the steps below.

### Step 1: Copy Template.m

In MATLAB, navigate to `gui/importc3d/ExpDetails/` and save a copy
of `Template.m` under a new name that reflects your study
(e.g., `MyStudyYoungerAdults.m`). The saved `.mat` filename will be
derived from this script's `expDes.group` string (alphabetic
characters only), so name the script accordingly.

### Step 2: Edit Sections 1–6

Open your copy and fill in each section:

| Section | Field | What to set |
|---|---|---|
| 1 | `expDes.group` | Display name in the GetInfoGUI dropdown (e.g., `'Older Adults Abrupt 2025'`) |
| 2 | `maxConds` | Total number of conditions |
| 3 | (auto) | Condition numbers — generated automatically; do not edit |
| 4 | `type` per condition | Locomotion context: `'OG'`, `'TM'`, or `'IN'` |
| 5 | `condNames` cell array | Short condition names (see baseline naming rule below) |
| 6 | `condDescriptions` | One-line description per condition (strides, speed, belt ratio) |
| 7 | `trialNums` | Expected C3D trial numbers: `'1:5'`, `'7'`, `'8 9'` — **not** `'1-5'` |

### Step 3: Run the Script

```matlab
% From the MATLAB Command Window or by pressing Run in the Editor:
MyStudyYoungerAdults
```

The script validates that each cell array has exactly `maxConds`
entries, then saves `ExpDetails/OlderAdultsAbrupt2025.mat` (using only
the alphabetic characters of `expDes.group`). A confirmation message
is printed:

```
Experiment description saved: .../ExpDetails/OlderAdultsAbrupt2025.mat
```

The new description appears immediately in the GetInfoGUI dropdown
the next time the GUI is opened (or after calling `c3d2mat`).

### Step 4: Updating an Existing Description

The script **will not overwrite** an existing `.mat` file — it throws
an error to prevent accidental data loss. To update a description:

1. Move the existing `.mat` file to `ExpDetails/Archive/`, or delete
   it if it is no longer needed.
2. Re-run the script. The new `.mat` file is saved in its place.

### Baseline Condition Naming Rule

For `removeBias` to subtract a condition as the per-subject baseline,
the condition's `condName` must contain **both** the type string
(`'OG'`, `'TM'`, or `'IN'`) and the substring `'base'` — for example,
`'OG base'` or `'TM base'`. Every condition sharing that type will
have the bias from its corresponding baseline removed.

> If the baseline condition name does not satisfy this rule,
> `removeBias` will silently find no matching baseline and leave the
> data uncentered.

---

## Marker Label Mapping

Vicon Nexus labs vary in how they name markers (e.g., `LANK` vs.
`L_ANK` vs. `LAnkle`). labTools maps all known variants to a single
canonical label for each marker position.

The mapping lives in `gui/importc3d/markerLabelKey.mat`. When loaded,
it contains a variable `matchedLabels`: a cell array where each row
holds all accepted label variants for one marker position, followed
by the canonical label that labTools uses internally.

### Adding a New Label Variant

```matlab
load('gui/importc3d/markerLabelKey.mat', 'matchedLabels')

% Inspect the current mapping (each row = one marker position):
matchedLabels

% Suppose your Vicon session uses 'L_Ankle' for the left ankle.
% Find the row for the left-ankle canonical label and append the
% new variant to that row, then save:
row = find(strcmp(matchedLabels(:, end), 'LANK'));
matchedLabels{row, end+1} = 'L_Ankle';   % add to that row
save('gui/importc3d/markerLabelKey.mat', 'matchedLabels')
```

> **Do not edit `findLabel.m` directly.** The switch-statement code
> visible in that file is commented-out legacy code; the active mapping
> source is `markerLabelKey.mat`.

---

## Instrumented Handrail (Optional)

If your treadmill has a force-transducer-instrumented handrail wired
into the C3D analog channels, `processGRFData` auto-detects it and
labels it `HFx`/`HFy`/`HFz` (+ moments `HMx`/`HMy`/`HMz`) inside
`GRFData`. No GetInfoGUI configuration is needed — presence of these
channels is determined entirely by the C3D file's analog channel
layout, not by any GUI setting.

### Stride-Level Parameters

`computeForceParameters` computes three stride-level parameters from
the vertical handrail channel (`HFz`):

- **`HandrailHolding`** — binary; `1` if the mean absolute vertical
  handrail force over the stride exceeds 5% body weight (BW), `0`
  otherwise, `NaN` if no handrail channel was found for the trial.
- **`HandrailForceNorm`** — continuous; the underlying mean absolute
  vertical force per stride, normalized to BW (the value
  `HandrailHolding` thresholds).
- **`HandrailForceN`** — continuous; the same mean absolute vertical
  force per stride, in Newtons (not normalized to BW). Useful when an
  analysis cares about absolute handrail loading rather than
  body-weight support (e.g., comparing across subjects of different
  mass without factoring out BW).

Unlike the belt-plate force parameters (`FyBS`/`FyPS`/etc.), which are
only computed for `'TM'`-type trials, handrail computation runs for
any trial type (`'TM'`, `'IN'`, `'NIM'`, or `'OG'`) — the handrail is
an independent load cell, not one of the belt plates, so it is not
tied to that gate. It self-gates purely on whether the `HFz` channel
is present and stride events are valid; on trials without a handrail
channel (e.g., `'OG'`, or any `'TM'`/`'IN'` session collected without
one), all three parameters simply stay `NaN`.

`abs()` is used so that both pushing down on the rail (weight support)
and pulling up on it (recovering balance from a backward fall) count
toward "holding."

**Threshold rationale:** the 5% BW cutoff is the documented "light
touch" ceiling from the instrumented-handrail literature (e.g.,
Buffum et al., *Treadmill Handrail-use Increases the Anteroposterior
Margin of Stability in Individuals Post-stroke*, PMC10957321; casual/
light-touch vertical forces there were ~1–2% BW). `>5% BW` therefore
means "more than light touch," not necessarily heavy weight-bearing.
Adjust `handrailHoldFractionBW` in `computeForceParameters.m` if a
stricter definition is needed for your study. See also Brown & Kesar,
*Handrail Holding During Treadmill Walking Reduces Locomotor Learning
in Able-Bodied Persons* (IEEE TNSRE, 2019; PMID 31425041), on why
handrail use is worth flagging for adaptation studies.

**Only vertical force (`HFz`) is used**, not fore-aft or
medial-lateral, based on an alongside-treadmill handrail placement
(matching the cited literature). If your handrail sits in front of the
participant rather than alongside, or if validation on your data shows
holding shows up mainly in `HFy`, consider using the `HFy`+`HFz` vector
magnitude instead (see the legacy `computeForceParameters_OGFP.m` for
that approach).

### Known Channel-Numbering Caveat

`processGRFData` maps analog force channel **3** to the handrail
prefix `H`; some collections and legacy loaders instead assume the
handrail is channel **4** (see the warning text and `fpPrefixMap` in
`processGRFData.m`). If `HandrailHolding`/`HandrailForceNorm`/
`HandrailForceN` are `NaN` for every stride of a session you know had
an instrumented handrail, verify which analog channel your load cell
was actually wired to
before assuming no data was collected. Some older collections instead
label the channel `X` rather than `H`; `computeForceParameters` falls
back to `XFz` in that case and issues a warning.

### Censoring Handrail-Held Strides

`HandrailHolding` is informational only — strides are **not**
automatically excluded from analysis. To drop (or NaN) strides where
the handrail was held:

```matlab
% Removes handrail-held strides (ORed with the existing 'bad' column):
adaptData = adaptData.removeHandrailStrides();

% Or NaN them instead of removing rows:
adaptData = adaptData.removeHandrailStrides(true);
```

`removeHandrailStrides` returns the object unchanged (with a warning)
if `HandrailHolding` is absent or entirely `NaN` for that subject.
