function refLeg = getRefLeg(this)
%getRefLeg  Returns reference leg for parameter computations
%
%   refLeg = getRefLeg(this) determines the reference leg by majority vote
%   over all trials in the experiment
%
%   Inputs:
%       this - experimentData object
%
%   Outputs:
%       refLeg - 'R' or 'L'
%
%   See also: getNonRefLeg, getSlowLeg

refLeg = {};
for i = 1:length(this.data) % Going over trials
    if ~isempty(this.data{i})
        refLeg{i} = this.data{i}.metaData.refLeg;
    end
end
Rvotes = sum(strcmp(refLeg, 'R'));
Lvotes = sum(strcmp(refLeg, 'L'));
if Rvotes > Lvotes
    refLeg = 'R';
elseif Rvotes < Lvotes
    refLeg = 'L';
else
    error('experimentData:getRefLeg', ...
        'Could not determine unique reference leg');
end
end

