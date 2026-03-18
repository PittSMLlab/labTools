function newThis = referenceToMarker(this, marker)
%referenceToMarker  References data to marker position
%
%   newThis = referenceToMarker(this, marker) translates data so
%   specified marker is at origin
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       marker - marker prefix to use as reference
%
%   Outputs:
%       newThis - translated orientedLabTimeSeries
%
%   Note: marker needs to be a prefix of this object
%
%   See also: translate

% Check: marker needs to be a suffix of this object.
data = getOrientedData(this, marker);
newThis = translate(this, squeeze(-1 * data));
end

