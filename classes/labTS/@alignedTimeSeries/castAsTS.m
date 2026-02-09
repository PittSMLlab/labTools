function newThis = castAsTS(this)
%castAsTS  Converts to labTimeSeries
%
%   newThis = castAsTS(this) converts alignedTimeSeries to
%   labTimeSeries
%
%   Inputs:
%       this - alignedTimeSeries object
%
%   Outputs:
%       newThis - labTimeSeries object
%
%   Note: Temp function until alignedTS inherits from labTS. Requires
%         single stride.
%
%   See also: concatenateAsTS, catStrides

if size(this.Data, 3) > 1
    ME = MException('alignedTS:castAsTS', ...
        ['To cast as TS, there may be a single alignedTS (i.e. ' ...
        'size(this.Data, 3) == 1)']);
    throw(ME);
end
newThis = labTimeSeries(this.Data, this.Time(1), ...
    this.Time(2) - this.Time(1), this.labels);
end

