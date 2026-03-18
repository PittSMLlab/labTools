function labelPref = getLabelPrefix(this)
%getLabelPrefix  Returns label prefixes without x/y/z
%
%   labelPref = getLabelPrefix(this) returns marker/variable prefixes
%   by removing x/y/z suffixes
%
%   Inputs:
%       this - orientedLabTimeSeries object
%
%   Outputs:
%       labelPref - cell array of label prefixes
%
%   Example:
%       this.labels = {'RPSISx', 'RPSISy', 'RPSISz', 'LPSISx', ...}
%       labelPref = getLabelPrefix(this)
%       labelPref = {'RPSIS', 'LPSIS', ...}
%
%   See also: addLabelSuffix, isaLabelPrefix

% isolate correct prefixes
aux = cellfun(@(x) x(1:end - 1), this.labels, 'UniformOutput', false);
% remove duplicate prefixes for each marker
labelPref = aux(1:3:end);
end

