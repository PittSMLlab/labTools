function [filteredData] = filtfilthd(filterObj,data,method)
warning('Using filtfilthd_short instead of filtfilthd for efficiency purposes. filtfilthd will be deprecated from pitools soon.')
if nargin<3
    method='reflect'; %Default
end
[filteredData] = filtfilthd_short(filterObj,data,method,[]);
%Deprecate on May 6th 2018

%Filters data along dim=1 with filterObj first forwards, and then
%backwards.
%It is an implementation of filtfilt that works with filter objects from
%the DSP toolbox.
%Uses 'reflect' method for dealing with borders.

if size(data,1)==1 
    warning('filtfiltHD expects input data to be entered as columns, transposing')
    data=data';
end
if size(data,1)<size(data,2)
    warning('Input data seems to be organized as rows, and filtfilthd filters along columns.')
end
%FILTFILTHD Zero-phase filter with reflective boundary handling.
%
%   Deprecated wrapper — delegates entirely to FILTFILTHD_SHORT.
% Use FILTFILTHD_SHORT directly for new code.
%
% Inputs:
%   filterObj - DSP toolbox filter object
%   data      - (N×C) double, data to filter (columns are channels)
%   method    - char, boundary method ('reflect' or other); default 'reflect'
%
% Outputs:
%   filteredData - (N×C) double, zero-phase filtered data
%
% Toolbox Dependencies: DSP System Toolbox (for filter objects)
%
% See also FILTFILTHD_SHORT.

M=size(data,1);

if nargin < 3
    method = 'reflect';
end
    switch method
        case 'reflect'
            pre=[data(end:-1:1,:)];
            post=[data(end:-1:1,:)];
        otherwise         
            pre=[];
            post=[];
    end
filteredData=filter(filterObj,[pre;data;post]);
filteredData=filter(filterObj,filteredData(end:-1:1,:));
filteredData=filteredData(end:-1:1,:);
filteredData=filteredData([size(pre,1)+1:size(pre,1)+M],:);

end
