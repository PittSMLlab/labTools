function fit = fitCal(intensitiesStim,amplitudesWaves)
%FITCAL Fit M- & H-wave recruitment curves
%   This function accepts the stimulation intensities and H- and M-wave
% amplitudes for the right and left legs as input and fits a modified
% hyperbolic function to the M-wave data (equation 1) and an asymmetric
% Gaussian to the H-wave data (modified from equation 2) based on the
% Brinkworth et al. (J. Neurosci. Methods, 2007) paper (Section 2.4 Curve
% Fitting).
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

% TODO:
%   1. compare fits using only the averages at each intensity with all data
%   2. compare fits using weighted least squares (by variance at each
%   amplitude) with a mixed effects model approach
%   3. compare fits of modified hyperbolic, standard hyperbolic, and
%   logistic sigmoid for M-wave recruitment data
%   4. compare fits of standard Gaussian, asymmetric Gaussian (power on
%   intensities), and asymmetric Gaussian (shift of denominator) for H-wave

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

for leg = 1:2                       % for each leg, ...
    % if no data for one leg, ...
    if isempty(intensitiesStim{leg}) || isempty(amplitudesWaves{leg,1})
        warning("No data available for leg %d. Skipping.",leg);
        continue;                   % advance to next leg
    end

    if leg == 1                     % if right leg, ...
        idLeg = 'R';
    else                            % otherwise, left leg
        idLeg = 'L';
    end

    I = intensitiesStim{leg};       % stimulation intensities (mA)
    M = amplitudesWaves{leg,1};     % M-wave amplitudes
    H = amplitudesWaves{leg,2};     % H-wave amplitudes

    % ========== fit M-wave data using non-linear least squares ==========
    try
        % initialize coefficients: Mmax, I_50, c
        p0M = [max(M) median(I) 1.2];
        paramsM = nlinfit(I,M,modHyperbolic,p0M);
    catch
        warning("M-wave fitting failed for leg %d. Using defaults.",leg);
        paramsM = [max(M) median(I) 1.2];       % default fallback params
    end

    MmaxFit = paramsM(1);           % extract fit Mmax for normalization
    fit.M.(idLeg).params = paramsM;
    fit.M.(idLeg).Mmax = MmaxFit;
    [fit.M.(idLeg).R2,fit.M.(idLeg).AIC,fit.M.(idLeg).BIC] = ...
        computeFitQuality(I,M,modHyperbolic,paramsM);

    % ========== fit H-wave data using non-linear least squares ==========
    try
        IU = unique(I);             % find unique stimulation amplitudes
        avgsH = arrayfun(@(x) mean(H(I == x),'omitnan'),IU);
        [valHmax,locHmax,width] = findpeaks(avgsH,IU,'NPeaks',1);
        if isempty(valHmax)         % if no peak found, ...
            [valHmax,indHmax] = max(H);         % compute maximum
            locHmax = I(indHmax);               % intensity at maximum
            width = std(I);
        end
        % initialize coefficients: Hmax, Ipeak (mu/mean), sigma (stdev), c
        p0H = [valHmax locHmax width 1];
        paramsH = nlinfit(I,H,asymGaussian,p0H);
    catch
        warning("H-wave fitting failed for leg %d. Using defaults.",leg);
        paramsH = [max(H) median(I) std(I) 1];  % default fallback params
    end

    fit.H.(idLeg).params = paramsH;
    [fit.H.(idLeg).R2,fit.H.(idLeg).AIC,fit.H.(idLeg).BIC] = ...
        computeFitQuality(I,H,asymGaussian,paramsH);

end

end

function [R2,AIC,BIC] = computeFitQuality(intensities,amps,func,params)
% helper function to compute goodness-of-fit metrics

numParams = numel(params);                      % number of parameters
numPnts = numel(amps);                          % number of data points
pred = func(params,intensities);                % model-predicted values
residuals = amps - pred;
SSR = sum(residuals.^2);                        % sum of squared residuals
R2 = 1 - (SSR / sum((amps - mean(amps)).^2));   % R^2 calculation
% Akaike information criterion
AIC = numPnts * log(SSR / numPnts) + 2 * numParams;
% Bayesian information criterion
BIC = numPnts * log(SSR / numPnts) + numParams * log(numPnts);

end

