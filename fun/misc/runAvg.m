function [xnew, xnewstd]=runAvg(x,binwidth,dim)
rows=size(x,1);
cols=size(x,2);

if ~isempty(x)
    if binwidth==1
        xnew=x;
        xnewstd=zeros(rows,cols);
    else
        if rows>=cols || (nargin>2 && dim==1) %average rows
            for  i=1:rows
                t1=max([1 i-floor(binwidth/2)]);
                t2=min([rows i+ceil(binwidth/2)]);
                
                xnew(i,:) = nanmean(x(t1:t2,:),1);
                xnewstd(i,:) = nanstd(x(t1:t2,:),[],1);                
            end
        elseif cols>rows || (nargin>2 && dim==2) %average columns
            for  i=1:cols
                t1=max([1 i-floor(binwidth/2)]);
                t2=min([cols i+ceil(binwidth/2)]);
                
                xnew(:,i) = nanmean(x(:,t1:t2),2);
                xnewstd(:,i) = nanstd(x(:,t1:t2),[],2);                
            end
        else
            warning('Dimension entered not correct')
            xnew=[];
            xnewstd=[];
        end
    end
else
    xnew=[];
    xnewstd=[];
end
%RUNAVG Compute a running (sliding-window) average of a matrix.
%
%   Computes a running average of X along the larger dimension (rows
% or columns) or along the dimension specified by DIM. BINWIDTH sets
% the number of samples in each window. Based on bin_dataV1 written
% by GTO, April 14 2009.
%
% Inputs:
%   x        - numeric matrix to average
%   binwidth - number of samples in the sliding window
%   dim      - (optional) dimension to average along: 1 = rows,
%              2 = columns; defaults to the larger dimension
%
% Outputs:
%   xnew    - running-average matrix, same size as X
%   xnewstd - running standard deviation, same size as X
%
% Toolbox Dependencies: None
%
% See also BIN_DATAV1, MEAN.
