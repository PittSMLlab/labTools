function processedThis = process(this, eventClass)
% process  Processes raw data for all trials in the experimental session.
%
%   processedThis = process(this) processes all trials using the
%   default gait event detection method.
%
%   processedThis = process(this, eventClass) uses the specified
%   gait event detection method.
%
%   Inputs:
%     this       - experimentData object containing raw trial data
%     eventClass - (optional) String specifying the gait event
%                  detection method. Defaults to '' if omitted:
%                    ''      - default (forces for TM trials,
%                              kinematics otherwise)
%                    'kin'   - strictly from kinematics
%                    'force' - strictly from forces
%
%   Outputs:
%     processedThis - experimentData object with processed trial data
%
%   Example:
%     expData = rawExpData.process();
%     expData = rawExpData.process('kin');
%
%   Toolbox Dependencies:
%     None
%
%   See also: labData/process, recomputeParameters, loadSubject

arguments
    this
    eventClass (1,:) char = ''
end

for trial = 1:length(this.data)
    disp(['Processing trial ' num2str(trial) '...']);
    if ~isempty(this.data{trial})
        procData{trial} = this.data{trial}.process( ...
            this.subData, eventClass);
    else
        procData{trial} = [];
    end
end
% this = checkMarkerHealth(this);
processedThis = experimentData(this.metaData, this.subData, procData);
end

