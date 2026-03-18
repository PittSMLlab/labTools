function [fh, ph, this] = assessMissing(this, labelPrefixes, fh, ph)
%assessMissing  Assesses missing data
%
%   [fh, ph, this] = assessMissing(this) creates plot showing missing
%   markers
%
%   [fh, ph, this] = assessMissing(this, labelPrefixes, fh, ph) uses
%   specified labels and handles
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       labelPrefixes - marker prefixes to assess (optional, currently
%                       ignored - uses all)
%       fh - figure handle (optional, -1 to suppress display)
%       ph - plot handle (optional)
%
%   Outputs:
%       fh - figure handle
%       ph - plot handle
%       this - orientedLabTimeSeries with Quality field updated
%
%   See also: labTimeSeries/assessMissing

if nargin < 3 || isempty(fh)
    fh = figure();
elseif fh == -1
    noDisp = true;
    ph = [];
else
    figure(fh);
    if nargin < 4
        ph = gca;
    else
        axes(ph);
    end
end
% if nargin < 2
labelPrefixes = this.getLabelPrefix; % Ignoring labelPrefixes input
% end
data = this.getOrientedData(labelPrefixes);
missing = any(isnan(data), 3);
miss = missing(:, any(missing));
if ~noDisp
    pp = plot(miss, 'o');
    aux = labelPrefixes(any(missing));
    for i = 1:length(pp)
        set(pp(i), 'DisplayName', [aux{i} ' (' ...
            num2str(sum(miss(:, i))) ' frames)']);
    end
    legend(pp);
    title('Missing markers');
    xlabel('Time (frames)');
    set(gca, 'YTick', [0 1], 'YTickLabel', {'Present', 'Missing'});
else
    fprintf(['Missing data in ' num2str(sum(any(missing, 2))) '/' ...
        num2str(size(missing, 1)) ' frames, avg. ' ...
        num2str(sum(missing(:)) / sum(any(missing, 2)), 3) ...
        ' per frame.\n']);
end
if isempty(this.Quality)
    this.Quality = zeros(size(this.Data));
end
Q = zeros(size(missing));
Q(missing) = -1;
for j = 1:3 % x, y, z
    this.Quality(:, j:3:end) = Q;
end
end

