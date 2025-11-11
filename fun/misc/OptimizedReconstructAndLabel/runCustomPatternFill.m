function runCustomPatternFill(vicon, refMap)

% runCustomPatternFill: applies pattern fill using marker specific
% reference markers
%
% Inputs:
%   vicon - initialized ViconNexus() object
%   refMap - containers.Map of target marker names to reference marker
%   names

markers = refMap.keys;

for i = 1:numel(markers)
    targetMarker = markers{i};
    refMarker = refMap(targetMarker);
    
    try
        % Apply pattern fill for the target marker using the reference
        % marker
        vicon.PatterFillGap(targetMarker, refMarker);
        fprintf('Pattern filled %s using %s. \n', targetMarker, refMarker);
    catch ME
        warning('Could not pattern fil %s with %s: %s', ...
            targetMarker, refMarker, ME.message);
    end
end
end


