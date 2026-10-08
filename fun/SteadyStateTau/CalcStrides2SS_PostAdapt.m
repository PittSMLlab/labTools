function Stride2SS = CalcStrides2SS_PostAdapt(allValues,SSraw, params, ...
    plotFlag, subID)
% this version was my first attempt to plot the postadaptation stuff,
% AND DO SO WITHOUT CROPPING THE DATA
%adaptDataList must be cell array of 'param.mat' file names
%params is cell array of parameters to plot. List with commas to
%plot on separate graphs or with semicolons to plot on same graph.
%conditions is cell array of conditions to plot
%binwidth is the number of data points to average in time
%indivFlag - set to true to plot individual subject time courses
%indivSubs - must be a cell array of 'param.mat' file names that is
%a subset of those in the adaptDataList. Plots specific subjects
%instead of all subjects.


% %%%How to calculate strides to ss
if isempty(plotFlag) ~= 0 || plotFlag == 1
    figure
end

idxVELO = find(strcmp(params, 'velocityContributionNorm2'));
idxNET  = find(strcmp(params, 'netContributionnorm2'));

binWidth      = 20;     % strides per bin (matches SmoothType below)
nEarlyStrides = 20;     % TODO: source? (strides searched for the extreme)
%Smooth the data:
allValuesALL = bin_dataV1(allValues,binWidth); SmoothType = ...
    'Whole, BW=20, first not before raw min';
ss           = SSraw;

for var = 1:length(params)

    %Here I am using the final steady state that subjects reached to
    %shift the net
    %use the non-smoothed data to shift the curves to identify the minimum
    %value that crossess the threshod
    whereIS = find(allValues(:,var) == ...
        min(allValues(1:nEarlyStrides,var), [], 'omitnan'),1, 'first');

    %Finding the initial quantity
    whereNo = find(~isnan(allValues(:,var)),1, 'first');
    NewQ    = allValuesALL(whereNo,var);

    %Finding the new quantity by subtracting the initial quantity and the
    %steady state
    NewQ(var) = (NewQ(var)-SSraw(var));

    %Finding the maximum point to shift the data by
    whereIM = find(allValues(:,var) == ...
        max(allValues(1:nEarlyStrides,var), [], 'omitnan'),1, 'first');
    maxmax  = allValues(whereIM,var);

    whereIMall = find(allValuesALL(:, var) == ...
        max(allValuesALL(1:nEarlyStrides,var), [], 'omitnan'),1,'first');

    %%

    %shifting  the steady state by the maximum value of the postadaptation
    %decay curve
    shifter = SSraw(var)+maxmax;

    %shift all the values by the first maximum value
    % allValuesALL(:,var)=allValuesALL(:,var)+abs(shifter);

    %shift the steady state value by the shifter which is the
    %maxmax+steadystate value
    ss(var) = SSraw(var);%+abs(shifter);

    % Calculate the threshold value for steady state (1/e decay)
    thresholdValue = (NewQ) * exp(-1)+ SSraw;


    %find the index of the values that are less than the threshold
    t_indx = find(allValuesALL(:,var) <= thresholdValue);

    %make sure that the indexes that are extracted are not above the any
    %value greater than the maximum value in allValues or allValuesAll
    tfinal = t_indx((t_indx >= whereIMall) & (t_indx >= whereIM));
    if isempty(tfinal) == 1
        tfinal = t;
    end

    %%alternative withot finding the 5 consecutive numbers
    %  tconsecutive = find(diff(tfinal));
    % first_t = tfinal(tconsecutive(1));
    %
    % if isempty(first_t)== 1
    %    Stride2SS(1, var)=NaN
    % else
    %  Stride2SS(1, var)=first_t;
    % end

    % Initialize the variable to store the first five consecutive numbers
    N = 5;
    first_consecutive_set = [];

    % Loop through tfinal to find the first set of N consecutive numbers
    %loop through the length of tfinal because beyond that, there wont be
    %any sequence to form
    for st = 1:length(tfinal)-N+1
        if all(diff(tfinal(st:st+N-1)) == 1)
            %find the index of the first 5 consecutive numbers
            first_consecutive_set = tfinal(st:st+N-1);
            break;
        end
    end

    % If a consecutive set of N numbers is found, set first_t
    first_t = first_consecutive_set(1);


    Stride2SS(1, var) = first_t;

    %%
    %optional plotting to see where the Tau is being identified
    if plotFlag == 1
        subplot(1, length(params), var)
        plot([allValuesALL(:, var)], 'b.-', 'MarkerSize', 25);hold on

        % plot(whereIM:whereIM+9, allValuesALL(whereIM:whereIM+9, var), ...
        %    'c.', 'MarkerSize', 25);hold on
        plot(first_t, allValuesALL(first_t, var) , '.r', 'MarkerSize', ...
            25); hold on
        xline(first_t,'Color', 'r', 'LineWidth', 1, 'LineStyle',':')

        %plotting mean steady state value
        line([0 400], [ss(var) ss(var)],'Color', 'k', 'LineWidth', 1)
        text(400,  ss(var), num2str(ss(var)), 'HorizontalAlignment', ...
            'right', 'VerticalAlignment', 'bottom');

        %plotting line showing the threshold
        line([0 400], [thresholdValue thresholdValue],'Color', 'k', ...
            'LineWidth', 1, 'LineStyle',':')
        text(400,  thresholdValue, num2str(thresholdValue), ...
            'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom');

        if subID
            title([subID ': Stride to SS = ' num2str(first_t)]);
        else
            title(['Stride to SS = ' num2str(first_t)]);
        end

        ylabel([params(var)])
        xlabel(['Strides (' SmoothType ')'])
        axis tight
        hold on
    end
end

%display('everything is awesome')

end

