function [xnew, xnewstd] = binData(x, binwidth)
%BINDATA Compute a running average and standard deviation of columns.
%
%   Averages binwidth-element windows of the columns in x and returns
% both the average and the standard deviation. Returned arrays have
% N - (binwidth - 1) rows, where N = size(x, 1).
%
% Inputs:
%   x        - Numeric matrix (rows × columns) or column vector
%   binwidth - Integer window width; must be ≤ size(x, 1)
%
% Outputs:
%   xnew    - Running-average matrix, same number of columns as x
%   xnewstd - Running standard deviation, same size as xnew
%
% Toolbox Dependencies: None
%
% See also BIN_DATAV1, SMOOTHEDMAX.

if ~isempty(x)
    if binwidth == 1
        xnew    = x;
        xnewstd = zeros(size(x, 1), size(x, 2));
    elseif binwidth > size(x, 1)
        ME = MException('binData:InvalidInput', ...
            'binwidth is larger than x.');
        throw(ME);
    else
        bstart = 1:size(x, 1) - (binwidth - 1);
        bend   = bstart + binwidth - 1;
        if any(bend > size(x, 1))
            bend(bend > size(x, 1)) = size(x, 1);
            warning(['The end elements of binned data may not be ' ...
                'averages of binwidth elements'])
        end

        for ii = 1:length(bstart)
            t1 = bstart(ii);
            t2 = bend(ii);
            if t2 == t1
                xnew(ii, :)    = NaN * zeros(1, size(x, 2)); %#ok<AGROW>
                xnewstd(ii, :) = NaN * zeros(1, size(x, 2)); %#ok<AGROW>
            else
                xnew(ii, :)    = mean(x(t1:t2, :), 'omitnan'); %#ok<AGROW>
                xnewstd(ii, :) = std(x(t1:t2, :), 0, 'omitnan'); %#ok<AGROW>
            end
        end
    end
else
    xnew    = [];
    xnewstd = [];
end

end
