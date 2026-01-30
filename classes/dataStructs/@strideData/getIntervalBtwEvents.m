function interval = getIntervalBtwEvents(this, event1, event2)
%getIntervalBtwEvents  Extracts data between two gait events
%
%   interval = getIntervalBtwEvents(this, event1, event2)
%   extracts a segment of the stride between the specified events
%
%   Inputs:
%       this - strideData object
%       event1 - label of starting event (e.g., 'LHS', 'RTO')
%       event2 - label of ending event (e.g., 'RHS', 'LTO')
%
%   Outputs:
%       interval - strideData object containing the extracted
%                  interval
%
%   See also: split, getDoubleSupportLR, getSingleStanceL

if strcmp(this.initialEvent, event1)
    t0 = this.gaitEvents.Time(1);
else
    t0 = this.gaitEvents.Time(find(...
        this.gaitEvents.getDataAsVector({event1}) == 1, 1));
end
if strcmp(this.initialEvent, event2)
    t1 = this.gaitEvents.Time(end) + this.gaitEvents.sampPeriod;
else
    t1 = this.gaitEvents.Time(find(...
        this.gaitEvents.getDataAsVector({event2}) == 1, 1));
end
if t1 <= t0
    ME = MException('strideData:GetInterval', ...
        ['The requested interval does not exist as such on ' ...
        'this stride.']);
    throw(ME)
end
interval = this.split(t0, t1);
end

