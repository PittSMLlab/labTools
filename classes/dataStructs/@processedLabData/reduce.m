function reducedThis = reduce(this, eventLabels, N)
%reduce  Aligns and resamples all timeseries to the same indexes and puts
%them all together in a single timeseries
%
%   reducedThis = reduce(this) reduces the processedLabData object using
%   default event labels and resampling parameters
%
%   reducedThis = reduce(this, eventLabels, N) reduces the processedLabData
%   object using specified event labels and resampling parameters
%
%   Inputs:
%       this - processedLabData object
%       eventLabels - cell array of event labels to use for alignment
%                     (default: based on refLeg)
%       N - vector of sample counts between events
%           (default: [18 57 18 57])
%
%   Outputs:
%       reducedThis - reducedLabData object containing aligned and
%                     resampled data
%
%   See also: reducedLabData, labTimeSeries/align

% Define the events that will be used for all further computations
if nargin < 2 || isempty(eventLabels)
    refLeg = this.metaData.refLeg;
    if refLeg == 'R'
        s = 'R';
        f = 'L';
    elseif refLeg == 'L'
        s = 'L';
        f = 'R';
    else
        ME = MException('processedLabData:reduce:refLegError', ...
            'the refLeg/initEventSide property of metaData must be either ''L'' or ''R''.');
        throw(ME);
    end
    eventLabels = {[s, 'HS'], [f, 'TO'], [f, 'HS'], [s, 'TO']};
end
if nargin < 3 || isempty(N)
    N = [18 57 18 57]; % 12/38% split for DS single stance,
    % 150 samples per gait cycle, to keep it above 100Hz in general
end
warning('off', 'labTS:renameLabels:dont');

% Synchronize all relevant TSs
allTS = this.markerData.getDataAsTS([]);
reducedFields{1} = 'markerData';
fieldPrefixes{1} = 'mrk';
fieldLabels{1} = allTS.labels;

% Exhaustive list of fields to be preserved
% ff = fields(this);
ff = {'markerData', 'GRFData', 'accData', 'procEMGData', ...
    'angleData', 'COPData', 'COMData', 'jointMomentsData'};
ffShort = {'mrk', 'GRF', 'acc', 'EMG', 'ang', 'COP', 'COM', 'mom'};

for i = 1:length(ff)
    field = this.(ff{i});
    if ~isempty(field) && isa(field, 'labTimeSeries') && ...
            ~strcmp(ff{i}, 'gaitEvents') && ...
            ~strcmp(ff{i}, 'markerData') && ...
            ~strcmp(ff{i}, 'EMGData') && ~strcmp(ff{i}, 'adaptParams')
        reducedFields{end + 1} = ff{i};
        fieldLabels{end + 1} = strcat(ffShort{i}, field.labels);
        fieldPrefixes{end + 1} = ffShort{i};
        allTS = allTS.cat(field.getDataAsTS(field.labels).renameLabels( ...
            [], fieldLabels{end}).synchTo(allTS));
    end
end

% Align:
[alignTS, bad] = allTS.align(this.gaitEvents, eventLabels, N);

% Create reduced struct:
reducedThis = reducedLabData(this.metaData, this.gaitEvents, alignTS, ...
    bad, reducedFields, fieldPrefixes, this.adaptParams); % Constructor
warning('on', 'labTS:renameLabels:dont');
end

