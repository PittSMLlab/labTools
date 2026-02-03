function [h, adaptDataObject] = parameterTimeCourse(this, field)
%parameterTimeCourse  Plots parameter time course
%
%   [h, adaptDataObject] = parameterTimeCourse(this, field) creates a
%   plot showing the specified parameter over time/strides
%
%   Inputs:
%       this - experimentData object
%       field - parameter label to plot
%
%   Outputs:
%       h - figure handle
%       adaptDataObject - adaptationData object used for plotting
%
%   Note: This function takes a long time to run. For efficiency, generate
%         and save an adaptData object, then use its plotting functions
%         directly.
%
%   See also: parameterEvolutionPlot, adaptationData/plotParamTimeCourse

if ~(this.isProcessed)
    ME = MException('experimentData:parameterTimeCourse', ...
        ['Cannot generate parameter time course plot from ' ...
        'unprocessed data!']);
    throw(ME);
end
if ~isempty(this.data{1}) && ...
        (all(this.data{1}.adaptParams.isaLabel(field)))
    adaptDataObject = this.makeDataObj([], 0);
    h = adaptDataObject.plotParamTimeCourse(field);
else
    % Creating adaptationData object, to include experimentalParams
    % (which are Dependent and need to be computed each time).
    % Otherwise we could just access this.data{trial}.experimentalParams
    adaptDataObject = this.makeDataObj;
    h = adaptDataObject.plotParamTimeCourse(field);
end
end

