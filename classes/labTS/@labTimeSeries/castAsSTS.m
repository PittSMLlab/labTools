function newThis = castAsSTS(this, F, tWin, tOverlap)
%castAsSTS  Converts to spectroTimeSeries
%
%   newThis = castAsSTS(this, F, tWin, tOverlap) converts to
%   spectroTimeSeries with specified parameters
%
%   Inputs:
%       this - labTimeSeries object
%       F - frequency vector
%       tWin - time window duration
%       tOverlap - overlap duration
%
%   Outputs:
%       newThis - spectroTimeSeries object
%
%   See also: spectroTimeSeries, spectrogram

% Check if it satisfies STS requirements
dataF = this.Data;
labelsF = this.labels;
t0 = this.Time(1);
Ts = this.sampPeriod;
spectroTimeSeries.inputArgsCheck( ...
    dataF, labelsF, t0, Ts, F, tWin, tOverlap);
newThis = spectroTimeSeries(dataF, labelsF, t0, Ts, F, tWin, tOverlap);
end

