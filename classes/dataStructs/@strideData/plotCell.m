function plotHandles = plotCell(strides, field, ampNorm, ...
    plotHandles, reqElements, color, plotEvents)
%PLOTCELL Plots cell array of stride data.
%
%   plotHandles = plotCell(strides, field, ampNorm, plotHandles,
% reqElements, color, plotEvents) plots data from multiple strides with
% various normalization and display options
%
% Inputs:
%   strides     - cell array of strideData objects
%   field       - name of field to plot
%   ampNorm     - amplitude normalization flag or coefficients
%   plotHandles - handles to plot axes
%   reqElements - elements to plot
%   color       - plot color specification
%   plotEvents  - flag to overlay gait events
%
% Outputs:
%   plotHandles - updated plot handles
%
% Toolbox Dependencies: None
%
% See also PLOTCELLAVG, CELL2MAT.

% NOTE: strides must be synchronized before the call; each element of the
% field (e.g., each muscle) gets its own subplot.

%Get a sample field:
eval(['justTheField{1}=strides{1}.' field ';']);
if nargin < 7 || isempty(plotEvents)
    plotEvents = false;
end
if nargin < 6 || isempty(color)
    color = [0.7,0.7,0.7];
end

%% First determine how many things are to be plotted & get the data.

%Find the requested data:3 options. If reqElements is a cell, the length of
%the cell. If it is empty or not given, then all
%the elements, finally if reqElement is 'L' or 'R', just the element labels
%that start with that.
if nargin < 5 || isempty(reqElements) %No requested elements, plotting all.
    relIdx    = 1:size(justTheField{1}.Data,2);
    relLabels = justTheField{1}.labels;
    %List of requested labels given/
elseif isa(reqElements,'cell') && isa(reqElements{1},'char')
    for ii = 1:length(reqElements)
        [flag(ii),labelIdx(ii)] = justTheField{1}.isaLabel(reqElements{ii});
    end
    relIdx    = labelIdx(flag == 1); %In case some labels don't exist
    relLabels = reqElements(flag == 1);
    %Either 'L' or 'R', plotting single side.
elseif isa(reqElements,'char') && length(reqElements) == 1
    labels    = justTheField{1}.labels;
    relIdx    = [];
    relLabels = {};
    for ii = 1:length(labels)
        if strcmp(labels{ii}(1),reqElements)
            relIdx(end+1) = ii;
            relLabels{end+1} = labels{ii};
        end
    end
end
Nplots = length(relIdx);

%Find length of all strides, and get data corresponding to the relevant
%labels.
for stride = 1:length(strides)
    eval(['relData{stride}=strides{stride}.' field ...
        '.getDataAsTS(relLabels);']);
    if plotEvents
        events{stride} = ...
            strides{stride}.gaitEvents.getDataAsTS({'RHS','LHS','RTO', ...
            'LTO'});
    end
    strideLength(stride) = size(relData{stride}.Data,1);
end
% N is the smallest power of two that is not shorter than any stride.
N = 2^ceil(log2(max(strideLength)));

%Time normalize and put everything in a matrix
for stride = 1:length(strides)
    allDataAsMatrix(:,:,stride) = ...
        relData{stride}.resampleN(N).getDataAsVector(relLabels);
end

%% Second, check if the plotHandles given (if any) are enough for those
%% plots, otherwise get adequate plotHandles
if nargin < 4 || length(plotHandles) ~= Nplots
    if Nplots > 16
        b = 4;
        a = ceil(Nplots/b);
    else
        b = 2;
        a = ceil(Nplots/b);
    end
    for ii = 1:Nplots
        plotHandles(ii) = subplot(a,b,ii);
    end
end

%% Third, do the plots & link axes in x. Also plot avg.
for ii = 1:Nplots
    subplot(plotHandles(ii))
    hold on
    plot(repmat([0:N-1]'/N,1,length(strides)), ...
        squeeze(allDataAsMatrix(:,ii,:)),'Color',color);
    if plotEvents
        % TODO: overlay the gait events
    end
    plot([0:N-1]'/N,mean(allDataAsMatrix(:,ii,:),3),'k--');
    ylabel(relLabels{ii})
    xlabel('Stride (%)')
    hold off
    if ampNorm
        axis tight
    else
        axis([0 1 min(allDataAsMatrix(:)) max(allDataAsMatrix(:))])
    end
end
linkaxes(plotHandles,'x')
