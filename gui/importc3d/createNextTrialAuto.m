function [nextTrial, curTrl] = createNextTrialAuto(curTrl, sepTime, newName)
%CREATENEXTTRIALAUTO Split one trial in two at a given time.
%
%   CURTRL keeps the samples in [0, SEPTIME) and NEXTTRIAL receives the
% samples in [SEPTIME, end]. NEXTTRIAL is renamed to NEWNAME.
%
% Inputs:
%   curTrl  - labData object (e.g., a trial in rawExpData or expData) to
%             split
%   sepTime - time (s) of the split, relative to the start of the
%             original trial (the first trial processed by c3d2mat)
%   newName - name of NEXTTRIAL
%
% Outputs:
%   nextTrial - labData object for the interval [sepTime, end]
%   curTrl    - labData object for the interval [0, sepTime)
%
% Toolbox Dependencies: None
%
% See also SEPCONDSINEXPBYAUDIOCUE, LABDATA.
%
% $Author: Shuqi Liu $  $Date: 2024/05/22 13:24:55 $  $Revision: 0.1 $
% Copyright: Sensorimotor Learning Laboratory 2024

%% Split the trial
% from sep (inclusive) to end (end omitted: defaults to trial end)
nextTrial = curTrl.split(sepTime);
nextTrial.metaData.name = newName;
% NaN start defaults to the trial start, giving [startOfCurTrl, sep) so
% sepTime is included only once (in nextTrial).
curTrl = curTrl.split(nan, sepTime);
end
