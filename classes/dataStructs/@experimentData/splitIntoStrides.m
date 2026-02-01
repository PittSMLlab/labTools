function stridedExp = splitIntoStrides(this, refEvent)
%splitIntoStrides  Separates trials into individual strides
%
%   stridedExp = splitIntoStrides(this) splits all trials into
%   individual strides using default reference event
%
%   stridedExp = splitIntoStrides(this, refEvent) splits using
%   specified reference event
%
%   Inputs:
%       this - experimentData object
%       refEvent - event label for stride boundaries (optional,
%                  default: refLeg HS)
%
%   Outputs:
%       stridedExp - stridedExperimentData object containing strided
%                    trials
%
%   Note: This might not be used?
%
%   See also: stridedExperimentData, processedLabData/separateIntoStrides

% This might not be used?
if ~this.isStepped && this.isProcessed
    for trial = 1:length(this.data)
        disp(['Splitting trial ' num2str(trial) '...']);
        trialData = this.data{trial};
        if ~isempty(trialData)
            if nargin < 2 || isempty(refEvent)
                refEvent = [trialData.metaData.refLeg, 'HS'];
                % Assuming that the first event of each stride should be
                % the heel strike of the refLeg! (check c3d2mat - refleg
                % should be opposite the dominant/fast leg)
            end
            aux = trialData.separateIntoStrides(refEvent);
            strides{trial} = aux;
        else
            strides{trial} = [];
        end
    end
    stridedExp = stridedExperimentData(this.metaData, ...
        this.subData, strides);
else
    disp(['Cannot stride experiment because it is raw or already ' ...
        'strided.']);
end
end

