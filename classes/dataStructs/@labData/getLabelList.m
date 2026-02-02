function list = getLabelList(this, fieldName)
%getLabelList  Returns list of labels from specified field
%
%   list = getLabelList(this, fieldName) returns the labels property from
%   the specified field
%
%   Inputs:
%       this - labData object
%       fieldName - name of property to access (e.g., 'markerData', ...
%                   'EMGData')
%
%   Outputs:
%       list - cell array of label strings
%
%   See also: getPartialData

list = this.(fieldName).labels;
end

