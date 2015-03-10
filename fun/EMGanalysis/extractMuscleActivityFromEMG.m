function [procData,filteredData,filterList,procList] =extractMuscleActivityFromEMG(data,fs,f_cut,BW,notchList)
% Extract EMG amplitude. Wrapper for filterEMG + amp_estim functions.

N=size(data,2); %Number of channels
if nargin<3
    f_cut=10;
end
if nargin<4
    BW=[];
end
if nargin<5
    notchList=[];
end

    [filteredData,filterList] = filterEMG(data,fs,BW,notchList); %Does a band-pass filter of the data, and removes some specific frequencies through notch-filters
    
    [procData,procList]=amp_estim(filteredData,fs,1,f_cut); %Amplitude estimation. 3rd argument defines order of estimation.
    
end

