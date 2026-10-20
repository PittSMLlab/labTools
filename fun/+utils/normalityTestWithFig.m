function [hn_sw,p_sw, h_ks, p_ks] = normalityTestWithFig(data, ...
    dataLabel, subplot_hist, subplot_qq, alpha, plotDiagnostics)
%NORMALITYTESTWITHFIG Test a vector for normality and plot diagnostics.
%
%   Runs the Shapiro-Wilk (SW) and Kolmogorov-Smirnov (KS) tests and warns
% when either rejects normality; SW is the preferred test for our data
% and its p-value sets the warning severity. Optionally draws a histogram
% with a fitted normal and a QQ plot: a normal-looking histogram and a QQ
% plot along the y = x line support normality.
%
% Side effects: when plotDiagnostics is true, makes subplot_hist and
%   subplot_qq the current axes and plots on them. Prints a pass message or
%   issues a warning with both p-values.
%
% Inputs:
%   data            - vector of doubles to test
%   dataLabel       - name of the data, used in the title and messages
%   subplot_hist    - axes for the histogram; may be empty or a filler
%                     when plotDiagnostics is false
%   subplot_qq      - axes for the QQ plot; may be empty or a filler when
%                     plotDiagnostics is false
%   alpha           - (optional) type I error rate (default: 0.05)
%   plotDiagnostics - (optional) logical, draw the histogram and QQ plot
%                     (default: true)
%
% Outputs:
%   hn_sw - SW decision (1 rejects normality)
%   p_sw  - SW p-value
%   h_ks  - KS decision (1 rejects normality)
%   p_ks  - KS p-value
%
% NOTE: alpha is accepted but not passed on; swtest and kstest use their
%   own default of 0.05.
%
% Toolbox Dependencies: Statistics and Machine Learning Toolbox
%
% See also SWTEST, KSTEST, HISTFIT, QQPLOT.

if nargin < 5 || isempty(alpha)
    alpha = 0.05; %default to 0.05
end

if nargin < 6 || isempty(plotDiagnostics)
    plotDiagnostics = true; %default to true
end

if plotDiagnostics
    axes(subplot_hist);
    histfit(data);
    title(dataLabel);

    axes(subplot_qq);
    qqplot(data)
end

[hn_sw, p_sw, W_sw] = swtest(data);
[h_ks,p_ks] = kstest(normalize(data));

if hn_sw || h_ks %0 is normal, 1 is reject = not normal
    % fprintf('\n') %start a new line for the warning, ...
    %    warning will by default have \n in the end but not in the
    %    beginning. So after the warning we will have an empty line bc I
    %    always start the print message with a \n
    severeAlpha = 0.01;     % arbitrary: p below this is severe
    if p_sw < severeAlpha
        warning(['Data normality failed (severe deviation <0.01) %s, ' ...
            'p_sw = %.4f, p_ks=%.4f'],dataLabel,p_sw,p_ks);
    else
        warning('Data normality failed %s, p_sw = %.4f, p_ks=%.4f', ...
            dataLabel,p_sw,p_ks);
    end
else
    fprintf('Data normal pass %s, p_sw = %.4f, p_ks=%.4f\n',dataLabel, ...
        p_sw,p_ks);
end
if p_sw < alpha
    title(sprintf('%s swtest p=%.2f',dataLabel,p_sw),'Color','r')
else
    title(sprintf('%s swtest p=%.2f',dataLabel,p_sw),'Color','k')
end
end