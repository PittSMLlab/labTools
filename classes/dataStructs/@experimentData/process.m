function processedThis = process(this, eventClass)
%process  Processes raw data for all trials
%
%   processedThis = process(this) processes all trials in the
%   experiment, calculating events, angles, and adaptation parameters
%
%   processedThis = process(this, eventClass) optionally specifies
%   event class for parameter calculation
%
%   Inputs:
%       this - experimentData object
%       eventClass - optional event classification parameter
%
%   Outputs:
%       processedThis - experimentData object with processed data
%
%   Example:
%       expData = rawExpData.process
%
%   See also: labData/process, recomputeParameters

% process  process full experiment
%
% Returns a new experimentData object with same metaData, subData and
% processed (trial) data. This is done by iterating through data
% (trials) and processing each by using labData.process
% ex: expData = rawExpData.process
%
% INPUTS:
% this: experimentData object
%
% OUTPUTS:
% processedThis: experimentData object with processed data
%
% See also: labData

if nargin < 2 || isempty(eventClass)
    eventClass = [];
end

for trial = 1:length(this.data)
    disp(['Processing trial ' num2str(trial) '...'])
    if ~isempty(this.data{trial})
        procData{trial} = this.data{trial}.process(this.subData, ...
            eventClass);
    else
        procData{trial} = [];
    end
end
% this = checkMarkerHealth(this);
processedThis = experimentData(this.metaData, this.subData, procData);
end

