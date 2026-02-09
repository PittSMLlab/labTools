function newThis = cat(this, other)
%cat  Concatenates two parameterSeries
%
%   newThis = cat(this, other) concatenates parameters from two
%   parameterSeries with same number of strides
%
%   Inputs:
%       this - parameterSeries object
%       other - parameterSeries object with same stride count
%
%   Outputs:
%       newThis - concatenated parameterSeries
%
%   See also: addStrides, appendData

if size(this.Data, 1) == size(other.Data, 1)
    if isempty(this.description)
        thisDescription = cell(size(this.labels));
    else
        thisDescription = this.description(:);
    end
    if isempty(other.description)
        otherDescription = cell(size(other.labels));
    else
        otherDescription = other.description(:);
    end
    newThis = parameterSeries([this.Data other.Data], ...
        [this.labels(:); other.labels(:)], this.hiddenTime, ...
        [thisDescription; otherDescription], this.trialTypes);
    % this.Data = [this.Data other.Data];
    % this.labels = [this.labels; other.labels];
    % this.description = [this.description; other.description];
else
    error('parameterSeries:cat', ...
        'Cannot concatenate series with different number of strides');
end
end

