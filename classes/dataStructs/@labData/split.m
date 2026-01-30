function newThis = split(this, t0, t1, newClass)
%split  Splits data into time-delimited segments
%
%   newThis = split(this, t0) splits data from time t0 to end
%   of trial
%
%   newThis = split(this, t0, t1) splits data into interval
%   [t0, t1)
%
%   newThis = split(this, t0, t1, newClass) splits data and
%   returns object of type specified by newClass string
%
%   Inputs:
%       this - labData object
%       t0 - time in seconds of split start (inclusive). Use
%            NaN for trial start
%       t1 - time in seconds of split end (exclusive). Use NaN
%            or omit for trial end
%       newClass - string representing class/object type to
%                  return (optional, default: same as this)
%
%   Outputs:
%       newThis - new object containing split data, of type
%                 specified by newClass or same as input (must be subclass)
%
%   See also: labTimeSeries/split

% Split the data into [t0, t1).
% Args:
%   -t0: time in seconds (relative to trial start) of where to start the
%        split (inclusive) when given NaN, default to start of the trial.
%   -t1: time in seconds (relative to trial start) of where to stop
%        (exclusive). OPTIONAL, when not provided or got NaN, default to
%        end of the trial
%   -newClass: string representing class/object type to return.
%        OPTIONAL, default return the same type

newThis = []; % Just to avoid Matlab saying this is not defined
cname = class(this);
if nargin < 4
    % (ID, date, experimenter, desc, obs, refLeg, parentMeta)
    metaData = derivedMetaData(labDate.genIDFromClock, ...
        labDate.getCurrent, 'labData.split', ...
        ['Splice of ' this.metaData.description], 'Auto-generated', ...
        this.metaData.refLeg, this.metaData);
    % HH removed 'Partial Interval' after labdata.split since 'type'
    % property was eliminated.
    eval(['newThis = ' cname '(metaData);']);
    % Call empty constructor of same class
else
    % Should I call a different metaData constructor
    metaData = strideMetaData(labDate.genIDFromClock, ...
        labDate.getCurrent, 'labData.split', ...
        ['Splice of ' this.metaData.description], 'Auto-generated', ...
        this.metaData.refLeg, this.metaData);
    eval(['newThis = ' newClass '(metaData);']);
    % Call empty constructor of same class
end

auxLst = properties(cname);
for i = 1:length(auxLst)
    % Should try to do this only if the property is not dependent;
    % otherwise, I'm computing things I don't need
    eval(['oldVal = this.' auxLst{i} ';'])
    if isa(oldVal, 'labTimeSeries') && ...
            ~isa(oldVal, 'parameterSeries')
        % no end time point provided, assume spliting from t0 to end of the
        % trial
        if nargin < 3 || isnan(t1)
            tEnd = oldVal.Time(end) + oldVal.sampPeriod;
        else % end point provided use it
            tEnd = t1;
        end
        % a flag/fake initial time provided, assuming split from beginning
        % to t1
        if isnan(t0)
            % start is inclusive, no need to pad
            tStart = oldVal.Time(1);
        else % end point provided use it.
            tStart = t0;
        end
        % Calling labTS.split (or one of the subclass' implementation)
        newVal = oldVal.split(tStart, tEnd);
    elseif ~isa(oldVal, 'labMetaData')
        newVal = oldVal; % Not a labTS object, not splitting
    end
    try
        % If this fails it is because the property is not settable
        eval(['newThis.' auxLst{i} ' = newVal;'])
    catch

    end
end
newThis.metaData = metaData;

end

