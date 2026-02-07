function this = times(this, constant)
%times  Multiplies by constant
%
%   this = times(this, constant) multiplies data by constant and
%   updates labels
%
%   Inputs:
%       this - alignedTimeSeries object
%       constant - scalar or array to multiply by
%
%   Outputs:
%       this - scaled alignedTimeSeries
%
%   See also: plus, minus

this.Data = this.Data .* constant;
if numel(constant) == 1
    s = num2str(constant);
else
    s = 'k'; % Generic constant string
end
this.labels = strcat([s '*'], this.labels);
end

