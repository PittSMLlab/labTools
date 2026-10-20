function this = times(this, constant)
%TIMES Multiplies data by constant.
%
%   this = times(this, constant) multiplies all data by a constant and
% updates labels
%
% Inputs:
%   this     - labTimeSeries object
%   constant - scalar or vector to multiply by
%
% Outputs:
%   this - labTimeSeries with scaled data
%
% Toolbox Dependencies: None
%
% See also PLUS, MINUS.

this.Data = this.Data .* constant;
if numel(constant) == 1
    s = num2str(constant);
else
    s = 'k'; % Generic constant string
end
this.labels = strcat([s '*'], this.labels);
end

