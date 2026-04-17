function out = computeHSparameters(someTS, gaitEvents, eventType)
% computeHSparameters  Compute heel-strike-aligned parameters per stride.
%
%   Syntax:
%     out = computeHSparameters(tsData, gaitEvents, eventTypes)
%
%   Extracts the value of each channel in tsData at the slow and fast
% heel strike events for each stride, and returns a parameterSeries
% object that can be concatenated with other parameter series objects
% (e.g., from computeTemporalParameters).
%
%   Inputs:
%     tsData     - labTimeSeries object whose channels will be sampled
%                  at each heel strike event
%     gaitEvents - labTimeSeries of gait events for the trial
%     eventTypes - Cell array of gait event type strings as constructed
%                  in calcParameters (e.g., {'LHS','RTO','RHS','LTO'}),
%                  or a single char specifying the slow leg ('L' or 'R')
%
%   Outputs:
%     out - parameterSeries object containing one parameter per channel
%           per leg, sampled at each stride's heel strike
%
%   Toolbox Dependencies:
%     None
%
%   See also: computeAngleParameters, computeTemporalParameters,
%     computeSpatialParameters, computeForceParameters, parameterSeries,
%     calcParameters

%TODO: this should be a method of labTS

%get slow heel strikes times
% T_HS=labTimeSeries.getArrayedEvents(gaitEvents,{[slowleg 'HS'],[getOtherLeg(slowleg) 'HS']});
T_HS = labTimeSeries.getArrayedEvents(gaitEvents, eventType);
nstrides = size(T_HS, 1);
%keyboard
% iSHS=find(ismember(someTS.Time,T_HS(2:end,1)));
% iFHS=find(ismember(someTS.Time,T_HS(1:end-1,2)));

% iSHS=find(ismember(someTS.Time,round(strideEvents.tSHS2,6)));
% iFHS=find(ismember(someTS.Time,round(strideEvents.tFHS,6)));

%extract parameters
Ang_SHS=squeeze(someTS.getSample(T_HS(2:end, 1)));

try
    Ang_FHS=squeeze(someTS.getSample(T_HS(1:end-1, 2)));
catch
    Ang_FHS = NaN(size(Ang_SHS));%NEEDS FIX
    disp('no gait events for fast leg!')
end

%rename labels
Slabs = strcat(someTS.labels, {'AtSHS'});
Flabs = strcat(someTS.labels, {'AtFHS'});
%Ang_SHS=Ang_SHS.renameLabels(Ang_SHS.labels,strcat(Ang_SHS.labels,{'@SHS'}));
%Ang_FHS=Ang_FHS.renameLabels(Ang_FHS.labels,strcat(Ang_FHS.labels,{'@FHS'}));
PangSHS = parameterSeries(Ang_SHS(:, :), Slabs, [], Slabs);
PangFHS = parameterSeries(Ang_FHS(:, :), Flabs, [], Flabs);
out = cat(PangSHS, PangFHS);

end

