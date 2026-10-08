function OTS = getOTSfromOrientedData(data, t0, Ts, labelPrefixes, ...
    orientation)
%GETOTSFROMORIENTEDDATA Creates OTS from 3D data array.
%
%   OTS = getOTSfromOrientedData(data, t0, Ts, labelPrefixes, orientation)
% creates orientedLabTimeSeries from oriented data
%
% Inputs:
%   data          - 3D matrix (time x markers x 3)
%   t0            - initial time
%   Ts            - sampling period
%   labelPrefixes - cell array of marker prefixes
%   orientation   - orientationInfo object
%
% Outputs:
%   OTS - orientedLabTimeSeries object
%
% Toolbox Dependencies: None
%
% See also GETORIENTEDDATA, ADDLABELSUFFIX.

% Static
labels = [strcat(labelPrefixes, 'x'); strcat(labelPrefixes, 'y'); ...
    strcat(labelPrefixes, 'z')];
data = permute(data, [1, 3, 2]);
OTS = orientedLabTimeSeries(data(:, :), t0, Ts, labels(:), ...
    orientation);
end

