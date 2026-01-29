function [stridedField,bad,initTime,events]=getStridedField(...
    this,field,events)
%getStridedField  Extracts field data organized by stride
%
%   [stridedField,bad,initTime,events] = getStridedField(this,
%   field,events) extracts the specified field data and
%   organizes it by stride based on the provided events
%
%   Inputs:
%       field - name of the data field to extract
%       events - event label or cell array of event labels
%                defining stride boundaries
%
%   Outputs:
%       stridedField - cell array of time series data organized
%                      by stride
%       bad - logical vector indicating strides with incomplete
%             or missing events
%       initTime - vector of stride start times
%       events - cell array of event labels used
%
%   Note: This method is very slow and has been deprecated.
%         Please don't use.
%
%   See also: getAlignedField, getStrideInfo

warning(['This is very slow and has been deprecated. '...
    'Please don''t use'])
if isa(events,'char')
    events={events};
end
%Step 1: separate strides by the first event
[numStrides,initTime,endTime]=getStrideInfo(this,events{1});
M=numStrides;
N=length(events);
%Step 2: for each stride, find the other events (if any)
intermediateTimes=nan(M,N-1);
bad=false(M,1);
for i=1:M
    for j=1:N-1
        aux=find(this.gaitEvents.getDataAsVector(...
            events{j+1}) & ...
            this.gaitEvents.Time>=initTime(i) & ...
            this.gaitEvents.Time<endTime(i));
        if length(aux)==1 %Found only one event, as expected
            intermediateTimes(i,j) = ...
                this.gaitEvents.Time(aux);
        else
            bad(i)=true;
        end
    end
end
%Step 3: slice timeseries
timeBreakpoints=[initTime, intermediateTimes]';
[slicedTS,~,~]=sliceTS(this.(field),...
    [timeBreakpoints(:); endTime(end)],0);

%Step 4: reshape & set to [] the slices which didn't have
%proper events
stridedField=reshape(slicedTS,N,M)';
end

