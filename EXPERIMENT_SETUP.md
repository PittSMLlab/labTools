# EXPERIMENT_SETUP.md — Configuring New Experiments

This guide covers two setup tasks that are specific to each study or
lab configuration:

1. [Adding a New Experiment Type](#adding-a-new-experiment-type)
2. [Marker Label Mapping](#marker-label-mapping)

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
