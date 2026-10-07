function flag = isempty(this)
%ISEMPTY Checks if the date equals the default value.
%
%   Determines whether the date equals the default sentinel date (Jan 1,
% 1900), which is used to represent an uninitialized labDate.
%
% Inputs:
%   this - labDate object
%
% Outputs:
%   flag - true if date equals default value, else false
%
% Toolbox Dependencies: None
%
% See also DEFAULT, TIMESINCE.

flag = timeSince(this, labDate.default()) == 0;
end

