function processedThis = process(this, eventClass)
%process  Processes raw data for all trials in experimental session
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
%       expData = rawExpData.process();
%
%   See also: labData/process, recomputeParameters

if nargin < 2 || isempty(eventClass)
    eventClass = [];
end

for trial = 1:length(this.data)
    disp(['Processing trial ' num2str(trial) '...']);
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

