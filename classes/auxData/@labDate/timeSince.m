function timeInMonths = timeSince(this, other)
%TIMESINCE Calculates elapsed time from another date.
%
%   Approximates fractional months by assuming 30 days per month.
%
% Inputs:
%   this  - labDate object (later date)
%   other - labDate object (earlier date)
%
% Outputs:
%   timeInMonths - Elapsed time in months (approximate; assumes 30 days per
%                  month)
%
% Example:
%   d1     = labDate(1, 'jan', 2015);
%   d2     = labDate(1, 'jun', 2015);
%   months = d2.timeSince(d1);  % returns 5
%
% Toolbox Dependencies: None
%
% See also ISEMPTY.

monthsPerYear = 12; % calendar months
daysPerMonth  = 30; % approximation stated in the description

timeInMonths = monthsPerYear * (this.year  - other.year)  + ...
    (this.month - other.month) + ...
    (this.day   - other.day) / daysPerMonth;
end

