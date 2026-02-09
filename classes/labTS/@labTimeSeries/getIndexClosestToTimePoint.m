function index = getIndexClosestToTimePoint(this, timePoints)
%getIndexClosestToTimePoint  Finds index nearest to time point
%
%   index = getIndexClosestToTimePoint(this, timePoints) returns
%   indices of samples closest to specified time points
%
%   Inputs:
%       this - labTimeSeries object
%       timePoints - vector or array of time points
%
%   Outputs:
%       index - indices of nearest samples (NaN returns NaN)
%
%   See also: getSample

% aux = abs(bsxfun(@minus, this.Time(:), timePoints(:)')) <= ...
%     (this.sampPeriod / 2 + eps);
% [ii, jj] = find(aux);
% index = nan(size(timePoints));
% index(jj) = ii;
index = round((timePoints(:) - this.Time(1)) / this.sampPeriod) + 1;
index(index < 1) = 1;
index(index > numel(this.Time)) = numel(this.Time);
index = reshape(index, size(timePoints));
% Check
% if any(abs(this.Time(index(:)) - timePoints(:)) >
%     (this.sampPeriod / 2 - eps))
%     error('Non consistent indices found');
% end
end

