function [h, adaptDataObject] = parameterEvolutionPlot(this, field)
%parameterEvolutionPlot  Plots parameter evolution across conditions
%
%   [h, adaptDataObject] = parameterEvolutionPlot(this, field)
%   creates a plot showing how the specified parameter evolves across
%   experimental conditions
%
%   Inputs:
%       this - experimentData object
%       field - parameter label to plot
%
%   Outputs:
%       h - figure handle
%       adaptDataObject - adaptationData object used for plotting
%
%   Note: This function takes a long time to run. For efficiency,
%         generate and save an adaptData object, then use its plotting
%         functions directly.
%
%   See also: parameterTimeCourse, adaptationData/plotParamByConditions

% ???
%
% INPUTS:
% field,
if ~(this.isProcessed)
    ME = MException('experimentData:parameterEvolutionPlot', ...
        ['Cannot generate parameter evolution plot from ' ...
        'unprocessed data!']);
    throw(ME);
end
if ~isempty(this.data{1}) && ...
        (all(this.data{1}.adaptParams.isaLabel(field)))
    adaptDataObject = this.makeDataObj([], 0);
    h = adaptDataObject.plotParamByConditions(field);
else
    % Creating adaptationData object, to include experimentalParams
    % (which are Dependent and need to be computed each time).
    % Otherwise we could just access this.data{trial}.experimentalParams
    adaptDataObject = this.makeDataObj;
    h = adaptDataObject.plotParamByConditions(field);
end
end

