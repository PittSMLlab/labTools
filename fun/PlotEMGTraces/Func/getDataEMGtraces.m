function data = getDataEMGtraces(expData,muscle,cond,leg,late,strides, ...
    IgnoreStridesEarly,IgnoreStridesLate)
%GETDATAEMGTRACES Get aligned EMG traces of one muscle and leg.
%
%   Returns the processed EMG of one muscle, aligned to the gait cycle on
% the events RHS, LTO, LHS, RTO (left leg: LHS, RTO, RHS, LTO) with
% alignment lengths of 16, 32, 16, and 32 samples, for the last or first
% strides of a condition.
%
% Side effects: warns when the condition has fewer strides than requested;
%   errors for an invalid leg or too few strides to skip.
%
% Inputs:
%   expData            - experimentData to read from
%   muscle             - muscle name without side prefix, e.g., 'TA'
%   cond               - cell array with the condition name
%   leg                - 'R' or 'L'
%   late               - 1 for the last strides, 0 for the first strides
%   strides            - number of strides to return
%   IgnoreStridesEarly - number of initial strides to skip
%   IgnoreStridesLate  - (optional) number of final strides to skip
%
% Outputs:
%   data - alignedTimeSeries of the selected strides
%
% Toolbox Dependencies: None
%
% EXAMPLE:
%   data = getDataEMGtraces(expData,'TA',{'TM base'},'R',1,40,[],[]);
%   returns the last 40 strides of the right TA during treadmill baseline.
%
% See also PLOTEMGTRACES.

%% Align the EMG
alignmentLengths = [16,32,16,32];
% events={'kinRHS','kinLTO','kinLHS','kinRTO'};
events = {'RHS','LTO','LHS','RTO'};
if leg == 'R'
    data = expData.getAlignedField('procEMGData',cond,events, ...
        alignmentLengths).getPartialDataAsATS({['R' muscle]});
elseif leg == 'L'
    data = expData.getAlignedField('procEMGData',cond,events([3,4,1,2]), ...
        alignmentLengths).getPartialDataAsATS({['L' muscle]});
else
    error('leg input is either L or R')
end


if late == 1 & ~isempty(IgnoreStridesLate)
    if size(data.Data,3) > (strides+IgnoreStridesLate)
        data = data.getPartialStridesAsATS(size(data.Data, ...
            3)-IgnoreStridesLate-strides:size(data.Data, ...
            3)-IgnoreStridesLate-1);
    else
        error(['The are less strides than expected. Check why this ' ...
            'might be the case.']);
    end
elseif late == 1 & isempty(IgnoreStridesLate)
    data = data.getPartialStridesAsATS(size(data.Data, ...
        3)-strides:size(data.Data,3));
elseif late == 0
    if size(data.Data,3) > strides
        data = data.getPartialStridesAsATS( ...
            IgnoreStridesEarly:strides+IgnoreStridesEarly);
    else
        data = data.getPartialStridesAsATS( ...
            IgnoreStridesEarly:size(data.Data,3)+IgnoreStridesEarly);
        warning(strcat([cond{1}, ' does not have ', num2str(strides), ...
            ' strides']))
    end
else
    error('Input the type of data that you want late=1')
end



end
