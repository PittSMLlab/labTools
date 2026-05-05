function [relativeShift, initTimeDelay] = estimateDopplerShift( ...
    signal1, signal2, M)
%ESTIMATEDOPPLERSHIFT Estimate relative sampling-rate mismatch via STFT.
%
%   Divides both signals into windows of length M, estimates the time
% lag between each window pair using FINDTIMELAG, then fits a line to
% the lag-vs-time relationship. The slope of that line is the relative
% Doppler shift (fractional sampling-rate difference). Outlier windows
% are iteratively rejected until convergence.
%
%   Signals should be pre-aligned (relative delay << M) and high-pass
% filtered for best results. The maximum detectable relative shift is
% approximately 1/M.
%
% Inputs:
%   signal1 - 1-D reference signal (row vector)
%   signal2 - 1-D secondary signal (row vector)
%   M       - (optional) window length in samples; defaults to a value
%             that yields approximately sqrt(N)/4 windows, capped at 128
%
% Outputs:
%   relativeShift  - fractional sampling-rate difference (slope of lag
%                    vs. time line); positive means signal2 is faster
%   initTimeDelay  - intercept of the lag-vs-time line, in samples
%
% Toolbox Dependencies: None
%
% See also MATCHSIGNALS, FINDTIMELAG.

if nargin<3
    k=sqrt(length(signal2))/4; %Approx number of windows that is optimal for the estimation
    if k>128
        k=128;
arguments
    signal1 (1,:) double
    signal2 (1,:) double
    M       (1,1) double = NaN
end

    end
    M=ceil(length(signal2)/k);
end

%% Prepare Signals
N       = ceil(max([length(signal2) length(signal1)]) / M);
signal1 = signal1 - mean(signal1);
signal2 = signal2 - mean(signal2);
% Pad to a multiple of M so every window is the same length
signal1(end+1:N*M) = 0;
signal2(end+1:N*M) = 0;
signal1 = signal1 - mean(signal1);

E1 = sum(signal1.^2); %#ok<NASGU>
E2 = sum(signal2.^2); %#ok<NASGU>

%% Fit Line to Per-Window Lags (Iterative Outlier Rejection)
% Identify outlier windows, fit a line, repeat until convergence.
firstStep   = true;
differences = true;
iiOld       = [];
while differences

    clear x t lineFit
    t = nan(1, N);
    for win = 1:N
        aux2     = signal2((win-1)*M + 1:win*M);
        aux1     = signal1((win-1)*M + 1:win*M);
        [~, ~, t(win)] = findTimeLag(aux1, aux2);
        %         F1=fft(aux1);
        %         F2=fft(aux2);
        %         F=F1.*conj(F2);
        %         P=ifft(F);
        %         [s(win),t(win)]=max(abs(P));
        %     %     [acor,lag]=xcorr(aux1,aux2,'unbiased');
        %     %     [~,ii]=max(abs(acor));
        %     %     t(win)=lag(ii);
        x(win) = M/2 + (win - 1)*M;

        %         if 5*N*sqrt(sum(aux1.^2)*sum(aux2.^2))<sqrt(E1*E2)
        %             t(win)=NaN;
        %         end
    end
    auxI   = ~isnan(t);
    properX = x(auxI);
    properT = t(auxI);
    if firstStep
        lineFit   = polyfit(properX, properT, 1);
        firstStep = false;
        iiOld     = [];
    else
        auxX    = x(ii);
        auxT    = t(ii);
        lineFit = polyfit(auxX(auxI(ii)), auxT(auxI(ii)), 1);
        iiOld   = ii;
    end
    residuals = abs(t - x*lineFit(1) - lineFit(2));
    pp = prctile(residuals, 50);
    if pp < 0.5
        pp = 0.5; % quantization floor: expect at least 0.5-sample error
    end
    ii = find(residuals < pp & auxI); % reject outlier windows

    if ~isempty(ii) && ...
            (length(iiOld) ~= length(ii) || any(ii ~= iiOld))
        differences = true;
    else
        differences = false;
    end

end
% figure(1)
% plot(x,t,'.')
% hold on
% plot(x(ii),t(ii),'g.')
% plot(x,x*lineFit(1)+lineFit(2),'r')
% hold off
% legend('Rejected samples','Used samples','Line fit')

relativeShift  = lineFit(1);
initTimeDelay  = lineFit(2); % in samples

end
