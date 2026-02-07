function newThis = appendData(this, newData, newLabels, newDesc)
%appendData  Appends new parameters
%
%   newThis = appendData(this, newData, newLabels) appends new
%   parameters without descriptions
%
%   newThis = appendData(this, newData, newLabels, newDesc) appends
%   with descriptions
%
%   Inputs:
%       this - parameterSeries object
%       newData - matrix of new parameter values (same number of rows)
%       newLabels - cell array of labels for new parameters
%       newDesc - cell array of descriptions (optional)
%
%   Outputs:
%       newThis - parameterSeries with appended parameters
%
%   Note: For backward compatibility
%
%   See also: cat, addNewParameter

if nargin < 4 || isempty(newDesc)
    newDesc = cell(size(newLabels));
end
other = parameterSeries(newData, newLabels, this.hiddenTime, newDesc, ...
    this.trialTypes);
newThis = cat(this, other);
end

