# Unapproved WIP Changes (stash@{0} as Patches)

Local changes that were in the working tree before the 2026-10
clean-up, saved as `stash@{0}` ("pre-cleanup WIP") on one machine. The
stash no longer applies to the restyled files, so these patches
re-express each change on top of the current code. **None of them is
approved.** Decide each with the lab, then apply it (and run the
before/after comparison in [TESTING.md](../TESTING.md)) or delete it.
Once all four are decided, delete this folder. Listed in
[FUTURE.md](../FUTURE.md) section 5.

| Patch | Change | Risk |
|---|---|---|
| `getEventsFromForces.patch` | force threshold 10 N -> 60 N (shifts force events by ~12 ms) | High |
| `getKinematicDataAbs.patch` | walking-direction sign from events [3 5] (FHS..SHS2) instead of [4 5]; renames `aux` to `walkDirSign` | High |
| `plotMultipleEpochBars.patch` | `removeBadStrides` on every group; `hold off` | Medium |
| `plotAvgTimeCourse.patch` | `maxNumPts = true`; drops `removeBiasFlag == 3` and the perceptual-task alignment; legend/patch changes | Medium |

Apply one file at a time from the repo root (checked 2026-10-21: all
four apply to master):

    git apply --ignore-whitespace --whitespace=nowarn stash-patches/<name>.patch

Each patched file matches the stash version except for the clean-up's
renames (`i`/`j` -> `ii`), `'omitnan'` forms and named constants. The
stash's cosmetic hunks in `ReviewEventsGUI` and `PlotParamsGUI`
(SliderStep reorder, `global expData` removal in
`save_button_Callback`, deleted commented-out code) were not carried
over. Their code repairs were committed separately.
