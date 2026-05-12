function stance = deleteShortPhases(stance, fsample, minDuration)
%DELETESHORTPHASES Remove stance or swing phases shorter than a minimum
%duration.
%
%   Iteratively applies a morphological open/close operation (convolution-
% based dilation then erosion) to eliminate phases whose duration is less
% than minDuration seconds. Operates on a logical stance vector.
%
% Inputs:
%   stance      - N×1 logical, stance phase signal (true = stance)
%   fsample     - scalar double, sampling frequency (Hz)
%   minDuration - scalar double, minimum phase duration to retain (s)
%
% Outputs:
%   stance - N×1 logical, stance signal with short phases removed
%
% Toolbox Dependencies: None
%
% See also GETSTANCEFROMFORCES, GETSTANCEFROMTOENANDHEEL.

N = ceil(minDuration * fsample);

if ~isempty(stance)
    for ii = 1:N
        % NOTE: iteratively applies a morphological opening. Each iteration
        % applies a window of radius ii: a sample survives only if at least
        % half+1 of its neighbours are stance. After N iterations, any run
        % shorter than N samples has been eroded to zero and removed.
        stance = conv(double(stance), ones(2*ii+1, 1), 'same') > ii;
    end
end

end
