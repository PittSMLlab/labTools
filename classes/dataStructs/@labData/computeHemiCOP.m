function [COP, F, M] = computeHemiCOP(this, side, noFilterFlag)
%COMPUTEHEMICOP Computes center of pressure for one leg.
%
%   [COP, F, M] = computeHemiCOP(this, side) computes center of pressure
% for specified leg with default filtering
%
%   [COP, F, M] = computeHemiCOP(this, side, noFilterFlag) optionally
% disables filtering when noFilterFlag is true
%
% Inputs:
%   this         - labData object
%   side         - 'L' or 'R' for left or right leg
%   noFilterFlag - flag to disable filtering (default: filtered)
%
% Outputs:
%   COP - orientedLabTimeSeries containing center of pressure
%   F   - force data matrix
%   M   - moment data matrix
%
% NOTE: COP computation is calibrated only for GRFData obtained from the
%       Bertec instrumented treadmill
%
% Toolbox Dependencies: Signal Processing Toolbox (indirect, via
%                        LABTIMESERIES filter methods)
%
% See also COMPUTECOPALT, MERGEHEMICOPS.

% COP calculation as used by the ALTERNATIVE version

this = this.GRFData;
fcut           = 50;      % Hz, low-pass cutoff; TODO: source?
medFiltOrder   = 5;       % samples; TODO: source?
forceThreshold = 100;     % N, artifact threshold on Fz; TODO: source?
plateOffsetZ   = 15;      % plate geometry (units?); TODO: source?
rightPlateOffX = 977.9;   % L-to-R plate x shift (units?); TODO: source?
labOffsetY     = 1619.25; % lab-axis y offset (units?); TODO: source?
labOffsetX     = 25.4;    % lab-axis x offset (units?); TODO: source?
% Warning: this only works if GRF data is stored here
warning('orientedLabTimeSeries:computeCOP', ...
    ['COP computation is calibrated only for GRFData ' ...
    'obtained from the Bertec instrumented treadmill']);
if nargin > 2 && ~isempty(noFilterFlag) && noFilterFlag == 1
    F = squeeze(this.getDataAsOTS([side 'F']).getOrientedData);
    M = squeeze(this.getDataAsOTS([side 'M']).getOrientedData);
else
    F = this.getDataAsOTS([side 'F']);
    F = F.medianFilter(medFiltOrder).substituteNaNs;
    F = F.lowPassFilter(fcut).thresholdByChannel(-forceThreshold, ...
        [side 'Fz'], 1);
    F = squeeze(F.getOrientedData);
    M = this.getDataAsOTS([side 'M']);
    M = M.medianFilter(medFiltOrder).substituteNaNs;
    M = M.lowPassFilter(fcut);
    M = squeeze(M.getOrientedData);
    % Thresholding to avoid artifacts
    F(abs(F(:, 3)) < forceThreshold, :) = 0;
end
% General COP formula (disabled; the Bertec-specific form below is used):
% aux = bsxfun(@rdivide, cross(F, M), (sum(F.^2, 2)));
% t = -aux(:, 3) ./ F(:, 3);
% COP = orientedLabTimeSeries(aux + t .* F, this.Time(1), this.sampPeriod,
% orientedLabTimeSeries.addLabelSuffix([side 'COP']), this.orientation);
% This is Bertec Treadmill specific:
aux(:, 1) = (-plateOffsetZ * F(:, 1) - M(:, 2)) ./ F(:, 3);
aux(:, 2) = (plateOffsetZ * F(:, 2) + M(:, 1)) ./ F(:, 3);
aux(:, 3) = 0;
if strcmp(side, 'R')
    % Flipping and offsetting to match reference axis of L-forceplate
    aux(:, 1) = aux(:, 1) - rightPlateOffX;
end
% Flipping & adding offset to match lab's reference axis sign
aux(:, 2) = -aux(:, 2) + labOffsetY;
% Adding offset to lab's reference origin
aux(:, 1) = aux(:, 1) + labOffsetX;
COP = orientedLabTimeSeries(aux, this.Time(1), this.sampPeriod, ...
    orientedLabTimeSeries.addLabelSuffix([side 'COP']), this.orientation);
end

