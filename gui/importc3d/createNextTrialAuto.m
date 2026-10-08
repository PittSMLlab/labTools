function [nextTrial, curTrl] = createNextTrialAuto(curTrl, sepTime, newName)
% Separate 1 trial into 2 using the sepTime, curTrl will be from [0,
% sepTime) and nextTrail will be from [sepTime, end)
%
% OUTPUTARGS: -nextTrial: labData object (e.g., a trial in rawExpData or
%                    expData) representing a new trial from [sepTime, end)
%             -curTrl: labData object (e.g., a trial in rawExpData or
%                    expData) representing a new trial from [0, sepTime)
% INPUTARGS:
%           - curTrl: labData object (e.g., a trial in rawExpData or
%                    expData) to separate
%           - sepTime: double, time (in seconds) to separate the trial, the
%                time is relative to the start of the original trial (1st
%                trial processed from c3d2mat)
%           - newName: string, name of the nextTrial.
% Examples: see SepCondsInExpByAudioCue.m
%
% $Author: Shuqi Liu $  $Date: 2024/05/22 13:24:55 $    $Revision: 0.1 $
% Copyright: Sensorimotor Learning Laboratory 2024

% from sep (inclusive) to end (end omitted: defaults to trial end)
nextTrial = curTrl.split(sepTime);
nextTrial.metaData.name = newName;
% NaN start defaults to the trial start, giving [startOfCurTrl, sep) so
% sepTime is included only once (in nextTrial).
curTrl = curTrl.split(nan, sepTime);
end