function [filteredData] = filtfilthd(filterObj,data,method)

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

M=size(data,1);

if nargin<3
    method='reflect'; %Default
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

