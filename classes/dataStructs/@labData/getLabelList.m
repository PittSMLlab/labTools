function list = getLabelList(this, fieldName)
%GETLABELLIST Returns list of labels from specified field.
%
%   list = getLabelList(this, fieldName) returns the labels property from
% the specified field
%
% Inputs:
%   this      - labData object
%   fieldName - name of property to access (e.g., 'markerData', ...
%               'EMGData')
%
% Outputs:
%   list - cell array of label strings
%
% Toolbox Dependencies: None
%
% See also GETPARTIALDATA.

list = this.(fieldName).labels;
end

