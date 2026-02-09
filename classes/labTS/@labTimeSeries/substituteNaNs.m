function this = substituteNaNs(this, method)
%substituteNaNs  Replaces NaN by interpolation
%
%   this = substituteNaNs(this) fills NaN values using linear
%   interpolation
%
%   this = substituteNaNs(this, method) uses specified interpolation
%   method
%
%   Inputs:
%       this - labTimeSeries object
%       method - interpolation method for interp1 (optional, default:
%                'linear')
%
%   Outputs:
%       this - labTimeSeries with NaN filled
%
%   Note: Labels with all NaN set to 0. Quality field updated to mark
%         interpolated samples.
%
%   See also: fillts, interp1

if nargin < 2 || isempty(method)
    method = 'linear';
end
badColumns = sum(~isnan(this.Data)) < 2;
% Returns true if any TS contained in the data is all NaN
if any(badColumns)
    % FIXME: This throws an exception now, but it should just return all
    % NaN labels as all NaN and substitute missing values in the others.
    warning('labTimeSeries:substituteNaNs', ...
        ['timeseries contains at least one label that is all (or ' ...
        'all but one sample) NaN. Can''t replace those values (no ' ...
        'data to use as reference), setting to 0.']);
    this.Data(:, badColumns) = 0;
end
% this.Quality = zeros(size(this.Data), 'int8');
aux = isnan(this.Data);
for i = 1:size(this.Data, 2) % Going through labels
    auxIdx = aux(:, i);
    % Extrapolation values are filled with 0
    this.Data(auxIdx, i) = interp1(this.Time(~auxIdx), ...
        this.Data(~auxIdx, i), this.Time(auxIdx), method, 0);
end
% Saving quality data (to mark which samples were interpolated): Matlab's
% timeseries stores this as int8. I would have preferred a sparse array.
this.Quality = int8(aux);
this.QualityInfo.Code = [0 1];
this.QualityInfo.Description = {'good', 'missing'};
end

