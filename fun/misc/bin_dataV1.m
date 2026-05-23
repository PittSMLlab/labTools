function [xnew, xnewstd] = bin_dataV1(x, binwidth)
%BIN_DATAV1 Compute a running average along the rows of a matrix.
%
%   Computes a causal sliding-window mean and standard deviation for
% each row of X using a window of BINWIDTH rows. Written by GTO,
% April 14 2009.
%
% Inputs:
%   x        - N×M numeric matrix
%   binwidth - number of rows in each sliding window
%
% Outputs:
%   xnew    - running-average matrix (N-binwidth+1) × M
%   xnewstd - running standard deviation, same size as xnew
%
% Toolbox Dependencies: None
%
% See also RUNAVG, MEAN.
if size(x, 1) >= binwidth
    if binwidth == 1
        xnew    = x;
        xnewstd = zeros(size(x, 1), size(x, 2));
    else
        bstart = 1:size(x, 1) - (binwidth - 1);    % window start indices
        bend   = bstart + binwidth - 1;             % window end indices
        bend(bend > size(x, 1)) = size(x, 1);

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
    % fewer strides than binwidth — use all available strides
    warning(['Running average could not use the provided binwidth ' ...
        '(' num2str(binwidth) ') because of too few strides (' ...
        num2str(size(x, 1)) '). Using available strides only.'])
    xnew    = mean(x, 'omitnan');
    xnewstd = std(x, 0, 'omitnan');
end

% NOTE: alternative causal implementation (no NaN handling):
%   if size(x,1) >= binwidth
%       N    = binwidth;
%       xnew = conv2(x, ones(N,1)/N, 'valid');
%       xnewstd = conv2(x.^2, ones(N,1)/N, 'valid') - xnew.^2;
%   end
end
