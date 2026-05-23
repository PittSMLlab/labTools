function runCustomPatternFill(vicon, refMap)
%RUNCUSTOMPATTERNFILL Apply pattern fill using marker-specific references.
%
%   Iterates over all target markers in refMap and fills trajectory gaps
% in each using the associated reference marker via the Vicon Nexus SDK.
%
% Inputs:
%   vicon  - Initialized ViconNexus() object
%   refMap - containers.Map mapping target marker names to reference
%            marker names
%
% Outputs:
%   None
%
% Toolbox Dependencies: None
%
% See also GETPATTERNFILLREFERENCEMAP.

markers = refMap.keys();

for mrkr = 1:numel(markers)
    targetMarker = markers{mrkr};
    refMarker    = refMap(targetMarker);
    try
        vicon.PatterFillGap(targetMarker, refMarker);
        fprintf('Pattern filled %s using %s.\n', targetMarker, refMarker);
    catch ME
        warning('Could not pattern fill %s with %s: %s', ...
            targetMarker, refMarker, ME.message);
    end
end

end
