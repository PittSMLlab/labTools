function [Stride2SS]=CalcStrides2SS(allValues,SSraw, params, plotFlag, subID)
% this version was my first attempt to plot the readaptation stuff,
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
if isempty(plotFlag)~=0 || plotFlag==1
    figure
end

idxVELO = find(strcmp(params, 'velocityContributionNorm2'));
idxNET = find(strcmp(params, 'netContributionNorm2'));

%Smooth the data:
allValuesALL=bin_dataV1(allValues,20); SmoothType='Whole, BW=20, first not before raw min';
ss=SSraw;

for var=1:length(params)
    
    %Here I am using the final steady state that subjects reached to
    %shift the net
%     if var==idxVELO
        whereIS=find(allValues(:,var)==nanmin(allValues(1:20,var)),1, 'first');%use the non-smoothed data to shift the curves
%     else
%         whereIS=find(allValues(:,var)==nanmin(allValues(1:end-10,var)),1, 'first');%use the non-smoothed data to shift the curves
%     end
    
    minmin=allValues(whereIS,var);
    
    if var==idxNET || var==idxVELO
        shifter=SSraw(idxVELO)-SSraw(idxNET);
        %difference between the velocity and net SS
        allValuesALL(:,var)=allValuesALL(:,var)+abs(shifter);
        ss(var)=SSraw(var)+abs(shifter);
    end
    
    t=find(allValuesALL(:,var)>=ss(var)*.632);
    if isempty(t)==1
        Stride2SS(1, var)=NaN;
    else %this prevents a stride from being identified before the min value in the timecourse
        first_t=t(1);
        knot=2;
        while first_t<=whereIS %5
            first_t=t(knot);
            knot=knot+1;
        end
        
        Stride2SS(1, var)=first_t;
    end

    %optional plotting to see where the Tau is being identified
    if plotFlag
        subplot(1, length(params), var)
        plot([allValuesALL(:, var)], 'b.-', 'MarkerSize', 25);hold on
        
        plot(whereIS:whereIS+9, allValuesALL(whereIS:whereIS+9, var), 'c.', 'MarkerSize', 25);hold on
        plot(first_t, allValuesALL(first_t, var) , '.r', 'MarkerSize', 25); hold on
        line([0 900], [ss(var) ss(var)],'Color', 'k', 'LineWidth', 1)
        line([0 900], [ss(var)*.632 ss(var)*.632],'Color', 'k', 'LineWidth', 1, 'LineStyle',':')
        line([0 900], [0 0])
        
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

