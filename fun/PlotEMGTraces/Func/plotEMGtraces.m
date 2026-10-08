function fh = plotEMGtraces(expData,conds,muscle,late,strides,normalize, ...
    normCond,IgnoreStridesEarly)
%PLOTEMGTRACES Plot EMG traces of several conditions for each muscle.
%
%   Opens one figure with one subplot per muscle and leg (5 x 6 grid) and
% draws, for each condition, the average of the requested strides with a
% 16-84 percentile band. Optionally scales each trace between the minimum
% and maximum of the average baseline traces of normCond (last 40
% strides).
%
% Side effects: opens a figure; errors if normalize is 1 and normCond is
%   empty.
%
% Inputs:
%   expData            - experimentData to read from
%   conds              - cell array of condition names
%   muscle             - cell array of muscle names without side prefix
%   late               - per condition, 1 for the last strides, 0 for the
%                        first
%   strides            - per condition, number of strides to average
%   normalize          - (optional) 1 to normalize the traces (default: 0)
%   normCond           - conditions used for normalization
%   IgnoreStridesEarly - per condition, initial strides to skip
%
% Outputs:
%   fh - figure handle
%
% Toolbox Dependencies: Statistics and Machine Learning Toolbox (through
%   alignedTimeSeries.plot)
%
% Example:
%   fh = plotEMGtraces(expData,{'TM base'},{'TA'},1,40);
%   plots the average of the last 40 strides of TA during treadmill
%   baseline.
%
% See also GETDATAEMGTRACES, EMG_TRACES_EXAMPLE.

%% Plot config

%this is the setting for a 5x6 subplot
row   = 5;
colum = 6;

%% Check inputs
if nargin < 6 || isempty(normalize)
    normalize = 0;
end

if normalize == 1 && isempty(normCond)
    error('You need to define which conditions to use for normalization')
end


lm = 1:2:2*length(muscle)+1;
% if late(c)==1
%     condlegend=strcat(repmat(conds,1,1),'_{late}');
% else
%
%     condlegend=strcat(repmat(conds,1,1),'_{early}');
% end


fh = figure('Units','Normalized');
poster_colors;
colorOrder = [p_red; p_orange; p_fade_green; p_fade_blue; p_plum; ...
    p_green; p_blue; p_fade_red; p_lime; p_yellow; [0 0 0]];
condColors = colorOrder;
if length(conds) > length(colorOrder)
    condColors = [colorOrder; rand(1)*colorOrder];
end

ph1 = [];
prc = [16,84];
alignmentLengths = [16,32,16,32];
MM = sum(alignmentLengths);
M = cumsum([0 alignmentLengths]);
xt = sort([M,M(1:end-1)+[diff(M)/2]]);
phaseSize = 8;
xt = [0:phaseSize:MM];

fs = 16; %FontSize

set(gcf,'color','w')
hold on

for m = 1:length(muscle)
    leg = {'R','L'};
    for l = 1:2
        for c = 1:length(conds)


            if l == 1
                data = getDataEMGtraces(expData,muscle{m},conds(c), ...
                    leg{l},late(c),strides(c),IgnoreStridesEarly(c));
                if normalize == 1
                    norm = getDataEMGtraces(expData,muscle{m},normCond, ...
                        leg{l},1,40);
                end
                tit = ['R' muscle{m}];
            elseif l == 2
                data = getDataEMGtraces(expData,muscle{m},conds(c), ...
                    leg{l},late(c),strides(c),IgnoreStridesEarly(c));
                if normalize == 1
                    norm = getDataEMGtraces(expData,muscle{m},normCond, ...
                        leg{l},1,40);
                end
                tit = ['L' muscle{m}];
            end

            if normalize == 1

                % norm=nanmax(nanmean(squeeze(norm.Data)));
                % data.Data=bsxfun(@rdivide,data.Data,norm);
                normM = max(mean(squeeze(norm.Data), 2, 'omitnan'), [], ...
                    'omitnan');
                normm = min(mean(squeeze(norm.Data), 2, 'omitnan'), [], ...
                    'omitnan');
                % normM=nanmax(squeeze(norm.Data),[],'all');
                % normm=nanmin(squeeze(norm.Data),[],'all');
                data.Data = (data.Data-normm)/(normM-normm);




            end
            ph = subplot(row,colum,lm(m)+l-1);
            data.plot(fh,ph,condColors(c,:),[],0,[-49:0],prc,false);

            if late(c) == 1
                condlegend(c) = strcat(repmat(conds(c),1,1),'_{late}');
            else

                condlegend(c) = strcat(repmat(conds(c),1,1),'_{early}');
            end



        end
        axis tight
        ylabel('')
        ylabel(tit)
        grid on
        ll = findobj(ph,'Type','Line');
    end


end
% if late==1
%     title('Late Phases')
%
% else
%     title('Early Phases')
% end
legend(ll(end:-1:1),condlegend{:})



end
