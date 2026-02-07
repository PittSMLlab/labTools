function [fh, ph, missing] = assessMissing(this, labels, fh, ph)
%assessMissing  Assesses and plots missing data
%
%   [fh, ph, missing] = assessMissing(this) creates plot showing
%   missing data patterns
%
%   [fh, ph, missing] = assessMissing(this, labels, fh, ph) plots
%   specified labels in existing figure
%
%   Inputs:
%       this - labTimeSeries object
%       labels - labels to assess (optional, default: all)
%       fh - figure handle (optional, -1 to suppress display)
%       ph - plot handle (optional)
%
%   Outputs:
%       fh - figure handle
%       ph - plot handle
%       missing - logical matrix indicating missing samples
%
%   See also: substituteNaNs

noDisp = false;
if nargin < 3 || isempty(fh)
    fh = figure();
elseif fh == -1
    noDisp = true;
else
    figure(fh);
    if nargin < 4
        ph = gca;
    else
        axes(ph);
    end
end

if nargin < 2
    labels = this.labels;
end
data = this.getDataAsVector(labels);
missing = isnan(data);
miss = missing(:, any(missing));

if ~noDisp
    pp = plot(miss, 'o');
    aux = labels(any(missing));
    for i = 1:length(pp)
        set(pp(i), 'DisplayName', [aux{i} ' (' num2str(sum(miss(:, i))) ...
            ' frames)']);
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
end

