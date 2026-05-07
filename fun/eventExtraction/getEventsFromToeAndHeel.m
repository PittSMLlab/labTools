function [LHS, RHS, LTO, RTO] = ...
    getEventsFromToeAndHeel(Ltoe, Lheel, Rtoe, Rheel, fsample)
%GETEVENTSFROMTOENANDHEEL Detect gait events from toe and heel marker data.
%
%   Estimates stance phases from heel and toe marker kinematics, derives
% gait events from those phases, and masks out events that occur before
% meaningful limb activity begins (onset detection via cumulative energy).
%
% Inputs:
%   Ltoe    - N×3 double, left toe marker position (mm)
%   Lheel   - N×3 double, left heel marker position (mm)
%   Rtoe    - N×3 double, right toe marker position (mm)
%   Rheel   - N×3 double, right heel marker position (mm)
%   fsample - scalar double, sampling frequency (Hz)
%
% Outputs:
%   LHS - N×1 logical, left heel-strike events
%   RHS - N×1 logical, right heel-strike events
%   LTO - N×1 logical, left toe-off events
%   RTO - N×1 logical, right toe-off events
%
% Toolbox Dependencies: None
%
% See also GETSTANCEFROMTOENANDHEEL, GETEVENTSFROMSTANCE.

% retrieve stance gait phases from toe and heel markers
stanceL = getStanceFromToeAndHeel(Lheel, Ltoe, fsample);
stanceR = getStanceFromToeAndHeel(Rheel, Rtoe, fsample);

% retrieve gait events from stance phase
[LHS, RHS, LTO, RTO] = getEventsFromStance(stanceL, stanceR);
badInds = any(isnan(Lheel')) | any(isnan(Ltoe')) ...
    | any(isnan(Rheel')) | any(isnan(Rtoe'));
LHS(badInds) = false;
RHS(badInds) = false;
LTO(badInds) = false;
RTO(badInds) = false;

% eliminate any events that occur prior to actual activity in the trial
ENERGY_FRAC = 0.001; % 0.1% of total cumulative energy used as onset threshold

rHeelShifted   = Rheel(:, 1) - Rheel(1, 1); % zero initial value (right)
rHeelCumEnergy = cumsum(rHeelShifted .^ 2);
begin_index1   = find(rHeelCumEnergy > ENERGY_FRAC * rHeelCumEnergy(end), 1);

lHeelShifted   = Lheel(:, 1) - Lheel(1, 1); % zero initial value (left)
lHeelCumEnergy = cumsum(lHeelShifted .^ 2);
begin_index2   = find(lHeelCumEnergy > ENERGY_FRAC * lHeelCumEnergy(end), 1);

begin_index = max([begin_index1 begin_index2]);

LHS(1:begin_index) = false;
RHS(1:begin_index) = false;
LTO(1:begin_index) = false;
RTO(1:begin_index) = false;

% verify that all gait events are consistent
% consistent = checkEventConsistency(LHS,RHS,LTO,RTO);

end
