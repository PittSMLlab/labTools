function [COP, F, M] = computeHemiCOP(this, side, noFilterFlag)
%computeHemiCOP  Computes center of pressure for one leg
%
%   [COP, F, M] = computeHemiCOP(this, side) computes center of
%   pressure for specified leg with default filtering
%
%   [COP, F, M] = computeHemiCOP(this, side, noFilterFlag)
%   optionally disables filtering when noFilterFlag is true
%
%   Inputs:
%       this - labData object
%       side - 'L' or 'R' for left or right leg
%       noFilterFlag - flag to disable filtering (default:
%                      filtered)
%
%   Outputs:
%       COP - orientedLabTimeSeries containing center of
%             pressure
%       F - force data matrix
%       M - moment data matrix
%
%   Note: COP computation is calibrated only for GRFData
%         obtained from the Bertec instrumented treadmill
%
%   See also: computeCOPAlt, mergeHemiCOPs

% COP calculation as used by the ALTERNATIVE version

this = this.GRFData;
fcut = 50;
% Warning: this only works if GRF data is stored here
warning('orientedLabTimeSeries:computeCOP', ...
    ['COP computation is calibrated only for GRFData ' ...
    'obtained from the Bertec instrumented treadmill']);
if nargin > 2 && ~isempty(noFilterFlag) && noFilterFlag == 1
    F = squeeze(this.getDataAsOTS([side 'F']).getOrientedData);
    M = squeeze(this.getDataAsOTS([side 'M']).getOrientedData);
else
    F = this.getDataAsOTS([side 'F']).medianFilter(5).substituteNaNs;
    F = F.lowPassFilter(fcut).thresholdByChannel(-100, [side 'Fz'], 1);
    F = squeeze(F.getOrientedData);
    M = this.getDataAsOTS([side 'M']).medianFilter(5).substituteNaNs;
    M = M.lowPassFilter(fcut);
    M = squeeze(M.getOrientedData);
    % Thresholding to avoid artifacts
    F(abs(F(:, 3)) < 100, :) = 0;
end
% I believe this should work for all forceplates in the world:
% aux = bsxfun(@rdivide, cross(F, M), (sum(F.^2, 2)));
% t = -aux(:, 3) ./ F(:, 3);
% COP = orientedLabTimeSeries(aux + t .* F, this.Time(1), this.sampPeriod,
% orientedLabTimeSeries.addLabelSuffix([side 'COP']), this.orientation);
% This is Bertec Treadmill specific:
aux(:, 1) = (-15 * F(:, 1) - M(:, 2)) ./ F(:, 3);
aux(:, 2) = (15 * F(:, 2) + M(:, 1)) ./ F(:, 3);
aux(:, 3) = 0;
if strcmp(side, 'R')
    % Flipping and offsetting to match reference axis of L-forceplate
    aux(:, 1) = aux(:, 1) - 977.9;
end
% Flipping & adding offset to match lab's reference axis sign
aux(:, 2) = -aux(:, 2) + 1619.25;
% Adding offset to lab's reference origin
aux(:, 1) = aux(:, 1) + 25.4;
COP = orientedLabTimeSeries(aux, this.Time(1), this.sampPeriod, ...
    orientedLabTimeSeries.addLabelSuffix([side 'COP']), this.orientation);
end

