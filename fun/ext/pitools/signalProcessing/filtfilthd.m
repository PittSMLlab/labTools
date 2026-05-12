function filteredData = filtfilthd(filterObj, data, method)
%FILTFILTHD Zero-phase filter with reflective boundary handling.
%
%   Deprecated wrapper — delegates entirely to FILTFILTHD_SHORT.
% Use FILTFILTHD_SHORT directly for new code.
%
% Inputs:
%   filterObj - DSP toolbox filter object
%   data      - (N×C) double, data to filter (columns are channels)
%   method    - char, boundary method ('reflect' or other); default 'reflect'
%
% Outputs:
%   filteredData - (N×C) double, zero-phase filtered data
%
% Toolbox Dependencies: DSP System Toolbox (for filter objects)
%
% See also FILTFILTHD_SHORT.

warning('filtfilthd:deprecated', ...
    'Use filtfilthd_short directly. filtfilthd will be removed.');

if nargin < 3
    method = 'reflect';
end
filteredData = filtfilthd_short(filterObj, data, method, []);

end
