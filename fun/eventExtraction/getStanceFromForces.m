function stance = getStanceFromForces(Fz, threshold, fsample)
%GETSTANCEFROMFORCES Estimate stance phase from vertical ground reaction force.
%
%   Applies median filtering to remove quantization noise, corrects for
% non-zeroed force plates, and thresholds the result to produce a binary
% stance signal. Short stance and swing phases below 100 ms are removed.
%
% Inputs:
%   Fz        - N×1 double, vertical GRF signal (N, sign arbitrary)
%   threshold - scalar double, stance detection threshold (N)
%   fsample   - scalar double, sampling frequency (Hz)
%
% Outputs:
%   stance - N×1 logical, stance phase (true = stance)
%
% Toolbox Dependencies: None
%
% See also GETSTANCEFROMFORCESALT, DELETESHORTPHASES, GETEVENTSFROMFORCES.

%% Get stance from forces
N = round(0.01 * fsample); % median filter window: 10 ms
if mod(N, 2) == 0
    N = N + 1;
end
N1 = round(0.005 * fsample); % median filter window: 5 ms
if mod(N1, 2) == 0
    N1 = N1 + 1;
end
forces = medfilt1(Fz, N1);
forces = medfilt1(forces, N);

% sanity check: correct non-zeroed force plates
if mode(forces) ~= 0
    warning('getStanceFromForces:nonZeroMode', ...
        ['Vertical GRF has non-zero mode. ' ...
         'Subtracting mode from force data before event detection.']);
    forces = forces - mode(forces);
end

forceSign = sign(mean(forces, 'omitnan')); % use filtered forces in case plates were not zeroed
forces    = forces * forceSign; % ensure forces are positive on average

stance = forces > threshold;

%% Eliminate stance and swing phases shorter than 100 ms
stance = deleteShortPhases(stance, fsample, 0.1); % used to be 200 ms, but that is too long for stroke subjects

end
