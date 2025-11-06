function [hn_sw,p_sw, h_ks, p_ks] = normalityTestWithFig(data, dataLabel, subplot_hist, subplot_qq, alpha, plotDiagnostics)
    %Perform normality test on the data vector given using Shapiro-Wilk
    %test and kstest. Though preferred method is SW-test and the diagnostic plot
    %title will reflect SW test result because the SW test is more appropriate for our data. 
    %Also plot histogram and QQ plot for data
    %visualization. Normal looking histogram and QQ plot following a y=x
    %line is important indicator for data following a normal distribution.
    %
    %[OUTPUTARGS]: 
    % - hn_sw: normality decision from SW test (1 is rejecting normal)
    % - p_sw: p-value from sw test: for now use p < alpha as rejecting
    %       normal.
    % - h_ks: normality decision from KS test (1 is rejecting normal)
    % - p_ks: p-value from ks test: for now use p < alpha as rejecting
    %       normal.
    %
    %[INPUTARGS]
    % - data: a vector of double, data to test normality
    % - dataLabel: string for name of the data
    % - subplot_hist: subplot handle to plot the histogram on. OPTIONAL,
    %       can be empty or pass filler variable if the plotDiagnostics is false
    % - subplot_qq: subplot handle to plot the QQ plot on. OPTIONAL,
    %       can be empty  or pass filler variable if the plotDiagnostics is false
    % - alpha: OPTIONA. default is 0.05. alpha for type I error (p < alpha 
    %       will be considered evidence to reject null where data is normal). 
    % - plotDiagnostics: OPTIONAL. default true. Whether or not to generate
    %       a histogram and QQ plot to visually check for normality
    
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
%         fprintf('\n') %start a new line for the warning, warning will by default have \n in the end but not in the beginning. So after the warning we will have an empty line bc I always start the print message with a \n
        if p_sw < 0.01 %arbitrarily set <0.01 as severe deviation from normality
            warning('Data normality failed (severe deviation <0.01) %s, p_sw = %.4f, p_ks=%.4f',dataLabel,p_sw,p_ks);
        else
            warning('Data normality failed %s, p_sw = %.4f, p_ks=%.4f',dataLabel,p_sw,p_ks);
        end
    else
        fprintf('Data normal pass %s, p_sw = %.4f, p_ks=%.4f\n',dataLabel,p_sw,p_ks);
    end
    if p_sw < alpha
        title(sprintf('%s swtest p=%.2f',dataLabel,p_sw),'Color','r')
    else
        title(sprintf('%s swtest p=%.2f',dataLabel,p_sw),'Color','k')
    end
end