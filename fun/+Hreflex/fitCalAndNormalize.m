function [fit,amplitudesWavesNorm] = fitCalAndNormalize(intensitiesStim,amplitudesWaves)
%FITCALANDNORMALIZE Fit M- & H-wave recruitment curves & normalize data
%   This function accepts the stimulation intensities and H- and M-wave
% amplitudes for the right and left legs as input and fits a modified
% hyperbolic function to the M-wave data and an asymmetric Gaussian to the
% H-wave data based on the Brinkworth et al. (J. Neurosci. Methods, 2007)
% paper (Section 2.4 Curve Fitting) and outputs normalized data for
% convenience (by the fitted Mmax value).
%
% input(s):
%   intensitiesStim: 2 x 1 cell array of number of stimuli x 1 arrays for
%       right (cell 1) and left (cell 2) leg stimulation amplitudes (i.e.,
%       intensity of the constant current stimulation pulse in mA)
%   amplitudesWaves: 2 x 2 cell array of number of stimuli x 1 arrays for
%       right (row 1) and left (row 2) leg H-reflex amplitudes: M-wave
%       (column 1), H-wave (column 2)
% output(s):
%   fit: structure of M-wave and H-wave fit function, optimized parameters,
%       and maximum fit M value for normalization
%   amplitudesWavesNorm: 2 x 2 cell array of number of stimuli x 1 arrays
%       for right (row 1) and left (row 2) leg H-reflex amplitudes
%       normalized to the maximum M-wave fit value: M-wave (column 1),
%       H-wave (column 2)

% define the modified hyperbolic function for M-wave fitting: p(1) = Mmax,
% p(2) = I_50 (half-saturation intensity), p(3) = c (slope parameter)
modHyperbolic = @(p,I) (p(1) * (p(3).^I)) ./ (p(2) + (p(3).^I));

% define the asymmetric Gaussian function for H-wave fitting: p(1) = Hmax,
% p(2) = Ipeak (mu/mean), p(3) = sigma, p(4) = c (asymmetry slope parameter
asymGaussian = @(p,I) ...
    p(1) * exp(-((I - p(2)).^2) ./ (2 * (p(3) + (I - p(2)).^2 * p(4))));
% NOTE: Brinkworth et al. (J. Neurosci. Methods, 2007) uses the below
% asymmetric Gaussian, which does not appear to fit the data as well
% asymGaussian = @(p,I) p(1) * exp(-((I.^p(4) - p(2)).^2) / (2 * p(3)^2));
% p(1) = Hmax, p(2) = Ipeak, p(3) = width, p(4) = asymmetry (c)

fit = struct;                       % initialize output cal. fit structure
fit.M.modHyperbolic = modHyperbolic;
fit.H.asymGaussian = asymGaussian;
amplitudesWavesNorm = cell(2,2);    % initialized normalized data output

for leg = 1:2                           % for each leg, ...
    % if no data for one leg, ...
    if isempty(intensitiesStim{leg}) || isempty(amplitudesWaves{leg,1})
        warning("No data available for leg %d. Skipping.",leg);
        continue;                       % advance to next leg
    end

    I = intensitiesStim{leg};           % stimulation intensities (mA)
    M = amplitudesWaves{leg,1};         % M-wave amplitudes
    H = amplitudesWaves{leg,2};         % H-wave amplitudes

    % ===== fit M-wave data using non-linear least squares =====
    try
        p0M = [max(M) median(I) 1.2];   % initial guess: Mmax, I50, c
        paramsM = nlinfit(I,M,modHyperbolic,p0M);
    catch
        warning("M-wave fitting failed for leg %d. Using defaults.",leg);
        paramsM = [max(M) median(I) 1.2];   % default fallback
    end

    MmaxFit = paramsM(1);       % extract Mmax from fit for normalization
    amplitudesWavesNorm{leg,1} = M ./ MmaxFit;      % normalize M-wave data
    amplitudesWavesNorm{leg,2} = H ./ MmaxFit;      % normalize H-wave data

    % ===== fit H-wave data using non-linear least squares =====
    try
        IU = unique(I);         % find unique stimulation amplitudes
        avgsH = arrayfun(@(x) mean(H(I == x),'omitnan'),IU);
        [valHmax,locHmax,width] = findpeaks(avgsH,IU,'NPeaks',1);
        if isempty(valHmax)
            [valHmax,indHmax] = max(H);
            locHmax = I(indHmax);
            width = std(I);
        end
        p0H = [valHmax locHmax width 1];% initial guess: Hmax, Ipeak, sigma, c
        paramsH = nlinfit(I,H,asymGaussian,p0H);
    catch
        warning("H-wave fitting failed for leg %d. Using defaults.",leg);
        paramsH = [max(H) median(I) std(I) 1];  % default fallback
    end

    if leg == 1     % if right leg, ...
        fit.M.R.params = paramsM;
        fit.M.R.Mmax = MmaxFit;
        fit.H.R.params = paramsH;
    else            % otherwise, left leg
        fit.M.L.params = paramsM;
        fit.M.L.Mmax = MmaxFit;
        fit.H.L.params = paramsH;
    end
end

end

