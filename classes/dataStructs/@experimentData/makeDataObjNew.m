function adaptData = makeDataObjNew(this, filename, experimentalFlag, ...
    contraLateralFlag)
%makeDataObjNew  Internal method to create adaptationData object
%
%   adaptData = makeDataObjNew(this, filename, experimentalFlag,
%   contraLateralFlag) creates adaptationData object with full control
%   over parameters
%
%   Inputs:
%       this - experimentData object
%       filename - string for saving (optional)
%       experimentalFlag - if false, excludes experimental parameters
%                          (optional)
%       contraLateralFlag - if true, uses non-reference leg for
%                           computation (optional)
%
%   Outputs:
%       adaptData - adaptationData object
%
%   Note: This function may not be compatible with certain methods of
%         the adaptationData class
%
%   See also: makeDataObj, adaptationData

% This function may not be compatible with certain methods of the
% adaptationData class

if isempty(contraLateralFlag) || contraLateralFlag == 0
    % Normal parameters
    % nop
else
    % Computing all parameters on a contraLateral way (this is, we
    % compute parameters using the NON reference leg as the 'slow'
    % one, opposite to the default computation)
    if strcmp(this.getRefLeg, 'R')
        initEventSide = 'L';
    elseif strcmp(this.getRefLeg, 'L')
        initEventSide = 'R';
    else
        ME = MException('makeDataObject:ContralateralComputation', ...
            ['Could not determine proper reference leg for this ' ...
            'experiment.']);
        throw(ME);
    end
    % Using default event class ('', as opposed to 'force' or 'kin')
    this = recomputeParameters(this, [], initEventSide);
end

for i = 1:length(this.data) % Trials
    if ~isempty(this.data{i}) && ~isempty(this.data{i}.adaptParams)
        % Get data from this trial:
        aux = this.data{i}.adaptParams;
        trialTypes{i} = this.data{i}.metaData.type;
        if ~(nargin > 2 && ~isempty(experimentalFlag) && ...
                experimentalFlag == 0)
            aux = cat(aux, this.data{i}.experimentalParams);
        end
        % Concatenate with other trials:
        % Case in which no strides were detected for a trial, it
        % could happen. Not concatenating those
        if ~isempty(aux.Data)
            if ~exist('paramData', 'var')
                paramData = aux;
            else
                paramData = addStrides(paramData, aux);
            end
        end
    end
end
% HH: remove all bad strides completely
% paramData = parameterSeries(paramData.Data(paramData.bad == 0, :), paramData.labels, paramData.hiddenTime(paramData.bad == 0), paramData.description);
paramData = paramData.setTrialTypes(trialTypes);
adaptData = adaptationData(this.metaData, this.subData, paramData);
if nargin > 1 && ~isempty(filename)
    % HH edit 2/12 - added 'params' to file name so experimentData
    % file isn't overwritten
    save([filename 'params.mat'], 'adaptData', '-v7.3');
end
end

