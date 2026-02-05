function newThis = appendData(this, newData, newLabels)
%appendData  Adds new parameters to dataset
%
%   newThis = appendData(this, newData, newLabels) creates a new
%   paramData object with additional parameters appended
%
%   Inputs:
%       this - paramData object
%       newData - matrix of new parameter values (same number of rows
%                 as existing Data)
%       newLabels - cell array of labels for new parameters
%
%   Outputs:
%       newThis - paramData object with appended data
%
%   See also: paramData

% Modifiers:
newThis = paramData([this.Data newData], [this.labels newLabels], ...
    this.indsInTrial, this.trialTypes);
end

