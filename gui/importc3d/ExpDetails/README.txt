ExpDetails — Experiment Description Files
=========================================

Overview
--------
This folder contains experiment description MAT files used by GetInfoGUI.
Each file defines the condition structure for one experiment group and
appears as a selectable option in the GetInfoGUI experiment description
dropdown menu.

To add a new experiment description, run Template.m (or a renamed copy of it)
after editing it to match your experimental design. The file will be saved
here automatically.

To remove a description from the GetInfoGUI dropdown without permanently
deleting it, move the corresponding MAT file to the Archive/ subfolder. It
will no longer appear in the dropdown but can be retrieved at any time by
moving it back here.

Naming Convention
-----------------
Files are named using only the alphabetic characters of the experiment
group name defined in Template.m (e.g., 'OlderAdultsAbrupt'). Use
descriptive, specific names to avoid conflicts with future experiments.
Recommended format: <Population><Perturbation><Year>
  e.g., OlderAdultsAbrupt2022.mat
        YoungAdultsSplitBelt2024.mat

Active Experiment Descriptions
-------------------------------
The files currently in this folder and the studies they correspond to are
listed below. Update this table whenever a file is added or archived.

  File Name                      | Study Description                  | Created    | Author
  -------------------------------|------------------------------------|-----------|---------
  EDIT.mat                       | EDIT                               | YYYY-MM-DD | Initials
  EDIT.mat                       | EDIT                               | YYYY-MM-DD | Initials

Notes
-----
- EDIT: add any lab-specific notes, conventions, or caveats here.