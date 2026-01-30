function newThis = timeNormalize(this, N, newClass)
%timeNormalize  Resamples all data to uniform length
%
%   newThis = timeNormalize(this, N) resamples all time series
%   data to N samples, creating a time-normalized stride
%
%   newThis = timeNormalize(this, N, newClass) resamples and
%   returns object of type specified by newClass string
%
%   Inputs:
%       this - strideData object
%       N - target number of samples
%       newClass - string representing class/object type to
%                  return (optional, default: 'strideData')
%
%   Outputs:
%       newThis - time-normalized stride object
%
%   Note: EMG data is resampled to next power of 2 to maintain
%         appropriate sampling rate
%
%   See also: getMasterSampleLength, labTimeSeries/resampleN

newThis = []; % Just to avoid Matlab saying this is not defined
cname = class(this);
if nargin < 3
    metaData = strideMetaData(labDate.genIDFromClock, ...
        labDate.getCurrent, 'strideData.timeNormalize', ...
        'normalizedInterval', ...
        ['Normalized ' this.metaData.description], ...
        'Auto-generated', this.metaData);
    eval(['newThis = ' cname '(metaData);']); % Call empty
    % constructor of
    % same class
else
    % Should I call a different metaData constructor depending on
    % newClass?
    metaData = strideMetaData(labDate.genIDFromClock, ...
        labDate.getCurrent, 'strideData.timeNormalize', ...
        'normalizedInterval', ...
        ['Normalized  ' this.metaData.description], ...
        'Auto-generated', this.metaData);
    eval(['newThis = ' newClass '(metaData);']); % Call empty
    % constructor of
    % same class
end
auxLst = properties(cname);
for i = 1:length(auxLst)
    % Should try to do this only if the property is not dependent,
    % otherwise, I'm computing things I don't need
    eval(['oldVal = this.' auxLst{i} ';'])
    if isa(oldVal, 'labTimeSeries') && ...
            ~strcmp(auxLst{i}, 'EMGData')
        % Calling labTS.resample (or one of the subclass'
        % implementation), it should keep the time interval, which
        % for strided data should
        newVal = oldVal.resampleN(N);
    elseif strcmp(auxLst{i}, 'EMGData')
        k = this.EMGData.Nsamples / this.markerData.Nsamples;
        NN = 2^ceil(log2(k * N));
        newVal = oldVal.resampleN(NN);
    elseif ~isa(oldVal, 'labMetaData')
        newVal = oldVal; % Not a labTS object, not splitting
    end
    try
        % If this fails is because the property is not settable
        eval(['newThis.' auxLst{i} ' = newVal;'])
    catch
        if isa(oldVal, 'labTimeSeries')
            disp(['Failed to set new labTS value' auxLst{i}]);
        end
    end
end
end

