function filteredData = filtfilthd_short(filterObj, data, method, M1)
%FILTFILTHD_SHORT Zero-phase filter with length-limited reflective padding.
%
%   Implements zero-phase filtering using a DSP toolbox filter object by
% applying the filter forward and then backward. Reflective boundary
% padding reduces edge transients; the padding length is capped at M1
% samples (default 1000) for efficiency on long signals.
%
% Inputs:
%   filterObj - DSP toolbox filter object
%   data      - (N×C) double, data to filter (columns are channels)
%   method    - char, boundary method: 'reflect' (default) pads with a
%               mirrored copy; any other value uses no padding
%   M1        - scalar integer, reflection pad length (samples); [] uses
%               default
%
% Outputs:
%   filteredData - (N×C) double, zero-phase filtered data
%
% Toolbox Dependencies: DSP System Toolbox (for filter objects)
%
% See also FILTFILTHD.

DEFAULT_REFLECT_LEN = 1000;  % default reflection pad length (samples)

if size(data, 1) == 1
    warning('filtfilthd_short:rowInput', ...
        'Data appears to be a row vector; transposing to column.');
    data = data';
end
if size(data, 1) < size(data, 2)
    warning('filtfilthd_short:rowMajor', ...
        'Input data has more columns than rows; filtering along columns.');
end

M = size(data, 1);

if nargin < 3 || isempty(method)
    method = 'reflect';
end
if nargin < 4 || isempty(M1)
    M1 = min(DEFAULT_REFLECT_LEN, M);
    warning('filtfilthd_short:defaultPad', ...
        sprintf('Reflection pad length unspecified; using %d samples.', M1));
else
    M1 = min(round(M1), M);
end
%filteredData=filtfilt(filterObj,[pre;data;post]); %This should work, and
%is possibly more efficient, but doesn't.

switch method
    case 'reflect'
        pre  = data(M1:-1:1, :);
        post = data(end:-1:end-M1+1, :);
    otherwise
        pre  = [];
        post = [];
end

filteredData = filter(filterObj, [pre; data; post]);
filteredData = filter(filterObj, filteredData(end:-1:1, :));
filteredData = filteredData(end:-1:1, :);
filteredData = filteredData((M1 + 1):(M1 + M), :);

end
