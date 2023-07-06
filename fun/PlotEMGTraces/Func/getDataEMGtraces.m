function [data]=getDataEMGtraces(expData,muscle,cond,leg,late,strides,IgnoreStridesEarly)
%% get time series EMG data 
% This function returns the EMG as a time series
%
%INPUTS: 
    %expData - file to extract the data 
    %muscle - list with the muscle that you want to get data for 
    %cond - condition of interest
    %leg - leg of interest 
    %late - 1 if you want to plot the last strides 0 if yo uwant to plot
    %the initial strides 
    %strides - number of strides that you want to plot 
 %OUTPUT: 
    %data - Timeseries of the data
%
%EXAMPLE: 
    %data=getDataEMGtraces(expData,{'TA'},{'TM base'},'R',1,40);
    %This will give us the average of the last 40 strides of for the TA muscle
    %during treadmill baseline 
    

%%
alignmentLengths=[16,32,16,32];
% events={'kinRHS','kinLTO','kinLHS','kinRTO'};
events={'RHS','LTO','LHS','RTO'};
if leg=='R'
    data=expData.getAlignedField('procEMGData',cond,events,alignmentLengths).getPartialDataAsATS({['R' muscle]});
elseif leg=='L'
    data=expData.getAlignedField('procEMGData',cond,events([3,4,1,2]),alignmentLengths).getPartialDataAsATS({['L' muscle]});
else
    error('leg input is either L or R')
end

if late==1
    data=data.getPartialStridesAsATS(size(data.Data,3)-strides:size(data.Data,3));
    
elseif late==0
    if size(data.Data,3)>strides
        
        data=data.getPartialStridesAsATS(IgnoreStridesEarly:strides+IgnoreStridesEarly);
    else
        data=data.getPartialStridesAsATS(IgnoreStridesEarly:size(data.Data,3)+IgnoreStridesEarly);
        warning(strcat([cond{1}, ' does not have ', num2str(strides),' strides']))
    end
else
    error('Input the type of data that you want late=1')
end
    



end
