function partialData = getPartialData(this, fieldName, labels)
%getPartialData  Returns requested data from specified field
%
%   partialData = getPartialData(this, fieldName) returns all data from the
%   specified field
%
%   partialData = getPartialData(this, fieldName, labels) returns only the
%   specified labels from the field
%
%   Inputs:
%       this - labData object
%       fieldName - name of property to access (e.g., 'markerData', ...
%                   'EMGData')
%       labels - cell array or string of label(s) to extract (optional)
%
%   Outputs:
%       partialData - extracted data as vector or full object if no labels
%                     specified
%
%   See also: getLabelList

if nargin < 3 || isempty(labels)
    partialData = this.(fieldName);
else
    partialData = this.(fieldName).getDataAsVector(labels);
end
end

