function flag = isempty(this)
%isempty  Checks if date equals default value
%
%   flag = isempty(this) determines if the date equals the default
%   date (1 Jan 1900)
%
%   Inputs:
%       this - labDate object
%
%   Outputs:
%       flag - true if date equals default value, false otherwise
%
%   See also: default, timeSince

% If date equals default value, considering empty
flag = timeSince(this, labDate.default) == 0;
end

