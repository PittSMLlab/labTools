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
forceSign = sign(mean(Fz));
forces    = forces * forceSign; % ensure forces are positive on average

% highThreshold=prctile(abs(forceDiff),80); % Choosing threshold such that only 20% of samples are above it
bodyWeight   = 2 * mean(abs(forces - mean(forces))); % estimated body weight for thresholding
forceDiff    = diff(forces) * fsample;
lowThreshold = bodyWeight;
loading      = forceDiff > 3 * bodyWeight;
unloading    = forceDiff < -4 * bodyWeight;
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
N      = round(0.5 * fsample / fcut);
stance = conv(double(stance), ones(N, 1), 'same') > N - 1;

%% Eliminate stance and swing phases shorter than 100 ms
stance = deleteShortPhases(stance, fsample, 0.1); % used to be 200 ms, but too long for stroke subjects

% figure
% hold on
% plot([1:length(forces)]/fsample,forces)
% plot((.5+[1:length(forces)-1])/fsample,forceDiff)
% plot((.5+[1:length(forces)-1])/fsample,stance*max(forces))
% plot([1,length(forces)]/fsample,lowThreshold*[1,1],'k--')
% plot([1:length(forces)]/fsample,Fz*forceSign)
% xlabel('Time (ms)')
% legend('Filtered forces','Force derivative','Detected Stance','Low threshold','Raw forces')
% hold off

end
