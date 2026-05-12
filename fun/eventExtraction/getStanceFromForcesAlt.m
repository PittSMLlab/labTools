function stance = getStanceFromForcesAlt(Fz, lowThreshold, fsample)
%GETSTANCEFROMFORCESALT Estimate stance phase using force derivative thresholding.
%
%   Alternative to GETSTANCEFROMFORCES. Detects stance by identifying
% loading and unloading regions in the force derivative, then expands
% those regions inward/outward until they meet. A morphological shortening
% compensates for low-pass filter broadening, and short phases are removed.
%
% Inputs:
%   Fz           - N×1 double, vertical GRF signal (N, sign arbitrary)
%   lowThreshold - scalar double, ignored (overwritten internally; retained
%                  for API compatibility)
%   fsample      - scalar double, sampling frequency (Hz)
%
% Outputs:
%   stance - N×1 logical, stance phase (true = stance)
%
% Toolbox Dependencies: None
%
% See also GETSTANCEFROMFORCES, DELETESHORTPHASES, GETEVENTSFROMFORCES.

fcut = 25; % lowpass cutoff frequency (Hz)
coarseFilteredFz = medfilt1(Fz, round(0.0025 * fsample)); % median filter: 2.5 ms window
forces    = lowpassfiltering2(coarseFilteredFz, fcut, 2, fsample);
forceSign = sign(mean(Fz, 'omitnan'));
forces    = forces * forceSign; % ensure forces are positive on average

% Factor of 2 scales the mean absolute deviation to a full-range estimate
% (half-range × 2 ≈ peak-to-peak ≈ body weight for a typical GRF signal)
bodyWeight = 2 * mean(abs(forces - mean(forces)));

LOADING_MULT   = 3; % loading  rate threshold (× body weight per second)
UNLOADING_MULT = 4; % unloading rate threshold (× body weight per second)

forceDiff    = diff(forces) * fsample;
lowThreshold = bodyWeight;
loading      = forceDiff >  LOADING_MULT   * bodyWeight;
unloading    = forceDiff < -UNLOADING_MULT * bodyWeight;
unstance     = abs(forceDiff) < lowThreshold; % threshold in N/s

% expand loading zone rightwards and unloading leftwards until they meet
while any(diff(loading) == -1 & ~unloading(1:end-1))
    % inward expansion
    loading(2:end)   = loading(2:end) | (loading(1:end-1) & ~unloading(1:end-1));
    unloading(1:end-1) = unloading(1:end-1) ...
        | (unloading(2:end) & ~loading(2:end));
end
while any(diff(loading) == 1 & ~unstance(1:end-1)) ...
        || any(diff(unloading) == -1 & ~unstance(2:end))
    % outward expansion
    loading(1:end-1)   = loading(1:end-1) | (loading(2:end) & ~unstance(1:end-1));
    unloading(2:end)   = unloading(2:end) | (unloading(1:end-1) & ~unstance(2:end));
end
stance = loading | unloading;

%% Shorten stance phases to compensate for low-pass filter broadening
% Erode by applying a length-N kernel and requiring all N values to be
% stance. This removes up to N-1 samples from each phase boundary to undo
% broadening introduced by low-pass filtering (half-width ≈ fsample / (2*fcut)).
N      = round(0.5 * fsample / fcut);
stance = conv(double(stance), ones(N, 1), 'same') > N - 1;

%% Eliminate stance and swing phases shorter than 100 ms
stance = deleteShortPhases(stance, fsample, 0.1); % used to be 200 ms, but too long for stroke subjects

end
